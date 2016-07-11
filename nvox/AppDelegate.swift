/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import PureLayout

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

  @IBOutlet weak var window: NSWindow!
  
  private let mainWindowManager = MainWindowManager()
  
  @IBAction func debugSomething(sender: AnyObject!) {
    NSLog("debug sth...")
  }
  
  @IBAction func newDocument(sender: AnyObject!) {
    self.mainWindowManager.newMainWindow()
  }
  
  func applicationDidFinishLaunching(aNotification: NSNotification) {
//    let testView = InputTestView(frame: CGRect(x: 0, y: 0, width: 300, height: 300))
//    self.window.contentView?.addSubview(testView)
//    self.window.makeFirstResponder(testView)

    self.mainWindowManager.newMainWindow()
  }
}
