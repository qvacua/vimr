/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import XCTest
import Nimble

class MatcherTest: XCTestCase {

  let target = "UserDefaultContextTest.swift"

  func testExactMatch() {
    expect(Matcher.exactMatchIgnoringCase(self.target, pattern: "uSERdEFAULTcONTEXTtEST.SWIFT"))
      .to(equal(Matcher.ExactMatchResult.exact))
    expect(Matcher.exactMatchIgnoringCase(self.target, pattern: "uSERdEFAULt"))
      .to(equal(Matcher.ExactMatchResult.prefix))
    expect(Matcher.exactMatchIgnoringCase(self.target, pattern: "swIFt")).to(equal(Matcher.ExactMatchResult.suffix))
    expect(Matcher.exactMatchIgnoringCase(self.target, pattern: "userdecon")).to(equal(Matcher.ExactMatchResult.none))
  }
  
  func testUppercaseMatcher() {
    expect(Matcher.numberOfUppercaseMatches("SwiftNeoVimNeoVimView.swift", pattern: "swnvv")).to(equal(4))
    expect(Matcher.numberOfUppercaseMatches(self.target, pattern: "xct")).to(equal(2))
    expect(Matcher.numberOfUppercaseMatches(self.target, pattern: "uct")).to(equal(3))
    expect(Matcher.numberOfUppercaseMatches(self.target, pattern: "uDcT")).to(equal(4))
    expect(Matcher.numberOfUppercaseMatches(self.target, pattern: "dct")).to(equal(3))
    expect(Matcher.numberOfUppercaseMatches(self.target, pattern: "ut")).to(equal(2))
    expect(Matcher.numberOfUppercaseMatches(self.target, pattern: "de")).to(equal(1))
  }
  
  func testFuzzyMatcher() {
    expect(Matcher.fuzzyIgnoringCase(self.target, pattern: "ucotft").matches).to(equal(6))
    expect(Matcher.fuzzyIgnoringCase(self.target, pattern: "uco-tft").matches).to(equal(3))
  }
  
  func testWagerFischerAlgo() {
    expect(Matcher.wagnerFisherDistance("sitting", pattern: "kitten")).to(equal(3))
    expect(Matcher.wagnerFisherDistance("saturday", pattern: "sunday")).to(equal(3))
    expect(Matcher.wagnerFisherDistance("하태원", pattern: "하태이")).to(equal(1))
  }
}
