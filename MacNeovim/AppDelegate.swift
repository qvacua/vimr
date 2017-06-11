/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NeoVimWindowDelegate {

  fileprivate var neoVimWindows = Set<NeoVimWindow>()
}

// MARK: - NSApplicationDelegate
extension AppDelegate {

  func applicationOpenUntitledFile(_ sender: NSApplication) -> Bool {
    self.newDocument(self)
    return true
  }

  func applicationShouldTerminate(_ sender: NSApplication) -> NSApplicationTerminateReply {
    if self.neoVimWindows.isEmpty {
      return .terminateNow
    }

    let isDirty = self.neoVimWindows.reduce(false) { $0 ? true : $1.window.isDocumentEdited }
    guard isDirty else {
      self.neoVimWindows.forEach { $0.closeNeoVimWithoutSaving() }
      return .terminateNow
    }

    let alert = NSAlert()
    alert.addButton(withTitle: "Cancel")
    alert.addButton(withTitle: "Discard and Quit")
    alert.messageText = "There are windows with unsaved buffers!"
    alert.alertStyle = .warning

    if alert.runModal() == NSAlertSecondButtonReturn {
      self.neoVimWindows.forEach { $0.closeNeoVimWithoutSaving() }
      return .terminateNow
    }

    return .terminateCancel
  }
}

// MARK: - NeoVimWindow.Delegate
extension AppDelegate {

  func neoVimWindowDidClose(neoVimWindow: NeoVimWindow) {
    self.neoVimWindows.remove(neoVimWindow)
  }
}

// MARK: - IBActions
extension AppDelegate {

  @IBAction func newDocument(_: Any?) {
    let neoVimWindow = NeoVimWindow(delegate: self)
    self.neoVimWindows.insert(neoVimWindow)

    neoVimWindow.window.makeKeyAndOrderFront(self)
  }
}