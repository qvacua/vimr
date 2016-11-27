/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import PureLayout

/**
 This class is the base class for inner toolbars for workspace tools. It's got two default buttons:
 - Close button
 - Cog button: not shown when there's no menu
 */
class InnerToolBar: NSView {

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override var intrinsicContentSize: CGSize {
    return CGSize(width: NSViewNoIntrinsicMetrix, height: 24)
  }

  override init(frame: NSRect) {
    super.init(frame: frame)

    // Because other views also want layer, this view also must want layer. Otherwise the z-index ordering is not set
    // correctly: views w/ wantsLayer = false are behind views w/ wantsLayer = true even when added later.
    self.wantsLayer = true
    self.layer?.backgroundColor = NSColor.yellow.cgColor
  }
}

