/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import RxSwift

extension ObservableType {
  func compactMap<R>(_ transform: @escaping (Element) throws -> R?) -> Observable<R> {
    self
      .map(transform)
      .filter { $0 != nil }
      .map { $0! }
  }
}

extension PrimitiveSequence where Element == Never, Trait == CompletableTrait {
  func andThen(using body: () -> Completable) -> Completable { self.andThen(body()) }

  func wait(
    timeout: TimeInterval = 5,
    onCompleted: (() -> Void)? = nil,
    onError: ((Swift.Error) -> Void)? = nil
  ) throws {
    var trigger = false
    var err: Swift.Error?

    let condition = NSCondition()

    condition.lock()
    defer { condition.unlock() }

    let disposable = self.subscribe(onCompleted: {
      onCompleted?()

      condition.lock()
      defer { condition.unlock() }
      trigger = true
      condition.broadcast()
    }, onError: { error in
      onError?(error)
      err = error

      condition.lock()
      defer { condition.unlock() }
      trigger = true
      condition.broadcast()
    })

    while !trigger {
      condition.wait(until: Date(timeIntervalSinceNow: timeout))
      trigger = true
    }

    disposable.dispose()

    if let e = err { throw e }
  }
}

extension PrimitiveSequence where Trait == SingleTrait {
  static func fromSinglesToSingleOfArray(_ singles: [Single<Element>]) -> Single<[Element]> {
    Observable
      .merge(singles.map { $0.asObservable() })
      .toArray()
  }

  func flatMapCompletable(_ selector: @escaping (Element) throws -> Completable) -> Completable {
    self
      .asObservable()
      .flatMap { try selector($0).asObservable() }
      .ignoreElements()
  }

  func syncValue(timeout: TimeInterval = 5) -> Element? {
    var trigger = false
    var value: Element?

    let condition = NSCondition()

    condition.lock()
    defer { condition.unlock() }

    let disposable = self.subscribe(onSuccess: { result in
      value = result

      condition.lock()
      defer { condition.unlock() }
      trigger = true
      condition.broadcast()
    }, onError: { _ in
      condition.lock()
      defer { condition.unlock() }
      trigger = true
      condition.broadcast()
    })

    while !trigger {
      condition.wait(until: Date(timeIntervalSinceNow: timeout))
      trigger = true
    }

    disposable.dispose()

    return value
  }

  func asCompletable() -> Completable { self.asObservable().ignoreElements() }
}
