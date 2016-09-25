/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import XCTest
import Nimble

class FileUtilsTest: XCTestCase {

  var fileUtilsRsrcUrl = URL()
  var a1Dir = URL()

  override func setUp() {
    fileUtilsRsrcUrl = Bundle.init(for: type(of: self)).url(forResource: "FileUtilsTest", withExtension: "")!
    a1Dir = fileUtilsRsrcUrl.appendingPathComponent("a1")
  }

  func testCommonParentOneDirUrl() {
    let urls = [
      fileUtilsRsrcUrl.appendingPathComponent("a1"),
    ]

    expect(FileUtils.commonParent(ofUrls: urls)).to(equal(a1Dir))
  }

  func testCommonParentOneFileUrl() {
    let urls = [
      fileUtilsRsrcUrl.appendingPathComponent("a1/a1-file1"),
    ]

    expect(FileUtils.commonParent(ofUrls: urls)).to(equal(a1Dir))
  }

  func testCommonParentEmptyParams() {
    expect(FileUtils.commonParent(ofUrls: []) as URL).to(equal(URL(fileURLWithPath: "/", isDirectory: true)))
  }

  func testCommonParent1() {
    let urls = [
      fileUtilsRsrcUrl.appendingPathComponent("a1"),
      fileUtilsRsrcUrl.appendingPathComponent("a1/a1-file1"),
    ]

    expect(FileUtils.commonParent(ofUrls: urls)).to(equal(a1Dir))
  }

  func testCommonParent2() {
    let urls = [
      fileUtilsRsrcUrl.appendingPathComponent("a1"),
      fileUtilsRsrcUrl.appendingPathComponent("a1/a1-file1"),
      fileUtilsRsrcUrl.appendingPathComponent("a1/a2/a1-a2-file1"),
    ]

    expect(FileUtils.commonParent(ofUrls: urls)).to(equal(a1Dir))
  }

  func testCommonParent3() {
    let urls = [
      fileUtilsRsrcUrl.appendingPathComponent("a1"),
      fileUtilsRsrcUrl.appendingPathComponent("a1/a1-file1"),
      fileUtilsRsrcUrl.appendingPathComponent("a1/a2/a1-a2-file1"),
      fileUtilsRsrcUrl.appendingPathComponent("b1/b1-file1"),
    ]

    expect(FileUtils.commonParent(ofUrls: urls)).to(equal(fileUtilsRsrcUrl))
  }

  func testCommonParent4() {
    let urls = [
      fileUtilsRsrcUrl.appendingPathComponent("a1"),
      fileUtilsRsrcUrl.appendingPathComponent("a1/a1-file1"),
      fileUtilsRsrcUrl.appendingPathComponent("a1/a2/a1-a2-file1"),
      fileUtilsRsrcUrl.appendingPathComponent("b1"),
    ]

    expect(FileUtils.commonParent(ofUrls: urls)).to(equal(fileUtilsRsrcUrl))
  }

  func testCommonParent5() {
    let urls = [
      fileUtilsRsrcUrl.appendingPathComponent("a1/a1-file1"),
      fileUtilsRsrcUrl.appendingPathComponent("a1/a2/a1-a2-file1"),
      fileUtilsRsrcUrl.appendingPathComponent("a1/a2"),
    ]

    expect(FileUtils.commonParent(ofUrls: urls)).to(equal(a1Dir))
  }
}
