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

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override init(frame: NSRect) {
    super.init(frame: frame)

    // Because other views also want layer, this view also must want layer. Otherwise the z-index ordering is not set
    // correctly: views w/ wantsLayer = false are behind views w/ wantsLayer = true even when added later.
    self.wantsLayer = true
    self.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
  }

  override func draw(_ dirtyRect: NSRect) {
    let path = NSBezierPath(rect: self.bounds)
    path.lineWidth = 4
    NSColor.selectedControlColor.set()
    path.stroke()
  }
}
