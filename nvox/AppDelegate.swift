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
    self.neoVim.view.setFrameSize(CGSizeMake(100.0, 100.0))
    self.neoVim.view.setFrameOrigin(CGPointMake(0, 0))
    window.contentView?.addSubview(self.neoVim.view)
    window.makeFirstResponder(self.neoVim.view)

//    neoVim.vimInput("i")
//    neoVim.vimInput("\u{1F914}")
//    neoVim.vimInput("\u{1F480}")
//    neoVim.vimInput("č")
//    neoVim.vimInput("하")
//    neoVim.vimInput("a")
//    neoVim.vimInput("z")
//    neoVim.vimInput("\u{001B}")
//    neoVim.vimInput("하12")
//    neoVim.vimInput("r")
//    neoVim.vimInput("泰")
//    neoVim.vimInput("\u{001B}")
//    neoVim.vimInput("Z")
//    neoVim.vimInput("i")
//    for i in 0...9 {
//      neoVim.vimInput("\(i)")
//    }
  }

  func resizeToSize(size: CGSize) {
    self.neoVim.view.setFrameSize(size)
  }
}
