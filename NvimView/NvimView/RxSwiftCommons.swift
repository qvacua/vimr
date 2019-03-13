/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import RxSwift

extension PrimitiveSequence where Element == Never, TraitType == CompletableTrait {

  func wait(
    onCompleted: (() -> Void)? = nil,
    onError: ((Error) -> Void)? = nil
  ) throws {
    var trigger = false
    var err: Error? = nil

    let condition = NSCondition()

    condition.lock()
    defer { condition.unlock() }

    let disposable = self.subscribe(onCompleted: {
      onCompleted?()
      condition.lock()
      trigger = true
      broadcast(condition)
    }, onError: { error in
      onError?(error)
      condition.lock()
      trigger = true
      err = error
      broadcast(condition)
    })

    while !trigger && condition.wait(until: Date(timeIntervalSinceNow: 5)) {}
    disposable.dispose()

    if let e = err {
      throw e
    }
  }
}

extension PrimitiveSequence where TraitType == SingleTrait {

  static func fromSinglesToSingleOfArray(_ singles: [Single<Element>]) -> Single<[Element]> {
    return Observable.merge(singles.map { $0.asObservable() }).toArray().asSingle()
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
      trigger = true
      broadcast(condition)
    }, onError: { error in
      condition.lock()
      trigger = true
      broadcast(condition)
    })

    while !trigger && condition.wait(until: Date(timeIntervalSinceNow: 5)) {}
    disposable.dispose()

    return value
  }

  func flatMapCompletable(_ selector: @escaping (Element) throws -> Completable) -> Completable {
    return self
      .asObservable()
      .flatMap { try selector($0).asObservable() }
      .ignoreElements()
  }

  func asCompletable() -> Completable {
    return self.asObservable().ignoreElements()
  }
}

private func broadcast(_ condition: NSCondition) {
  defer { condition.unlock() }
  condition.broadcast()
}
