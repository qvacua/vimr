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
  
  private weak var mainWindowManager: MainWindowManager?
  
  private let neoVimView = NeoVimView(forAutoLayout: ())

  func setup(manager manager: MainWindowManager) {
    self.mainWindowManager = manager
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
}
