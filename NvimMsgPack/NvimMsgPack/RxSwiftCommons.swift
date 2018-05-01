/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import RxSwift

extension PrimitiveSequence where Element == Never, TraitType == CompletableTrait {

  func wait() {
    var trigger = false
    let condition = NSCondition()

    condition.lock()
    defer { condition.unlock() }

    let disposable = self.subscribe(onCompleted: {
      trigger = broadcast(condition)
    }, onError: { error in
      trigger = broadcast(condition)
    })

    while !trigger && condition.wait(until: Date(timeIntervalSinceNow: 5)) {}
    disposable.dispose()
  }
}

extension PrimitiveSequence where TraitType == SingleTrait {

  func syncValue() -> Element? {
    var value: Element?
    var trigger = false
    let condition = NSCondition()

    condition.lock()
    defer { condition.unlock() }

    let disposable = self.subscribe(onSuccess: { result in
      value = result
      trigger = broadcast(condition)
    }, onError: { error in
      trigger = broadcast(condition)
    })

    while !trigger && condition.wait(until: Date(timeIntervalSinceNow: 5)) {
      print("waiting: \(Thread.current)")
    }
    disposable.dispose()

    return value
  }

  func asCompletable() -> Completable {
    return self.asObservable().ignoreElements()
  }
}

fileprivate func broadcast(_ condition: NSCondition) -> Bool {
  condition.lock()
  defer { condition.unlock() }
  condition.broadcast()

  return true
}