/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import os

class FuzzyMatcherPool {

  let pattern: String

  init(pattern: String, initialPoolSize: Int = 2) {
    self.pattern = pattern
    self.matchers = []
    for _ in 0..<initialPoolSize { self.matchers.append(FuzzyMatcher(pattern: pattern)) }
  }

  func request() -> FuzzyMatcher {
    return self.lock.withLock {
      if self.matchers.isEmpty {
        let matcher = FuzzyMatcher(pattern: self.pattern)
        return matcher
      }

      let matcher = self.matchers.popLast()! // We know that the array is not empty!
      return matcher
    }
  }

  func giveBack(_ matcher: FuzzyMatcher) {
    self.lock.withLock { self.matchers.append(matcher) }
  }

  deinit {
    self.log.debug(
      "DEBUG FuzzyMatcherPool with pattern '\(self.pattern)' had \(self.matchers.count) matchers."
    )
  }

  private var matchers: [FuzzyMatcher]
  private let lock = NSLock()

  private let log = OSLog(subsystem: Defs.loggerSubsystem, category: Defs.LoggerCategory.service)
}

private extension NSLocking {

  func withLock<T>(_ body: () -> T) -> T {
    self.lock()
    defer { self.unlock() }
    return body()
  }
}
