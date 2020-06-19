/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

final class CellAttributesCollection {

  static let defaultAttributesId = 0
  static let reversedDefaultAttributesId = Int.max

  private(set) var defaultAttributes = CellAttributes(
    fontTrait: [],
    foreground: 0,
    background: 0xFFFFFF,
    special: 0xFF0000,
    reverse: false
  )

  init() { self.attributes[CellAttributesCollection.defaultAttributesId] = self.defaultAttributes }

  func attributes(of id: Int) -> CellAttributes? {
    return self.attributes(of: id, withDefaults: self.defaultAttributes)
  }

  func attributes(of id: Int, withDefaults defaults: CellAttributes) -> CellAttributes? {
    if id == Int.max { return self.defaultAttributes.reversed }

    let absId = abs(id)
    guard let attrs = self.attributes[absId] else { return nil }
    if id < 0 { return attrs.replacingDefaults(with: self.defaultAttributes).reversed }

    return attrs.replacingDefaults(with: defaults)
  }

  func set(attributes: CellAttributes, for id: Int) {
    self.attributes[id] = attributes
    if id == CellAttributesCollection.defaultAttributesId { self.defaultAttributes = attributes }
  }

  private var attributes: [Int: CellAttributes] = [:]
}
