/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import RxSwift

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

  func asCompletable() -> Completable {
    return self.asObservable().ignoreElements()
  }
}

private func broadcast(_ condition: NSCondition) {
  condition.lock()
  defer { condition.unlock() }
  condition.broadcast()
}