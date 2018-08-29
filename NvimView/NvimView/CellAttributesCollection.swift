/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

class CellAttributesCollection {

  static let defaultAttributesId = 0

  private(set) var defaultAttributes = CellAttributes(
    fontTrait: [],
    foreground: 0,
    background: 0xFFFFFF,
    special: 0xFF0000,
    reverse: false
  )

  init() {
    self.attributes[CellAttributesCollection.defaultAttributesId]
      = self.defaultAttributes
  }

  func attributes(of id: Int) -> CellAttributes? {
    guard let attrs = self.attributes[id] else {
      return nil
    }

    return attrs.replacingDefaults(with: self.defaultAttributes)
  }

  func set(attributes: CellAttributes, for id: Int) {
    self.attributes[id] = attributes

    if id == CellAttributesCollection.defaultAttributesId {
      self.defaultAttributes = attributes
    }
  }

  private var attributes: [Int: CellAttributes] = [:]
}
