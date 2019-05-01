/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import RxSwift

extension ObservableType {

  func compactMap<R>(
    _ transform: @escaping (Element) throws -> R?
  ) -> Observable<R> {
    return self
      .map(transform)
      .filter { $0 != nil }
      .map { $0! }
  }
}

extension PrimitiveSequence where Element == Never, Trait == CompletableTrait {

  func andThen(using body: () -> Completable) -> Completable {
    return self.andThen(body())
  }

  func wait(
    onCompleted: (() -> Void)? = nil,
    onError: ((Swift.Error) -> Void)? = nil
  ) throws {
    var trigger = false
    var err: Swift.Error? = nil

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

    while !trigger { condition.wait(until: Date(timeIntervalSinceNow: 5)) }
    disposable.dispose()

    if let e = err { throw e }
  }
}

extension PrimitiveSequence where Trait == SingleTrait {

  static func fromSinglesToSingleOfArray(
    _ singles: [Single<Element>]
  ) -> Single<[Element]> {
    return Observable
      .merge(singles.map { $0.asObservable() })
      .toArray()
  }

  func flatMapCompletable(
    _ selector: @escaping (Element) throws -> Completable
  ) -> Completable {
    return self
      .asObservable()
      .flatMap { try selector($0).asObservable() }
      .ignoreElements()
  }

  func syncValue() -> Element? {
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
    }, onError: { error in
      condition.lock()
      defer { condition.unlock() }
      trigger = true
      condition.broadcast()
    })

    while !trigger { condition.wait(until: Date(timeIntervalSinceNow: 5)) }
    disposable.dispose()

    return value
  }

  func asCompletable() -> Completable {
    return self.asObservable().ignoreElements()
  }
}
