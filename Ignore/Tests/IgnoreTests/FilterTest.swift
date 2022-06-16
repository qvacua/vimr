/// Tae Won Ha - http://taewon.de - @hataewon
/// See LICENSE

@testable import Ignore
import Nimble
import XCTest

final class FilterTest: XCTestCase {
  let root = Bundle.module.url(forResource: "Resources", withExtension: nil)!

  func testProperties() {
    var ignore = Filter(base: root, pattern: "/a")
    expect(ignore.isAllow).to(beFalse())
    expect(ignore.isRelativeToBase).to(beTrue())
    expect(ignore.isOnlyForDirectories).to(beFalse())

    ignore = Filter(base: self.root, pattern: "a/b")
    expect(ignore.isAllow).to(beFalse())
    expect(ignore.isRelativeToBase).to(beTrue())
    expect(ignore.isOnlyForDirectories).to(beFalse())

    ignore = Filter(base: self.root, pattern: "a/b/")
    expect(ignore.isAllow).to(beFalse())
    expect(ignore.isRelativeToBase).to(beTrue())
    expect(ignore.isOnlyForDirectories).to(beTrue())

    ignore = Filter(base: self.root, pattern: "a/")
    expect(ignore.isAllow).to(beFalse())
    expect(ignore.isRelativeToBase).to(beFalse())
    expect(ignore.isOnlyForDirectories).to(beTrue())

    ignore = Filter(base: self.root, pattern: "!a/")
    expect(ignore.isAllow).to(beTrue())
    expect(ignore.isRelativeToBase).to(beFalse())
    expect(ignore.isOnlyForDirectories).to(beTrue())
  }

  func testNonRelativeIgnores() {
    var ignore = Filter(base: root, pattern: "ab\\ ")
    expect(ignore.disallows("ab ")).to(beTrue())
    expect(ignore.disallows("ab")).to(beFalse())

    ignore = Filter(base: self.root, pattern: "!include")
    expect(ignore.explicitlyAllows("include")).to(beTrue())
    expect(ignore.disallows("include")).to(beFalse())
    expect(ignore.explicitlyAllows("no-include")).to(beFalse())
    expect(ignore.disallows("no-include")).to(beFalse())

    ignore = Filter(base: self.root, pattern: "a")
    expect(ignore.disallows("a")).to(beTrue())

    ignore = Filter(base: self.root, pattern: "*.png")
    expect(ignore.disallows("a.png")).to(beTrue())
    expect(ignore.disallows("b.png")).to(beTrue())
  }

  func testNonRelativeIgnoresUrl() {
    var ignore = Filter(base: root, pattern: "ab\\ ")
    expect(ignore.disallows(self.root.appendingPathComponent("ab "))).to(beTrue())
    expect(ignore.explicitlyAllows(self.root.appendingPathComponent("ab"))).to(beFalse())
    expect(ignore.disallows(self.root.appendingPathComponent("foo/bar/ab "))).to(beTrue())
    expect(ignore.explicitlyAllows(self.root.appendingPathComponent("foo/bar/ab")))
      .to(beFalse())

    ignore = Filter(base: self.root, pattern: "!include")
    expect(ignore.explicitlyAllows(self.root.appendingPathComponent("include"))).to(beTrue())
    expect(ignore.disallows(self.root.appendingPathComponent("no-include"))).to(beFalse())
    expect(ignore.explicitlyAllows(self.root.appendingPathComponent("foo/bar/include")))
      .to(beTrue())
    expect(ignore.disallows(self.root.appendingPathComponent("foo/bar/no-include")))
      .to(beFalse())

    ignore = Filter(base: self.root, pattern: "a")
    expect(ignore.disallows(self.root.appendingPathComponent("a"))).to(beTrue())
    expect(ignore.explicitlyAllows(self.root.appendingPathComponent("b"))).to(beFalse())
    expect(ignore.disallows(self.root.appendingPathComponent("foo/bar/a"))).to(beTrue())
    expect(ignore.explicitlyAllows(self.root.appendingPathComponent("foo/bar/b")))
      .to(beFalse())

    ignore = Filter(base: self.root, pattern: "*.png")
    expect(ignore.disallows(self.root.appendingPathComponent("a.png"))).to(beTrue())
    expect(ignore.disallows(self.root.appendingPathComponent("b.png"))).to(beTrue())
    expect(ignore.explicitlyAllows(self.root.appendingPathComponent("c.jpg"))).to(beFalse())
    expect(ignore.disallows(self.root.appendingPathComponent("foo/bar/a.png"))).to(beTrue())
    expect(ignore.disallows(self.root.appendingPathComponent("foo/bar/b.png"))).to(beTrue())
    expect(ignore.explicitlyAllows(self.root.appendingPathComponent("foo/bar/c.jpg")))
      .to(beFalse())
  }

  func testRelativeIgnores() {
    var ignore = Filter(base: root, pattern: "**/foo")
    expect(ignore.disallows(self.root.appendingPathComponent("foo").path)).to(beTrue())
    expect(ignore.disallows(self.root.appendingPathComponent("a/b/foo").path)).to(beTrue())
    expect(ignore.explicitlyAllows(self.root.appendingPathComponent("a").path)).to(beFalse())

    ignore = Filter(base: self.root, pattern: "abc/**")
    expect(ignore.disallows(self.root.appendingPathComponent("abc/foo").path)).to(beTrue())
    expect(ignore.disallows(self.root.appendingPathComponent("abc/def/foo").path))
      .to(beTrue())
    expect(ignore.explicitlyAllows(self.root.appendingPathComponent("a/b/c").path))
      .to(beFalse())

    ignore = Filter(base: self.root, pattern: "a/**/b")
    expect(ignore.disallows(self.root.appendingPathComponent("a/b").path)).to(beTrue())
    expect(ignore.disallows(self.root.appendingPathComponent("a/x/b").path)).to(beTrue())
    expect(ignore.disallows(self.root.appendingPathComponent("a/x/y/b").path)).to(beTrue())
    expect(ignore.explicitlyAllows(self.root.appendingPathComponent("a/x/y/c").path))
      .to(beFalse())
  }

  func testRelativeIgnoresUrl() {
    var ignore = Filter(base: root, pattern: "**/foo")
    expect(ignore.disallows(self.root.appendingPathComponent("foo"))).to(beTrue())
    expect(ignore.disallows(self.root.appendingPathComponent("a/b/foo"))).to(beTrue())
    expect(ignore.explicitlyAllows(self.root.appendingPathComponent("a"))).to(beFalse())

    ignore = Filter(base: self.root, pattern: "abc/**")
    expect(ignore.disallows(self.root.appendingPathComponent("abc/foo"))).to(beTrue())
    expect(ignore.disallows(self.root.appendingPathComponent("abc/def/foo")))
      .to(beTrue())
    expect(ignore.explicitlyAllows(self.root.appendingPathComponent("a/b/c"))).to(beFalse())

    ignore = Filter(base: self.root, pattern: "a/**/b")
    expect(ignore.disallows(self.root.appendingPathComponent("a/b"))).to(beTrue())
    expect(ignore.disallows(self.root.appendingPathComponent("a/x/b"))).to(beTrue())
    expect(ignore.disallows(self.root.appendingPathComponent("a/x/y/b"))).to(beTrue())
    expect(ignore.explicitlyAllows(self.root.appendingPathComponent("a/x/y/c"))).to(beFalse())
  }
}
