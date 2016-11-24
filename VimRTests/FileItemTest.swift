/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import XCTest
import Nimble
import RxSwift
@testable import VimR

class FileItemTest: XCTestCase {

  let fileItemService = FileItemService(source: Observable.empty())

  var fileUtilsRsrcUrl = URL(fileURLWithPath: "/")
  var root = FileItem(FileUtils.userHomeUrl)
  var a1Dir = URL(fileURLWithPath: "/")

  override func setUp() {
    fileUtilsRsrcUrl = Bundle.init(for: type(of: self)).url(forResource: "FileUtilsTest", withExtension: "")!

    root = fileItemService.fileItemWithChildren(for: fileUtilsRsrcUrl)!
    a1Dir = fileUtilsRsrcUrl.appendingPathComponent("a1")
  }

  func testChildWithUrl() {
    let child = root.child(with: root.url.appendingPathComponent("a1"))
    expect(child).to(equal(FileItem(root.url.appendingPathComponent("a1"))))
  }

  func testDeepChildWithUrl() {
    let child = root.child(with: root.url.appendingPathComponent("a1"))!
    child.children = fileItemService.fileItemWithChildren(for: child.url)!.children

    let targetChildUrl = root.url.appendingPathComponent("a1/a2")
    expect(self.root.deepChild(with: targetChildUrl)).to(equal(FileItem(targetChildUrl)))
  }

  func testDeepChildWithUrl2() {
    let a1 = root.child(with: root.url.appendingPathComponent("a1"))!
    a1.children = fileItemService.fileItemWithChildren(for: a1.url)!.children

    let a2 = a1.child(with: a1.url.appendingPathComponent("a2"))!
    a2.children = fileItemService.fileItemWithChildren(for: a2.url)!.children

    let targetChildUrl = root.url.appendingPathComponent("a1/a2/a1-a2-file1")
    expect(self.root.deepChild(with: targetChildUrl)).to(equal(FileItem(targetChildUrl)))
  }

  func testDeepChildWithUrlNotExisting() {
    let a1 = root.child(with: root.url.appendingPathComponent("a1"))!
    a1.children = fileItemService.fileItemWithChildren(for: a1.url)!.children

    let a2 = a1.child(with: a1.url.appendingPathComponent("a2"))!
    a2.children = fileItemService.fileItemWithChildren(for: a2.url)!.children

    let targetChildUrl = root.url.appendingPathComponent("a1/a3/a1-a2-file1")
    expect(self.root.deepChild(with: targetChildUrl)).to(beNil())
  }

  func testDeepChildWithUrlNotExisting2() {
    let child = root.child(with: root.url.appendingPathComponent("a1"))!
    child.children = fileItemService.fileItemWithChildren(for: child.url)!.children

    let targetChildUrl = root.url.appendingPathComponent("foobar")
    expect(self.root.deepChild(with: targetChildUrl)).to(beNil())
  }

  func testDeepChildWithUrlNotExisting3() {
    let child = root.child(with: root.url.appendingPathComponent("a1"))!
    child.children = fileItemService.fileItemWithChildren(for: child.url)!.children

    let targetChildUrl = FileUtils.userHomeUrl
    expect(self.root.deepChild(with: targetChildUrl)).to(beNil())
  }

  func testRemoveChildWithUrl() {
    root.remove(childWith: root.url.appendingPathComponent("b1"))

    expect(self.root.children).to(haveCount(1))
    expect(self.root.children[0]).to(equal(FileItem(root.url.appendingPathComponent("a1"))))
  }
}
