/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Nimble
import XCTest

@testable import Commons

class FileUtilsTest: XCTestCase {
  var fileUtilsRsrcUrl = URL(fileURLWithPath: "/")
  var a1Dir = URL(fileURLWithPath: "/")

  override func setUp() {
    self.fileUtilsRsrcUrl = Bundle.module.url(
      forResource: "FileUtilsTest",
      withExtension: "",
      subdirectory: "Resources"
    )!
    self.a1Dir = self.fileUtilsRsrcUrl.appendingPathComponent("a1")
  }

  func testCommonParentOneDirUrl() {
    let urls = [
      fileUtilsRsrcUrl.appendingPathComponent("a1"),
    ]

    expect(FileUtils.commonParent(of: urls)).to(equal(self.fileUtilsRsrcUrl))
  }

  func testCommonParentOneFileUrl() {
    let urls = [
      fileUtilsRsrcUrl.appendingPathComponent("a1/a1-file1"),
    ]

    expect(FileUtils.commonParent(of: urls)).to(equal(self.a1Dir))
  }

  func testCommonParentEmptyParams() {
    expect(FileUtils.commonParent(of: []) as URL)
      .to(equal(URL(fileURLWithPath: "/", isDirectory: true)))
  }

  func testCommonParent1() {
    let urls = [
      fileUtilsRsrcUrl.appendingPathComponent("a1"),
      self.fileUtilsRsrcUrl.appendingPathComponent("a1/a1-file1"),
    ]

    expect(FileUtils.commonParent(of: urls)).to(equal(self.fileUtilsRsrcUrl))
  }

  func testCommonParent2() {
    let urls = [
      fileUtilsRsrcUrl.appendingPathComponent("a1"),
      self.fileUtilsRsrcUrl.appendingPathComponent("a1/a1-file1"),
      self.fileUtilsRsrcUrl.appendingPathComponent("a1/a2/a1-a2-file1"),
    ]

    expect(FileUtils.commonParent(of: urls)).to(equal(self.fileUtilsRsrcUrl))
  }

  func testBug1() {
    let paths = [
      fileUtilsRsrcUrl.appendingPathComponent("Downloads/test2/some/nginx.config"),
      self.fileUtilsRsrcUrl.appendingPathComponent(".Trash/nginx.config"),
    ]
    expect(FileUtils.commonParent(of: paths)).to(equal(self.fileUtilsRsrcUrl))
  }

  func testBug2() {
    let paths = [
      fileUtilsRsrcUrl.appendingPathComponent("Downloads/test2/some/nginx.config"),
      self.fileUtilsRsrcUrl.appendingPathComponent(".Trash/nginx.config/de/nginx.config"),
    ]
    expect(FileUtils.commonParent(of: paths)).to(equal(self.fileUtilsRsrcUrl))
  }

  func testCommonParent3() {
    let urls = [
      fileUtilsRsrcUrl.appendingPathComponent("a1"),
      self.fileUtilsRsrcUrl.appendingPathComponent("a1/a1-file1"),
      self.fileUtilsRsrcUrl.appendingPathComponent("a1/a2/a1-a2-file1"),
      self.fileUtilsRsrcUrl.appendingPathComponent("b1/b1-file1"),
    ]

    expect(FileUtils.commonParent(of: urls)).to(equal(self.fileUtilsRsrcUrl))
  }

  func testCommonParent4() {
    let urls = [
      fileUtilsRsrcUrl.appendingPathComponent("a1"),
      self.fileUtilsRsrcUrl.appendingPathComponent("a1/a1-file1"),
      self.fileUtilsRsrcUrl.appendingPathComponent("a1/a2/a1-a2-file1"),
      self.fileUtilsRsrcUrl.appendingPathComponent("b1"),
    ]

    expect(FileUtils.commonParent(of: urls)).to(equal(self.fileUtilsRsrcUrl))
  }

  func testCommonParent5() {
    let urls = [
      fileUtilsRsrcUrl.appendingPathComponent("a1/a1-file1"),
      self.fileUtilsRsrcUrl.appendingPathComponent("a1/a2/a1-a2-file1"),
      self.fileUtilsRsrcUrl.appendingPathComponent("a1/a2"),
    ]

    expect(FileUtils.commonParent(of: urls)).to(equal(self.a1Dir))
  }
}
