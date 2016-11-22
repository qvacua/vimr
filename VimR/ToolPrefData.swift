/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

enum ToolIdentifier: String {

  case fileBrowser = "com.qvacua.vimr.tool.file-browser"
  case bufferList = "com.qvacua.vimr.tool.buffer-list"

  static let all = [ fileBrowser, bufferList ]
}

struct ToolPrefData: StandardPrefData {

  fileprivate static let identifier = "identifier"
  fileprivate static let location = "location"
  fileprivate static let isVisible = "is-visible"
  fileprivate static let dimension = "dimension"

  static let defaults: [ToolIdentifier: ToolPrefData] = [
      .fileBrowser: ToolPrefData(identifier: .fileBrowser, location: .left, isVisible: true, dimension: 200),
      .bufferList: ToolPrefData(identifier: .bufferList, location: .left, isVisible: true, dimension: 200),
  ]

  var identifier: ToolIdentifier
  var location: WorkspaceBarLocation
  var isVisible: Bool
  var dimension: CGFloat

  init(identifier: ToolIdentifier, location: WorkspaceBarLocation, isVisible: Bool, dimension: CGFloat) {
    self.identifier = identifier
    self.location = location
    self.isVisible = isVisible
    self.dimension = dimension
  }

  func dict() -> [String: Any] {
    return [
      ToolPrefData.identifier: self.identifier.rawValue,
      ToolPrefData.location: PrefUtils.locationAsString(for: self.location),
      ToolPrefData.isVisible: self.isVisible,
      ToolPrefData.dimension: Float(self.dimension),
    ]
  }

  init?(dict: [String: Any]) {
    guard let identifierRawValue = dict[ToolPrefData.identifier] as? String,
          let locationRawValue = dict[ToolPrefData.location] as? String,
          let isVisible = PrefUtils.bool(from: dict, for: ToolPrefData.isVisible),
          let fDimension = PrefUtils.float(from: dict, for: ToolPrefData.dimension)
        else {
      return nil
    }

    guard let identifier = ToolIdentifier(rawValue: identifierRawValue),
          let location = PrefUtils.location(from: locationRawValue)
        else {
      return nil
    }

    self.init(identifier: identifier, location: location, isVisible: isVisible, dimension: CGFloat(fDimension))
  }
}
