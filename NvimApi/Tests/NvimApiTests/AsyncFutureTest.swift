/// Tae Won Ha - http://taewon.de - @hataewon
/// See LICENSE

import Foundation
import NvimApi
import Testing

class AsyncFutureTest {
  @Test func testAsyncFuture() async throws {
    let future = AsyncFuture<Int>()

    DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
      future.yield(.success(1))
    }

    try await Task.sleep(nanoseconds: 2 * nanoSecondsPerSecond)

    #expect(try await future.value().get() == 1)
  }
}

private let nanoSecondsPerSecond: UInt64 = 1_000_000_000
