/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa

class WorkspaceToolButton: NSView {
  
  static fileprivate let titlePadding = CGSize(width: 8, height: 2)

  fileprivate let title: NSAttributedString
  fileprivate var trackingArea = NSTrackingArea()
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - API
  var location = WorkspaceBarLocation.left
  var isSelected: Bool {
    return self.tool?.isSelected ?? false
  }

  weak var tool: WorkspaceTool?

  init(title: String) {
    self.title = NSAttributedString(string: title, attributes: [
      NSFontAttributeName: NSFont.systemFont(ofSize: 11)
    ])

    super.init(frame: CGRect.zero)
    self.translatesAutoresizingMaskIntoConstraints = false

    self.wantsLayer = true
  }

  func highlight() {
    self.layer?.backgroundColor = NSColor.controlShadowColor.cgColor
  }

  func dehighlight() {
    self.layer?.backgroundColor = NSColor.clear.cgColor
  }
}

// MARK: - NSView
extension WorkspaceToolButton {

  override var intrinsicContentSize: NSSize {
    let titleSize = self.title.size()
    
    let padding = WorkspaceToolButton.titlePadding
    switch self.location {
    case .top, .bottom:
      return CGSize(width: titleSize.width + 2 * padding.width, height: titleSize.height + 2 * padding.height)
    case .right, .left:
      return CGSize(width: titleSize.height + 2 * padding.height, height: titleSize.width + 2 * padding.width)
    }
  }

  override func draw(_ dirtyRect: NSRect) {
    super.draw(dirtyRect)
    
    let padding = WorkspaceToolButton.titlePadding
    switch self.location {
    case .top, .bottom:
      self.title.draw(at: CGPoint(x: padding.width, y: padding.height))
    case .right:
      self.title.draw(at: CGPoint(x: padding.height, y: self.bounds.height - padding.width), angle: -CGFloat(M_PI_2))
    case .left:
      self.title.draw(at: CGPoint(x: self.bounds.width - padding.height, y: padding.width), angle: CGFloat(M_PI_2))
    }
  }

  override func updateTrackingAreas() {
    self.removeTrackingArea(self.trackingArea)

    self.trackingArea = NSTrackingArea(rect: self.bounds,
                                       options: [.mouseEnteredAndExited, .activeInActiveApp],
                                       owner: self,
                                       userInfo: nil)
    self.addTrackingArea(self.trackingArea)

    super.updateTrackingAreas()
  }

  override func mouseDown(with event: NSEvent) {
    self.tool?.toggle()
  }

  override func mouseEntered(with _: NSEvent) {
    if self.isSelected {
      return
    }

    self.highlight()
  }

  override func mouseExited(with _: NSEvent) {
    if self.isSelected {
      return
    }

    self.dehighlight()
  }
}
