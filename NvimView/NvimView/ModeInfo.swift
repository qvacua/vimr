/**
 * Johann Rudloff - @cypheon
 * See LICENSE
 */

import MessagePack

public enum CursorShape : Equatable {
  case Block
  case Horizontal(cellPercentage: Int)
  case Vertical(cellPercentage: Int)

  static func of(shape: String, cellPercentage: Int?) -> CursorShape? {
    switch shape {
    case "block":
      return Block
    case "horizontal":
      return cellPercentage.map(Horizontal(cellPercentage:))
    case "vertical":
      return cellPercentage.map(Vertical(cellPercentage:))
    default:
      return nil
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
    attrId = dict["attr_id"]?.intValue
    if let shapeName = dict["cursor_shape"]?.stringValue,
      let cursorShape = CursorShape.of(shape: shapeName, cellPercentage: dict["cell_percentage"]?.intValue) {
      self.cursorShape = cursorShape
    } else {
      self.cursorShape = .Block
    }
    shortName = dict["short_name"]?.stringValue ?? "?"
    name = dict["name"]?.stringValue ?? (dict["short_name"]?.stringValue ?? "???")
  }

  public var description: String {
    return "ModeInfo<\(name) (\(shortName)) shape: \(cursorShape) attr_id:\(attrId)>"
  }
}
