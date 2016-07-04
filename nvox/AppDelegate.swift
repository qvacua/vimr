/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import PureLayout

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NeoVimViewDelegate {

  @IBOutlet weak var window: NSWindow!
  
  var neoVim: NeoVim!

  @IBAction func debugSomething(sender: AnyObject!) {
    self.neoVim.xpc.resizeToWidth(35, height: 13)
  }

  func applicationDidFinishLaunching(aNotification: NSNotification) {
//    let testView = InputTestView(frame: CGRect(x: 0, y: 0, width: 300, height: 300))
//    self.window.contentView?.addSubview(testView)
//    self.window.makeFirstResponder(testView)

    self.neoVim = NeoVim()
    self.neoVim.view.delegate = self

    let view = self.neoVim.view
    view.translatesAutoresizingMaskIntoConstraints = false
    self.window.contentView?.addSubview(self.neoVim.view)
    view.autoPinEdgesToSuperviewEdges()

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
//    let delta = CGFloat(4 + 4)
//    let bigger = CGSize(width: size.width + delta, height: size.height + delta)
//    self.neoVim.view.setFrameSize(bigger)
//    NSLog("\(#function)")
  }
  
  func setTitle(title: String) {
    self.window.title = title
  }
}
