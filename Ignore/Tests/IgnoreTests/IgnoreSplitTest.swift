/// Tae Won Ha - http://taewon.de - @hataewon
/// See LICENSE

@testable import Ignore
import Nimble
import XCTest

private struct IgnoreSplittingTestSpec {
  var fileName: String
  var mixed: [String]
  var disallow: [String]
}

private let ignoreSplittingTestSpecs = [
  IgnoreSplittingTestSpec(
    fileName: "ignore-splitting-0",
    mixed: [],
    disallow: ["*.a", "*.b", "*.c", "*.d"]
  ),
  IgnoreSplittingTestSpec(
    fileName: "ignore-splitting-1",
    mixed: ["*.a"],
    disallow: ["*.b", "*.c", "*.d"]
  ),
  IgnoreSplittingTestSpec(
    fileName: "ignore-splitting-2",
    mixed: ["*.a", "*.b"],
    disallow: ["*.c", "*.d"]
  ),
  IgnoreSplittingTestSpec(
    fileName: "ignore-splitting-3",
    mixed: ["*.a", "*.b", "*.c"],
    disallow: ["*.d"]
  ),
  IgnoreSplittingTestSpec(
    fileName: "ignore-splitting-4",
    mixed: ["*.a", "*.b", "*.c", "*.d"],
    disallow: []
  ),
]

final class IgnoreSplitTest: XCTestCase {
  func testIgnoreSplitting() {
    ignoreSplittingTestSpecs.forEach { spec in
      let url = Bundle.module.url(
        forResource: "IgnoreCollectionTest",
        withExtension: nil,
        subdirectory: "Resources"
      )!
      let ignoreFile = Ignore(base: url, parent: nil, ignoreFileNames: [spec.fileName])!

      expect(ignoreFile.mixedIgnores.map(\.pattern)).to(equal(spec.mixed))
      expect(ignoreFile.remainingDisallowIgnores.map(\.pattern)).to(equal(spec.disallow))
    }
  }
}
