/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import XCTest
import Nimble
@testable import VimR

fileprivate class DummyToken: Comparable {

  static func ==(left: DummyToken, right: DummyToken) -> Bool {
    return left.value == right.value
  }

  static func <(left: DummyToken, right: DummyToken) -> Bool {
    return left.value < right.value
  }

  let value: String

  init(_ value: String) {
    self.value = value
  }
}

class ArrayCommonsTest: XCTestCase {

  func testCase1() {
    let substitute = [
        DummyToken("a0"),
        DummyToken("a1"),
        DummyToken("a2")
    ]

    let array = [
        DummyToken("b0"),
        DummyToken("b1"),
        DummyToken("a0"),
        DummyToken("a1"),
        DummyToken("b4"),
        DummyToken("a2"),
    ]

    let result = array.substituting(elements: substitute)

    expect(result[2]).to(beIdenticalTo(substitute[0]))
    expect(result[3]).to(beIdenticalTo(substitute[1]))
    expect(result[5]).to(beIdenticalTo(substitute[2]))

    expect(result).to(equal(array))
  }

  func testCase2() {
    let substitute = [
        DummyToken("a0"),
        DummyToken("a1"),
        DummyToken("a2")
    ]

    let array = [
        DummyToken("a0"),
        DummyToken("b0"),
        DummyToken("a1"),
        DummyToken("b1"),
        DummyToken("a2"),
        DummyToken("b4"),
    ]

    let result = array.substituting(elements: substitute)

    expect(result[0]).to(beIdenticalTo(substitute[0]))
    expect(result[2]).to(beIdenticalTo(substitute[1]))
    expect(result[4]).to(beIdenticalTo(substitute[2]))

    expect(result).to(equal(array))
  }

  func testCase3() {
    let substitute = [
        DummyToken("a0"),
        DummyToken("a1"),
        DummyToken("a2")
    ]

    let array = [
        DummyToken("b0"),
        DummyToken("b1"),
        DummyToken("b4"),
        DummyToken("a0"),
        DummyToken("a1"),
        DummyToken("a2"),
    ]

    let result = array.substituting(elements: substitute)

    expect(result[3]).to(beIdenticalTo(substitute[0]))
    expect(result[4]).to(beIdenticalTo(substitute[1]))
    expect(result[5]).to(beIdenticalTo(substitute[2]))

    expect(result).to(equal(array))
  }

  func testCase4() {
    let substitute = [
        DummyToken("a0"),
        DummyToken("a1"),
        DummyToken("a2")
    ]

    let array = [
        DummyToken("a0"),
        DummyToken("a1"),
        DummyToken("a2"),
        DummyToken("b0"),
        DummyToken("b1"),
        DummyToken("b4"),
    ]

    let result = array.substituting(elements: substitute)

    expect(result[0]).to(beIdenticalTo(substitute[0]))
    expect(result[1]).to(beIdenticalTo(substitute[1]))
    expect(result[2]).to(beIdenticalTo(substitute[2]))

    expect(result).to(equal(array))
  }

  func testCase5() {
    let substitute = [
        DummyToken("a0"),
        DummyToken("something else"),
        DummyToken("a1"),
        DummyToken("a2"),
    ]

    let array = [
        DummyToken("a0"),
        DummyToken("b0"),
        DummyToken("a1"),
        DummyToken("b1"),
        DummyToken("a2"),
        DummyToken("b4"),
    ]

    let result = array.substituting(elements: substitute)

    expect(result[0]).to(beIdenticalTo(substitute[0]))
    expect(result[2]).to(beIdenticalTo(substitute[2]))
    expect(result[4]).to(beIdenticalTo(substitute[3]))

    expect(result).to(equal(array))
  }
}
