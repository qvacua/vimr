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