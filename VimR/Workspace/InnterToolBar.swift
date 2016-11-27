/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import PureLayout
import CocoaFontAwesome

/**
 This class is the base class for inner toolbars for workspace tools. It's got two default buttons:
 - Close button
 - Cog button: not shown when there's no menu
 */
class InnerToolBar: NSView {

  static fileprivate let separatorColor = NSColor.controlShadowColor
  static fileprivate let separatorThickness = CGFloat(1)
  static fileprivate let iconDimension = CGFloat(18)

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  fileprivate let closeButton = NSButton(forAutoLayout:())
  fileprivate let cogButton = NSButton(forAutoLayout:())

  override var intrinsicContentSize: CGSize {
    if #available(macOS 10.11, *) {
      return CGSize(width: NSViewNoIntrinsicMetric, height: 24 + InnerToolBar.separatorThickness)
    } else {
      return CGSize(width: -1, height: 24)
    }
  }

  override init(frame: NSRect) {
    super.init(frame: frame)

    // Because other views also want layer, this view also must want layer. Otherwise the z-index ordering is not set
    // correctly: views w/ wantsLayer = false are behind views w/ wantsLayer = true even when added later.
    self.wantsLayer = true
    self.layer?.backgroundColor = NSColor.yellow.cgColor

    self.addViews()
  }

  override func draw(_ dirtyRect: NSRect) {
    InnerToolBar.separatorColor.set()

    let separatorRect = self.bottomSeparatorRect()
    if dirtyRect.intersects(separatorRect) {
      NSRectFill(separatorRect)
    }
  }

  fileprivate func configureToStandardIconButton(button: NSButton, image: NSImage?) {
    button.image = image
    button.imagePosition = .imageOnly
    button.isBordered = false
    // The following disables the square appearing when pushed.
    (button.cell as? NSButtonCell)?.highlightsBy = .contentsCellMask
  }

  fileprivate func addViews() {
    let close = self.closeButton
    let cog = self.cogButton

    self.configureToStandardIconButton(button: close,
                                       image: NSImage.fontAwesomeIcon(code: "fa-times-circle",
                                                                      textColor: .darkGray,
                                                                      dimension: InnerToolBar.iconDimension))

    self.configureToStandardIconButton(button: cog,
                                       image: NSImage.fontAwesomeIcon(name: .cog,
                                                                      textColor: .darkGray,
                                                                      dimension: InnerToolBar.iconDimension))

    self.addSubview(close)
    self.addSubview(cog)

    close.autoPinEdge(toSuperviewEdge: .top, withInset: 2)
    close.autoPinEdge(toSuperviewEdge: .right, withInset: 2)
    close.autoSetDimension(.width, toSize: InnerToolBar.iconDimension)
    close.autoSetDimension(.height, toSize: InnerToolBar.iconDimension)

    cog.autoPinEdge(toSuperviewEdge: .top, withInset: 2)
    cog.autoPinEdge(.right, to: .left, of: close, withOffset: -2)
    cog.autoSetDimension(.width, toSize: InnerToolBar.iconDimension)
    cog.autoSetDimension(.height, toSize: InnerToolBar.iconDimension)
  }

  fileprivate func bottomSeparatorRect() -> CGRect {
    let bounds = self.bounds
    return CGRect(x: bounds.minX, y: bounds.minY, width: bounds.width, height: InnerToolBar.separatorThickness)
  }
}

