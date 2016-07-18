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

  func isDirty() -> Bool {
    return self.neoVimView.hasDirtyDocs()
  }

  // MARK: - NSWindowDelegate
  func windowWillClose(notification: NSNotification) {
    self.mainWindowManager?.closeMainWindow(self)
  }

  func windowShouldClose(sender: AnyObject) -> Bool {
    if !self.isDirty() {
      return true
    }

    let alert = NSAlert()
    alert.addButtonWithTitle("Cancel")
    alert.addButtonWithTitle("Discard and Close")
    alert.messageText = "There are unsaved buffers!"
    alert.alertStyle = .WarningAlertStyle
    alert.beginSheetModalForWindow(self.window!) { response in
      if response == NSAlertSecondButtonReturn {
        self.close()
      }
    }

    return false
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
