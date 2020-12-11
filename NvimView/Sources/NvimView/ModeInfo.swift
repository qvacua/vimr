/**
 * Johann Rudloff - @cypheon
 * See LICENSE
 */

import MessagePack

public enum CursorShape: Equatable {
  case block
  case horizontal(cellPercentage: Int)
  case vertical(cellPercentage: Int)

  static func of(shape: String, cellPercentage: Int?) -> CursorShape? {
    switch shape {
    case "block": return block
    case "horizontal": return cellPercentage.map(horizontal(cellPercentage:))
    case "vertical": return cellPercentage.map(vertical(cellPercentage:))
    default: return nil
    }
  }
}

public struct ModeInfo: CustomStringConvertible {
  public let attrId: Int?
  public let cursorShape: CursorShape
  public let shortName: String
  public let name: String

  public init(
    withMsgPackDict dict: MessagePackValue
  ) {
    self.attrId = dict["attr_id"]?.intValue
    if let shapeName = dict["cursor_shape"]?.stringValue,
       let cursorShape = CursorShape.of(
         shape: shapeName,
         cellPercentage: dict["cell_percentage"]?.intValue
       )
    {
      self.cursorShape = cursorShape
    } else {
      self.cursorShape = .block
    }
    self.shortName = dict["short_name"]?.stringValue ?? "?"
    self.name = dict["name"]?.stringValue ?? (dict["short_name"]?.stringValue ?? "???")
  }

  public var description: String {
    "ModeInfo<\(self.name) (\(self.shortName)) shape: \(self.cursorShape)" +
      "attr_id:\(String(describing: self.attrId))>"
  }
}
