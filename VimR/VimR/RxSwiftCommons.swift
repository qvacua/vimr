/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import RxSwift

extension ObservableType {

  func mapOmittingNil<R>(_ transform: @escaping (E) throws -> R?) -> RxSwift.Observable<R> {
    return self
      .map(transform)
      .filter { $0 != nil }
      .map { $0! }
  }
}

extension PrimitiveSequenceType where TraitType == CompletableTrait, ElementType == Never {

  func andThen(using body: () -> Completable) -> Completable {
    return self.andThen(body())
  }
}

extension PrimitiveSequence where Element == Never, TraitType == CompletableTrait {

  func wait() throws {
    var trigger = false
    var err: Error? = nil

    let condition = NSCondition()

    condition.lock()
    defer { condition.unlock() }

    let disposable = self.subscribe(onCompleted: {
      trigger = true
      broadcast(condition)
    }, onError: { error in
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

  func flatMapCompletable(_ selector: @escaping (Element) throws -> Completable) -> Completable {
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
      trigger = true
      broadcast(condition)
    }, onError: { error in
      trigger = true
      broadcast(condition)
    })

    while !trigger && condition.wait(until: Date(timeIntervalSinceNow: 5)) {}
    disposable.dispose()

    return value
  }
}

private func broadcast(_ condition: NSCondition) {
  condition.lock()
  defer { condition.unlock() }
  condition.broadcast()
}
