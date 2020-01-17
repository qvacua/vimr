/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

class ConditionVariable {

  private(set) var posted: Bool

  init(posted: Bool = false) {
    self.posted = posted
  }

  func wait(`for` seconds: TimeInterval, then fn: (() -> Void)? = nil) {
    self.condition.lock()
    defer { self.condition.unlock() }

    while !self.posted {
      self.condition.wait(until: Date(timeIntervalSinceNow: seconds))
    }

    fn?()
  }

  func broadcast(then fn: (() -> Void)? = nil) {
    self.condition.lock()
    defer { self.condition.unlock() }

    self.posted = true
    self.condition.broadcast()

    fn?()
  }

  private let condition = NSCondition()
}
