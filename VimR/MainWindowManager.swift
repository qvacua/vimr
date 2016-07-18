/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa

class MainWindowManager {
  
  private var mainWindowControllers: [String: MainWindowController] = [:]
  
  func newMainWindow() {
    let mainWindowController = MainWindowController(windowNibName: "MainWindow")
    self.mainWindowControllers[mainWindowController.uuid] = mainWindowController

    mainWindowController.setup(manager: self)
    mainWindowController.showWindow(self)
  }
  
  func closeMainWindow(mainWindowController: MainWindowController) {
    self.mainWindowControllers.removeValueForKey(mainWindowController.uuid)
  }

  func hasDirtyWindows() -> Bool {
    for windowController in self.mainWindowControllers.values {
      if windowController.isDirty() {
        return true
      }
    }

    return false
  }
}
