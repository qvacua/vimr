/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import PureLayout

class MainWindowController: NSWindowController, NSWindowDelegate {
  
  var uuid: String {
    return self.neoVimView.uuid
  }
  
  weak var mainWindowManager: MainWindowManager?
  
  private let neoVimView = NeoVimView(forAutoLayout: ())

  init(contentRect: CGRect, manager: MainWindowManager) {
    self.mainWindowManager = manager
    
    let style = NSTitledWindowMask | NSUnifiedTitleAndToolbarWindowMask | NSTexturedBackgroundWindowMask |
                NSClosableWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask
    let window = NSWindow(contentRect: contentRect, styleMask: style, backing: .Buffered, defer: true)
    
    super.init(window: window)
    
    window.delegate = self
    window.hasShadow = true
    window.title = "nvox"
    window.opaque = false
    window.animationBehavior = .DocumentWindow
    
    self.addViews()
    
    self.window?.makeFirstResponder(self.neoVimView)
  }
  
  func windowWillClose(notification: NSNotification) {
    self.neoVimView.cleanUp()
    self.mainWindowManager?.closeMainWindow(self)
  }
  
  private func addViews() {
    self.window?.contentView?.addSubview(self.neoVimView)
    self.neoVimView.autoPinEdgesToSuperviewEdges()
  }
 
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
