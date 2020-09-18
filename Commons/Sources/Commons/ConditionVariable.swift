/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

public final class ConditionVariable {
  private(set) var posted: Bool

  public init(posted: Bool = false) {
    self.posted = posted
  }

  public func wait(for seconds: TimeInterval, then fn: (() -> Void)? = nil) {
    self.condition.lock()
    defer { self.condition.unlock() }

    while !self.posted {
      self.condition.wait(until: Date(timeIntervalSinceNow: seconds))
      self.posted = true
    }

    fn?()
  }

  public func broadcast(then fn: (() -> Void)? = nil) {
    self.condition.lock()
    defer { self.condition.unlock() }

    self.posted = true
    self.condition.broadcast()

    fn?()
  }

  private let condition = NSCondition()
}
