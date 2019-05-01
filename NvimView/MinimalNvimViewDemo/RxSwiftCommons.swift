/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import RxSwift

extension PrimitiveSequence where Element == Never, Trait == CompletableTrait {

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

    if let e = err {
      throw e
    }
  }
}
