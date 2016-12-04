/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa

protocol WorkspaceToolDelegate: class {

  func toggle(_ tool: WorkspaceTool)
}

class WorkspaceTool: Hashable {

  static func ==(left: WorkspaceTool, right: WorkspaceTool) -> Bool {
    return left.uuid == right.uuid
  }

  // MARK: - API
  var hashValue: Int {
    return self.uuid.hashValue
  }
  /**
   This UUID is only memory-persistent. It's generated when the tool is instantiated.
   */
  let uuid = UUID().uuidString
  let title: String
  let view: NSView
  let button: WorkspaceToolButton
  var location = WorkspaceBarLocation.left {
    didSet {
      self.button.location = self.location
    }
  }

  var isSelected = false {
    didSet {
      if self.isSelected {
        self.button.highlight()
      } else {
        self.button.dehighlight()
      }
    }
  }

  weak var delegate: WorkspaceToolDelegate?
  weak var bar: WorkspaceBar?

  var workspace: Workspace? {
    return self.bar?.workspace
  }

  let minimumDimension: CGFloat
  var dimension: CGFloat

  init(title: String, view: NSView, minimumDimension: CGFloat = 50) {
    self.title = title
    self.view = view
    self.minimumDimension = minimumDimension
    self.dimension = minimumDimension
    self.button = WorkspaceToolButton(title: title)

    self.button.tool = self
  }

  func toggle() {
    self.delegate?.toggle(self)
    self.isSelected = !self.isSelected
  }
}
