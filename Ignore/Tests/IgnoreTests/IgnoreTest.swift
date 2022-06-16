/// Tae Won Ha - http://taewon.de - @hataewon
/// See LICENSE

@testable import Ignore
import Nimble
import XCTest

final class IgnoreTest: XCTestCase {
  func testIgnoreSplitting() {
    let root = Bundle.module.url(
      forResource: "IgnoreCollectionTest",
      withExtension: nil,
      subdirectory: "Resources"
    )!
    let c = Ignore(base: root, parent: nil)!

    expect(c.excludes(self.url("out", base: root, isDir: true))).to(beTrue())
    expect(c.excludes(self.url("out", base: root, isDir: false))).to(beFalse())
    expect(c.excludes(self.url("logs", base: root, isDir: true))).to(beTrue())
    expect(c.excludes(self.url("logs", base: root, isDir: false))).to(beFalse())

    expect(c.excludes(self.url("a.png", base: root))).to(beTrue())

    expect(c.excludes(self.url("include-me", base: root))).to(beFalse())
    expect(c.excludes(self.url("a/b/include-me", base: root))).to(beFalse())

    expect(c.excludes(self.url("ignore-me", base: root))).to(beTrue())
    expect(c.excludes(self.url("a/b/ignore-me", base: root))).to(beTrue())
  }

  private func url(_ path: String, base: URL, isDir: Bool = false) -> URL {
    URL(fileURLWithPath: path, isDirectory: isDir, relativeTo: base)
  }
}
