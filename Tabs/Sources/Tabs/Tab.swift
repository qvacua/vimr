/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa

public class Tab: NSView {
  
  public init() {
    super.init(frame: .zero)
    self.configureForAutoLayout()
    self.wantsLayer = true

    #if DEBUG
      self.layer?.backgroundColor = NSColor.cyan.cgColor
    #endif
    
    self.autoSetDimensions(to: CGSize(width: 200, height: Dimensions.tabHeight))
  }

  public override func mouseDown(with event: NSEvent) {
    Swift.print("mouse down in tab")
  }

  public override func mouseUp(with event: NSEvent) {
    Swift.print("mouse up in tab")
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
