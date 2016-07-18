/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import PureLayout

class MainWindowController: NSWindowController, NSWindowDelegate, NeoVimViewDelegate {
  
  var uuid: String {
    return self.neoVimView.uuid
  }
  
  private weak var mainWindowManager: MainWindowManager?
  
  private let neoVimView = NeoVimView(forAutoLayout: ())

  func setup(manager manager: MainWindowManager) {
    self.mainWindowManager = manager
    self.neoVimView.delegate = self
    self.addViews()

    self.window?.makeFirstResponder(self.neoVimView)
  }

  // MARK: - NSWindowDelegate
  func windowWillClose(notification: NSNotification) {
    self.mainWindowManager?.closeMainWindow(self)
  }

  func windowShouldClose(sender: AnyObject) -> Bool {
    return !self.neoVimView.hasDirtyDocs()
  }

  // MARK: - NeoVimViewDelegate
  func setNeoVimTitle(title: String) {
    NSLog("\(#function): \(title)")
  }
  
  func neoVimStopped() {
    self.close()
  }

  // MARK: - Private
  private func addViews() {
    self.window?.contentView?.addSubview(self.neoVimView)
    self.neoVimView.autoPinEdgesToSuperviewEdges()
  }
}
