/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import XCTest
import Nimble

class FileItemIgnorePatternTest: XCTestCase {

  var pattern: FileItemIgnorePattern = FileItemIgnorePattern(pattern: "dummy")

  func testMatchFolder() {
    pattern = FileItemIgnorePattern(pattern: "*/.git")

    expect(self.pattern.match(absolutePath: "/a/b/c/.git")).to(equal(true))
    expect(self.pattern.match(absolutePath: "/a/b/c/.git/d")).to(equal(true))
    expect(self.pattern.match(absolutePath: "/a/b/c/.git/d/e")).to(equal(true))

    expect(self.pattern.match(absolutePath: "/a/b/c/.gitfolder/d")).to(equal(false))
    expect(self.pattern.match(absolutePath: "/a/b/c/1.git/d")).to(equal(false))
    expect(self.pattern.match(absolutePath: ".git")).to(equal(false))
    expect(self.pattern.match(absolutePath: "/a/b/c/.hg/d")).to(equal(false))
  }

  func testMatchFolderMultipleWildCards() {
    pattern = FileItemIgnorePattern(pattern: "*/*.xcodeproj")

    expect(self.pattern.match(absolutePath: "/a/b/c/VimR.xcodeproj")).to(equal(true))
    expect(self.pattern.match(absolutePath: "/a/b/c/VimR.xcodeproj/somefile")).to(equal(true))
    expect(self.pattern.match(absolutePath: "/a/b/c/VimR.xcodeproj/somefile/deep")).to(equal(true))
    expect(self.pattern.match(absolutePath: "/a/b/c/VimR.xcworkspace/somefile")).to(equal(false))
  }

  func testMatchSuffix() {
    pattern = FileItemIgnorePattern(pattern: "*.png")

    expect(self.pattern.match(absolutePath: "/a/b/c/d.png")).to(equal(true))
    expect(self.pattern.match(absolutePath: "a.png")).to(equal(true))

    expect(self.pattern.match(absolutePath: "/a/b/c/d.pnge")).to(equal(false))
    expect(self.pattern.match(absolutePath: "/a/b/c/d.png/e")).to(equal(false))
  }

  func testMatchPrefix() {
    pattern = FileItemIgnorePattern(pattern: "vr*")

    expect(self.pattern.match(absolutePath: "/a/b/c/vr.png")).to(equal(true))
    expect(self.pattern.match(absolutePath: "vr.png")).to(equal(true))

    expect(self.pattern.match(absolutePath: "/a/b/c/wvr.png")).to(equal(false))
    expect(self.pattern.match(absolutePath: "/a/b/c/wvr.png/e")).to(equal(false))
  }

  func testMatchExact() {
    pattern = FileItemIgnorePattern(pattern: "some")

    expect(self.pattern.match(absolutePath: "/a/b/c/some")).to(equal(true))
    expect(self.pattern.match(absolutePath: "some")).to(equal(true))

    expect(self.pattern.match(absolutePath: "/a/b/c/some1")).to(equal(false))
    expect(self.pattern.match(absolutePath: "/a/b/c/1some")).to(equal(false))
  }
}
