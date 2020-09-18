/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Nimble
import XCTest

class DictionaryCommonsTest: XCTestCase {
  func testMapToDict() {
    let dict = [
      1: "a",
      2: "b",
      3: "c",
    ]
    expect(dict.mapToDict { k, v in (v, "\(k)-\(v)") }).to(equal(
      [
        "a": "1-a",
        "b": "2-b",
        "c": "3-c",
      ]
    ))
  }

  func testFlatMapToDict() {
    let dict = [
      1: "a",
      2: "b",
      3: "c",
    ]
    expect(dict.flatMapToDict { k, v in
      if k == 2 {
        return nil
      }

      return (v, "\(k)-\(v)")
    }).to(equal(
      [
        "a": "1-a",
        "c": "3-c",
      ]
    ))
  }
}
