/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NeoVimViewDelegate {

  @IBOutlet weak var window: NSWindow!
  
  var neoVim: NeoVim!

  @IBAction func debugSomething(sender: AnyObject!) {
    self.neoVim.xpc.debugScreenLines()
  }

  func applicationDidFinishLaunching(aNotification: NSNotification) {
    self.neoVim = NeoVim()
    self.neoVim.view.delegate = self

    self.neoVim.view.setFrameSize(CGSize(width: 100.0, height: 100.0))
    self.neoVim.view.setFrameOrigin(CGPoint(x: 0, y: 0))
    self.window.contentView?.addSubview(self.neoVim.view)

    self.window.makeFirstResponder(self.neoVim.view)

//    neoVim.vimInput("i")
//    neoVim.vimInput("\u{1F914}")
//    neoVim.vimInput("\u{1F480}")
//    neoVim.vimInput("č")
//    neoVim.vimInput("하")
//    neoVim.vimInput("a")
//    neoVim.vimInput("泰")
//    neoVim.vimInput("z")
//    neoVim.vimInput("\u{001B}")
  }

  func resizeToSize(size: CGSize) {
    self.neoVim.view.setFrameSize(size)
  }
}
