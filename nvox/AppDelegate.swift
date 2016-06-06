/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NeoVimViewDelegate {

  @IBOutlet weak var window: NSWindow!
  
  var neoVim: NeoVim!

  func applicationDidFinishLaunching(aNotification: NSNotification) {
    self.neoVim = NeoVim()
    self.neoVim.view.delegate = self
    self.neoVim.view.setFrameSize(CGSizeMake(100.0, 100.0))
    self.neoVim.view.setFrameOrigin(CGPointMake(0, 0))
    window.contentView?.addSubview(self.neoVim.view)
    
    window.makeFirstResponder(self.neoVim.view)
    
//    neoVim.vimInput("i")
//    neoVim.vimInput("abc")
//    neoVim.vimInput("\u{001B}")
//    neoVim.vimInput("i")
//    neoVim.vimInput("Z")
//    neoVim.vimInput("\u{001B}")
//    neoVim.vimInput("i")
//    for i in 0...9 {
//      neoVim.vimInput("\(i)")
//    }
  }

  func resizeToSize(size: CGSize) {
    self.neoVim.view.setFrameSize(size)
  }
}
