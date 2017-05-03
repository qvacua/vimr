/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import XCTest
import Nimble
@testable import VimR

class UrlCommonsTest: XCTestCase {

  func testIsDirectParent() {
    let parent = URL(fileURLWithPath: "/some/path")
    let child = URL(fileURLWithPath: "/some/path/text.txt")
    let noChild1 = URL(fileURLWithPath: "/some/where/else/text.txt")
    let noChild2 = URL(fileURLWithPath: "/some/text.txt")

    expect(parent.isDirectParent(of: child)).to(beTrue())
    expect(parent.isDirectParent(of: noChild1)).to(beFalse())
    expect(parent.isDirectParent(of: noChild2)).to(beFalse())
  }

  func testIsParent() {
    let parent = URL(fileURLWithPath: "/some/path")
    let child1 = URL(fileURLWithPath: "/some/path/text.txt")
    let child2 = URL(fileURLWithPath: "/some/path/deep/text.txt")
    let noChild1 = URL(fileURLWithPath: "/some/where/else/text.txt")
    let noChild2 = URL(fileURLWithPath: "/some/text.txt")

    expect(parent.isParent(of: child1)).to(beTrue())
    expect(parent.isParent(of: child2)).to(beTrue())
    expect(parent.isParent(of: noChild1)).to(beFalse())
    expect(parent.isParent(of: noChild2)).to(beFalse())
  }

  func testIsContained() {
    let parent = URL(fileURLWithPath: "/some/path")
    let child1 = URL(fileURLWithPath: "/some/path/text.txt")
    let child2 = URL(fileURLWithPath: "/some/path/deep/text.txt")
    let noChild1 = URL(fileURLWithPath: "/some/where/else/text.txt")
    let noChild2 = URL(fileURLWithPath: "/some/text.txt")

    expect(child1.isContained(in: parent)).to(beTrue())
    expect(child2.isContained(in: parent)).to(beTrue())
    expect(noChild1.isContained(in: parent)).to(beFalse())
    expect(noChild2.isContained(in: parent)).to(beFalse())
  }

  func testParent() {
    expect(URL(fileURLWithPath: "/some/path/").parent).to(equal(URL(fileURLWithPath: "/some/")))
    expect(URL(fileURLWithPath: "/some/path/text.txt").parent).to(equal(URL(fileURLWithPath: "/some/path/")))
    expect(URL(fileURLWithPath: "/").parent).to(equal(URL(fileURLWithPath: "/")))
  }

  func testIsDir() {
    let resourceUrl = Bundle.init(for: type(of: self)).url(forResource: "UrlCommonsTest", withExtension: "")!
    let hidden = resourceUrl.appendingPathComponent(".dot-hidden-file")

    expect(resourceUrl.isDir).to(beTrue())
    expect(hidden.isDir).to(beFalse())
  }

  func testIsHidden() {
    let resourceUrl = Bundle.init(for: type(of: self)).url(forResource: "UrlCommonsTest", withExtension: "")!
    let hidden = resourceUrl.appendingPathComponent(".dot-hidden-file")

    expect(hidden.isHidden).to(beTrue())
    expect(resourceUrl.isHidden).to(beFalse())
  }

  func testIsPackage() {
    let resourceUrl = Bundle.init(for: type(of: self)).url(forResource: "UrlCommonsTest", withExtension: "")!
    let package = resourceUrl.appendingPathComponent("dummy.rtfd")

    expect(package.isPackage).to(beTrue())
    expect(resourceUrl.isPackage).to(beFalse())
  }
}
