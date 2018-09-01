/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import XCTest
import Nimble

@testable import NvimView

struct Dummy {

  var value: Int
  var marker: Bool
}

class ArraySliceTest: XCTestCase {

  func testArraySliceGroup1() {
    let grouped = [
      Dummy(value: 0, marker: true),

      Dummy(value: 0, marker: true),
      Dummy(value: 1, marker: false),
      Dummy(value: 2, marker: false),

      Dummy(value: 3, marker: false),
    ][1...3].groupedRanges { i, element, array in element.marker }

    expect(grouped).to(equal(
      [
        1...1,
        2...3,
      ]
    ))
  }

  func testArraySliceGroup2() {
    let grouped = [
      Dummy(value: 0, marker: false),

      Dummy(value: 1, marker: false),
      Dummy(value: 2, marker: false),
      Dummy(value: 3, marker: true),

      Dummy(value: 3, marker: true),
    ][1...3].groupedRanges { i, element, array in element.marker }

    expect(grouped).to(equal(
      [
        1...2,
        3...3,
      ]
    ))
  }

  func testArraySliceGroup3() {
    let grouped = [
      Dummy(value: 0, marker: true),

      Dummy(value: 1, marker: true),
      Dummy(value: 2, marker: true),

      Dummy(value: 3, marker: true),
    ][1...2].groupedRanges { i, element, array in element.marker }

    expect(grouped).to(equal(
      [
        1...2
      ]
    ))
  }

  func testArraySliceGroup4() {
    let grouped = [
      Dummy(value: 0, marker: true),

      Dummy(value: 0, marker: true),
      Dummy(value: 1, marker: true),
      Dummy(value: 1, marker: false),
      Dummy(value: 1, marker: true),
      Dummy(value: 1, marker: true),

      Dummy(value: 1, marker: true),
    ][1...5].groupedRanges { i, element, array in element.marker }

    expect(grouped).to(equal(
      [
        1...2,
        3...3,
        4...5,
      ]
    ))
  }

  func testArraySliceGroup5() {
    let grouped = [
      Dummy(value: 0, marker: true),

      Dummy(value: 0, marker: true),
      Dummy(value: 1, marker: true),
      Dummy(value: 1, marker: true),
      Dummy(value: 1, marker: false),
      Dummy(value: 1, marker: true),

      Dummy(value: 1, marker: true),
    ][1...5].groupedRanges { i, element, array in element.marker }

    expect(grouped).to(equal(
      [
        1...3,
        4...4,
        5...5,
      ]
    ))
  }

  func testArraySliceGroup6() {
    let grouped = [
      Dummy(value: 0, marker: true),

      Dummy(value: 0, marker: true),

      Dummy(value: 0, marker: true),
    ][1...1].groupedRanges { i, element, array in element.marker }

    expect(grouped).to(equal(
      [
        1...1
      ]
    ))
  }
}

class SwiftCommonsTest: XCTestCase {

  func testArrayGroup1() {
    let grouped = [
      Dummy(value: 0, marker: true),
      Dummy(value: 1, marker: false),
      Dummy(value: 2, marker: false),
      Dummy(value: 3, marker: false),
    ].groupedRanges { i, element, array in element.marker }

    expect(grouped).to(equal(
      [
        0...0,
        1...3,
      ]
    ))
  }

  func testArrayGroup2() {
    let grouped = [
      Dummy(value: 0, marker: false),
      Dummy(value: 1, marker: false),
      Dummy(value: 2, marker: false),
      Dummy(value: 3, marker: true),
    ].groupedRanges { i, element, array in element.marker }

    expect(grouped).to(equal(
      [
        0...2,
        3...3,
      ]
    ))
  }

  func testArrayGroup3() {
    let grouped = [
      Dummy(value: 0, marker: true),
      Dummy(value: 1, marker: true),
    ].groupedRanges { i, element, array in element.marker }

    expect(grouped).to(equal(
      [
        0...1
      ]
    ))
  }

  func testArrayGroup4() {
    let grouped = [
      Dummy(value: 0, marker: true),
      Dummy(value: 1, marker: true),
      Dummy(value: 1, marker: false),
      Dummy(value: 1, marker: true),
      Dummy(value: 1, marker: true),
    ].groupedRanges { i, element, array in element.marker }

    expect(grouped).to(equal(
      [
        0...1,
        2...2,
        3...4,
      ]
    ))
  }

  func testArrayGroup5() {
    let grouped = [
      Dummy(value: 0, marker: true),
      Dummy(value: 1, marker: true),
      Dummy(value: 1, marker: true),
      Dummy(value: 1, marker: false),
      Dummy(value: 1, marker: true),
    ].groupedRanges { i, element, array in element.marker }

    expect(grouped).to(equal(
      [
        0...2,
        3...3,
        4...4,
      ]
    ))
  }

  func testArrayGroup6() {
    let grouped = [
      Dummy(value: 0, marker: true),
    ].groupedRanges { i, element, array in element.marker }

    expect(grouped).to(equal(
      [
        0...0
      ]
    ))
  }
}
