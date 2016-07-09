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
  let view = NeoVimView(forAutoLayout: ())

  @IBAction func debugSomething(sender: AnyObject!) {
//    let font = NSFont(name: "Courier", size: 14)!
//    self.neoVim.view.setFont(font)
  }

  func applicationDidFinishLaunching(aNotification: NSNotification) {
//    let testView = InputTestView(frame: CGRect(x: 0, y: 0, width: 300, height: 300))
//    self.window.contentView?.addSubview(testView)
//    self.window.makeFirstResponder(testView)

    self.window.contentView?.addSubview(self.view)
    self.view.autoPinEdgesToSuperviewEdges()
    self.window.makeFirstResponder(self.view)
  }
  
  func applicationWillTerminate(notification: NSNotification) {
    self.view.cleanUp()
  }

  func setTitle(title: String) {
    self.window.title = title
  }
}
