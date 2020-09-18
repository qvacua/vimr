/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Nimble
import XCTest

class StringCommonsTest: XCTestCase {
  func testWithoutPrefix() {
    expect("prefixAbc".without(prefix: "prefix")).to(equal("Abc"))
    expect("prefix".without(prefix: "prefix")).to(equal(""))
    expect("Abcprefix".without(prefix: "prefix")).to(equal("Abcprefix"))
  }
}
