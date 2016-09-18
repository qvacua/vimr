/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa

class WorkspaceToolButton: NSView {
  
  static private let titlePadding = CGSize(width: 8, height: 2)

  var location = WorkspaceBarLocation.left
  var isSelected: Bool {
    return self.tool?.isSelected ?? false
  }

  weak var tool: WorkspaceTool?

  override var fittingSize: NSSize {
    return self.intrinsicContentSize
  }

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

  private let title: NSAttributedString
  private var trackingArea = NSTrackingArea()

  init(title: String) {
    self.title = NSAttributedString(string: title, attributes: [
      NSFontAttributeName: NSFont.systemFontOfSize(11)
    ])

    super.init(frame: CGRect.zero)
    self.translatesAutoresizingMaskIntoConstraints = false

    self.wantsLayer = true
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func drawRect(dirtyRect: NSRect) {
    super.drawRect(dirtyRect)
    
    let padding = WorkspaceToolButton.titlePadding
    switch self.location {
    case .top, .bottom:
      self.title.drawAtPoint(CGPoint(x: padding.width, y: padding.height))
    case .right:
      self.title.draw(at: CGPoint(x: padding.height, y: self.bounds.height - padding.width), angle: -CGFloat(M_PI_2))
    case .left:
      self.title.draw(at: CGPoint(x: self.bounds.width - padding.height, y: padding.width), angle: CGFloat(M_PI_2))
    }
  }

  override func updateTrackingAreas() {
    self.removeTrackingArea(self.trackingArea)

    self.trackingArea = NSTrackingArea(rect: self.bounds,
                                       options: [.MouseEnteredAndExited, .ActiveInActiveApp],
                                       owner: self,
                                       userInfo: nil)
    self.addTrackingArea(self.trackingArea)

    super.updateTrackingAreas()
  }

  override func mouseDown(event: NSEvent) {
    self.tool?.toggle()
  }

  override func mouseEntered(_: NSEvent) {
    if self.isSelected {
      return
    }

    self.highlight()
  }

  override func mouseExited(_: NSEvent) {
    if self.isSelected {
      return
    }

    self.dehighlight()
  }

  func highlight() {
    self.layer?.backgroundColor = NSColor.controlShadowColor().CGColor
  }

  func dehighlight() {
    self.layer?.backgroundColor = NSColor.clearColor().CGColor
  }
}
