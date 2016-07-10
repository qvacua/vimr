/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa

class MainWindowManager {
  
  private var mainWindowControllers: [String: MainWindowController] = [:]
  
  func newMainWindow() {
    let mainWindowController = MainWindowController(contentRect: CGRect(x: 100, y: 100, width: 320, height: 240),
                                                    manager: self)
    mainWindowController.showWindow(self)
    
    self.mainWindowControllers[mainWindowController.uuid] = mainWindowController
  }
  
  func closeMainWindow(mainWindowController: MainWindowController) {
    self.mainWindowControllers.removeValueForKey(mainWindowController.uuid)
  }
}
