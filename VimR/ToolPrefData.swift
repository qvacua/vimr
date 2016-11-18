/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

protocol StandardPrefData {
  
  init?(dict: [String: Any])
  func dict() -> [String: Any]
}

struct ToolPrefData: StandardPrefData {
  
  fileprivate static let identifier = "identifier"
  fileprivate static let isVisible = "isVisible"
  fileprivate static let dimension = "dimension"
  
  let identifier: ToolIdentifier
  let isVisible: Bool
  let dimension: Float
  
  init(identifier: ToolIdentifier, isVisible: Bool, dimension: Float) {
    self.identifier = identifier
    self.isVisible = isVisible
    self.dimension = dimension
  }
  
  func dict() -> [String: Any] {
    return [
      ToolPrefData.identifier: self.identifier,
      ToolPrefData.isVisible: self.isVisible,
      ToolPrefData.dimension: self.dimension,
    ]
  }
  
  init?(dict: [String: Any]) {
    guard let identifier = dict[ToolPrefData.identifier] as? ToolIdentifier,
      let isVisible = dict[ToolPrefData.isVisible] as? Bool,
      let dimension = dict[ToolPrefData.dimension] as? Float
      else {
        return nil
    }
    
    self.init(identifier: identifier, isVisible: isVisible, dimension: dimension)
  }
}
