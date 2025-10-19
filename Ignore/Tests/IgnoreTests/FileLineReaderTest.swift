/// Tae Won Ha - http://taewon.de - @hataewon
/// See LICENSE

import Nimble
import XCTest
@testable import Ignore

private struct TestSpec {
  var fileName: String
  var result: [String]
}

private let specs = [
  TestSpec(fileName: "empty", result: []),
  TestSpec(fileName: "unix-only-new-lines", result: ["\n", "\n", "\n"]),
  TestSpec(fileName: "unix-no-line-ending-at-the-end", result: ["0123\n", "하태원\n", "abcde"]),
  TestSpec(fileName: "unix-with-line-ending-at-the-end", result: ["0123\n", "하태원\n", "abcde\n"]),
  TestSpec(fileName: "dos-only-new-lines", result: ["\r\n", "\r\n", "\r\n"]),
  TestSpec(fileName: "dos-no-line-ending-at-the-end", result: ["0123\r\n", "하태원\r\n", "abcde"]),
  TestSpec(
    fileName: "dos-with-line-ending-at-the-end",
    result: ["0123\r\n", "하태원\r\n", "abcde\r\n"]
  ),
]

final class FileLineReaderTest: XCTestCase {
  func testSpecsDefaultBuffer() {
    for spec in specs {
      let url = Bundle.module.url(
        forResource: spec.fileName,
        withExtension: "txt",
        subdirectory: "Resources/FileLineReaderTest"
      )!
      let lineReader = FileLineReader(url: url, encoding: .utf8)
      let lines = Array(lineReader)

      expect(lines).to(equal(spec.result))
    }
  }

  func testSpecsSmallBuffer() {
    for spec in specs {
      let url = Bundle.module.url(
        forResource: spec.fileName,
        withExtension: "txt",
        subdirectory: "Resources/FileLineReaderTest"
      )!
      let lineReader = FileLineReader(url: url, encoding: .utf8, lineBufferCount: 5)
      let lines = Array(lineReader)

      expect(lines).to(equal(spec.result))
    }
  }

  func testSpecsBigBuffer() {
    for spec in specs {
      let url = Bundle.module.url(
        forResource: spec.fileName,
        withExtension: "txt",
        subdirectory: "Resources/FileLineReaderTest"
      )!
      let lineReader = FileLineReader(url: url, encoding: .utf8, lineBufferCount: 2048)
      let lines = Array(lineReader)

      expect(lines).to(equal(spec.result))
    }
  }
}
