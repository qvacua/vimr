/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa

public class Tab: NSView {

  public var title: String
  
  public init(withTitle title: String) {
    self.title = title
    self.attributedTitle = NSAttributedString(string: title, attributes: [
      .font: Defs.tabTitleFont
    ])
    super.init(frame: .zero)

    self.configureForAutoLayout()
    self.wantsLayer = true

    #if DEBUG
      self.layer?.backgroundColor = NSColor.cyan.cgColor
    #endif
    
    self.autoSetDimensions(to: CGSize(width: 200, height: Defs.tabHeight))
  }

  public override func mouseDown(with event: NSEvent) {
    Swift.print("mouse down in tab")
  }

  public override func mouseUp(with event: NSEvent) {
    Swift.print("mouse up in tab")
  }

  public override func draw(_ dirtyRect: NSRect) {
    self.attributedTitle.draw(in: self.bounds)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) { fatalError("init(coder:) has not been implemented") }

  private var attributedTitle: NSAttributedString
}
