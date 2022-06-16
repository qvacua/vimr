/// Tae Won Ha - http://taewon.de - @hataewon
/// See LICENSE

@testable import Ignore
import Nimble
import XCTest

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
    specs.forEach { spec in
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
    specs.forEach { spec in
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
    specs.forEach { spec in
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
