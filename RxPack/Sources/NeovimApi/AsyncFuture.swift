/// Tae Won Ha - http://taewon.de - @hataewon
/// See LICENSE

import Foundation
import os

public final class AsyncFuture<Element: Sendable>: Sendable {
  public typealias ResultType = Result<Element, Swift.Error>

  public init() {
    (self.stream, self.continuation) = AsyncStream.makeStream()
    self.defaultValue = nil
  }

  public init(_ result: ResultType) {
    (self.stream, self.continuation) = AsyncStream.makeStream()
    self.defaultValue = result
  }

  public func yield(_ result: ResultType) {
    guard self.defaultValue == nil else { fatalError("This should not happen!") }

    self.continuation.yield(result)
    self.continuation.finish()
  }

  public func value() async -> ResultType {
    if let defaultValue = self.defaultValue { return defaultValue }

    for await result in self.stream {
      // Return the first (and only) value
      return result
    }

    fatalError("This should not happen!")
  }

  // MARK: Private

  private let stream: AsyncStream<ResultType>
  private let continuation: AsyncStream<ResultType>.Continuation

  private let defaultValue: ResultType?
}
