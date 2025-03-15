/// Tae Won Ha - http://taewon.de - @hataewon
/// See LICENSE

import Foundation

public final class AsyncFuture<Element: Sendable>: Sendable {
  public typealias ResultType = Result<Element, Swift.Error>

  public init() {
    (self.stream, self.continuation) = AsyncStream.makeStream()
  }

  public func yield(_ result: ResultType) {
    self.continuation.yield(result)
    self.continuation.finish()
  }

  public func value() async -> ResultType {
    for await result in self.stream {
      // Return the first (and only) value
      return result
    }

    fatalError("This should not happen!")
  }

  // MARK: Private

  private let stream: AsyncStream<ResultType>
  private let continuation: AsyncStream<ResultType>.Continuation
}
