/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import PureLayout

/**
 This class is used to display the placeholder bar when a tool is drag & dropped to a location with no existing tools.
 */
class ProxyWorkspaceBar: NSView {
  var theme = Workspace.Theme.default

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override init(frame: NSRect) {
    super.init(frame: frame)

    // Because other views also want layer, this view also must want layer. Otherwise the z-index ordering is not set
    // correctly: views w/ wantsLayer = false are behind views w/ wantsLayer = true even when added later.
    self.wantsLayer = true
    self.layer?.backgroundColor = self.theme.background.cgColor
  }

  func repaint() {
    self.layer?.backgroundColor = self.theme.background.cgColor
    self.needsDisplay = true
  }

  override func draw(_: NSRect) {
    let path = NSBezierPath(rect: self.bounds)
    path.lineWidth = 4
    self.theme.barFocusRing.set()
    path.stroke()
  }
}
