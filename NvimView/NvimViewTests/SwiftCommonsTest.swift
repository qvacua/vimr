/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import XCTest
import Nimble

@testable import NvimView

class SwiftCommonsTest: XCTestCase {

  struct Dummy {

    var value: Int
    var marker: Bool
  }

  func testArrayGroup1() {
    let grouped = [
      Dummy(value: 0, marker: true),
      Dummy(value: 1, marker: false),
      Dummy(value: 2, marker: false),
      Dummy(value: 3, marker: false),
    ].groupedRanges { i, element, array in element.marker }

    expect(grouped).to(haveCount(2))
    expect(grouped[0]).to(equal(0...0))
    expect(grouped[1]).to(equal(1...3))
  }

  func testArrayGroup2() {
    let grouped = [
      Dummy(value: 0, marker: false),
      Dummy(value: 1, marker: false),
      Dummy(value: 2, marker: false),
      Dummy(value: 3, marker: true),
    ].groupedRanges { i, element, array in element.marker }

    expect(grouped).to(haveCount(2))
    expect(grouped[0]).to(equal(0...2))
    expect(grouped[1]).to(equal(3...3))
  }

  func testArrayGroup3() {
    let grouped = [
      Dummy(value: 0, marker: true),
      Dummy(value: 1, marker: true),
    ].groupedRanges { i, element, array in element.marker }

    expect(grouped).to(haveCount(1))
    expect(grouped[0]).to(equal(0...1))
  }

  func testArrayGroup4() {
    let grouped = [
      Dummy(value: 0, marker: true),
      Dummy(value: 1, marker: true),
      Dummy(value: 1, marker: false),
      Dummy(value: 1, marker: true),
      Dummy(value: 1, marker: true),
    ].groupedRanges { i, element, array in element.marker }

    expect(grouped).to(haveCount(3))
    expect(grouped[0]).to(equal(0...1))
    expect(grouped[1]).to(equal(2...2))
    expect(grouped[2]).to(equal(3...4))
  }
}
