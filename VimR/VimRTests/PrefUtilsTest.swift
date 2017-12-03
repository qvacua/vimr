/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import XCTest
import Nimble

class PrefUtilsTest: XCTestCase {

  func testIgnorePatternsFromString() {
    expect(PrefUtils.ignorePatterns(fromString: "a, b,c,,d")).to(equal(
      Set(["a", "b", "c", "d"].map(FileItemIgnorePattern.init))
    ))
  }

  func testIgnorePatternsFromEmptyString() {
    expect(PrefUtils.ignorePatterns(fromString: "")).to(equal(Set()))
  }

  func testIgnorePatternsFromEffectivelyEmptyString() {
    expect(PrefUtils.ignorePatterns(fromString: ", ,      ,    ")).to(equal(Set()))
  }

  func testIgnorePatternStringFromSet() {
    let set = Set(["c", "a", "d", "b"].map(FileItemIgnorePattern.init))
    expect(PrefUtils.ignorePatternString(fromSet: set)).to(equal("a, b, c, d"))
  }

  func testIgnorePatternStringFromEmptySet() {
    expect(PrefUtils.ignorePatternString(fromSet: Set())).to(equal(""))
  }
}
