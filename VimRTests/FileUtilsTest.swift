/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import XCTest
import Nimble

class FileUtilsTest: XCTestCase {

  var fileUtilsRsrcUrl = NSURL()
  var a1Dir = NSURL()

  override func setUp() {
    fileUtilsRsrcUrl = NSBundle.init(forClass: self.dynamicType).URLForResource("FileUtilsTest", withExtension: "")!
    a1Dir = fileUtilsRsrcUrl.URLByAppendingPathComponent("a1")
  }

  func testCommonParentOneDirUrl() {
    let urls = [
      fileUtilsRsrcUrl.URLByAppendingPathComponent("a1"),
    ]

    expect(FileUtils.commonParent(ofUrls: urls)).to(equal(a1Dir))
  }

  func testCommonParentOneFileUrl() {
    let urls = [
      fileUtilsRsrcUrl.URLByAppendingPathComponent("a1/a1-file1"),
    ]

    expect(FileUtils.commonParent(ofUrls: urls)).to(equal(a1Dir))
  }

  func testCommonParentEmptyParams() {
    expect(FileUtils.commonParent(ofUrls: [])).to(equal(NSURL(fileURLWithPath: "/", isDirectory: true)))
  }

  func testCommonParent1() {
    let urls = [
      fileUtilsRsrcUrl.URLByAppendingPathComponent("a1"),
      fileUtilsRsrcUrl.URLByAppendingPathComponent("a1/a1-file1"),
    ]

    expect(FileUtils.commonParent(ofUrls: urls)).to(equal(a1Dir))
  }

  func testCommonParent2() {
    let urls = [
      fileUtilsRsrcUrl.URLByAppendingPathComponent("a1"),
      fileUtilsRsrcUrl.URLByAppendingPathComponent("a1/a1-file1"),
      fileUtilsRsrcUrl.URLByAppendingPathComponent("a1/a2/a1-a2-file1"),
    ]

    expect(FileUtils.commonParent(ofUrls: urls)).to(equal(a1Dir))
  }

  func testCommonParent3() {
    let urls = [
      fileUtilsRsrcUrl.URLByAppendingPathComponent("a1"),
      fileUtilsRsrcUrl.URLByAppendingPathComponent("a1/a1-file1"),
      fileUtilsRsrcUrl.URLByAppendingPathComponent("a1/a2/a1-a2-file1"),
      fileUtilsRsrcUrl.URLByAppendingPathComponent("b1/b1-file1"),
    ]

    expect(FileUtils.commonParent(ofUrls: urls)).to(equal(fileUtilsRsrcUrl))
  }

  func testCommonParent4() {
    let urls = [
      fileUtilsRsrcUrl.URLByAppendingPathComponent("a1"),
      fileUtilsRsrcUrl.URLByAppendingPathComponent("a1/a1-file1"),
      fileUtilsRsrcUrl.URLByAppendingPathComponent("a1/a2/a1-a2-file1"),
      fileUtilsRsrcUrl.URLByAppendingPathComponent("b1"),
    ]

    expect(FileUtils.commonParent(ofUrls: urls)).to(equal(fileUtilsRsrcUrl))
  }

  func testCommonParent5() {
    let urls = [
      fileUtilsRsrcUrl.URLByAppendingPathComponent("a1/a1-file1"),
      fileUtilsRsrcUrl.URLByAppendingPathComponent("a1/a2/a1-a2-file1"),
      fileUtilsRsrcUrl.URLByAppendingPathComponent("a1/a2"),
    ]

    expect(FileUtils.commonParent(ofUrls: urls)).to(equal(a1Dir))
  }
}
