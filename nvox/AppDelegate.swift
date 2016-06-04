/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

  @IBOutlet weak var window: NSWindow!
  
  var neoVim: NeoVim = NeoVim()

  func applicationDidFinishLaunching(aNotification: NSNotification) {
    self.neoVim.doSth()
  }

  func applicationWillTerminate(aNotification: NSNotification) {
  }
}

