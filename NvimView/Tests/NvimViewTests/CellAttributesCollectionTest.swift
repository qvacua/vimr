/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import Nimble
import XCTest

@testable import NvimView

class CellAttributesCollectionTest: XCTestCase {
  func testSetDefaultAttributes() {
    let attrs = CellAttributes(
      fontTrait: [], foreground: 1, background: 2, special: 3, reverse: true
    )
    self.cellAttributesCollection.set(attributes: attrs, for: 0)
    expect(self.cellAttributesCollection.defaultAttributes)
      .to(equal(attrs))
  }

  func testSetAndGetAttributes() {
    let attrs = CellAttributes(
      fontTrait: [], foreground: 1, background: 2, special: 3, reverse: true
    )
    self.cellAttributesCollection.set(attributes: attrs, for: 1)
    expect(self.cellAttributesCollection.attributes(of: 1))
      .to(equal(attrs))
  }

  func testSetAndGetAttributesWithDefaults() {
    let defaultAttrs = CellAttributes(
      fontTrait: [], foreground: 10, background: 20, special: 30, reverse: true
    )
    self.cellAttributesCollection
      .set(attributes: defaultAttrs, for: CellAttributesCollection.defaultAttributesId)

    var attrs = CellAttributes(
      fontTrait: [], foreground: -1, background: 2, special: 3, reverse: true
    )
    self.cellAttributesCollection.set(attributes: attrs, for: 1)
    expect(self.cellAttributesCollection.attributes(of: 1))
      .to(equal(CellAttributes(
        fontTrait: [], foreground: 20, background: 2, special: 3, reverse: true
      )))

    attrs = CellAttributes(
      fontTrait: [], foreground: 1, background: -1, special: 3, reverse: true
    )
    self.cellAttributesCollection.set(attributes: attrs, for: 1)
    expect(self.cellAttributesCollection.attributes(of: 1))
      .to(equal(CellAttributes(
        fontTrait: [], foreground: 1, background: 10, special: 3, reverse: true
      )))

    attrs = CellAttributes(
      fontTrait: [], foreground: 1, background: -1, special: -1, reverse: true
    )
    self.cellAttributesCollection.set(attributes: attrs, for: 1)
    expect(self.cellAttributesCollection.attributes(of: 1))
      .to(equal(CellAttributes(
        fontTrait: [], foreground: 1, background: 10, special: 30, reverse: true
      )))
  }

  private let cellAttributesCollection = CellAttributesCollection()
}
