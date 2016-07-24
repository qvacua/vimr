/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import RxSwift
import PureLayout

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

  @IBOutlet weak var window: NSWindow!

  private let prefWindowComponent = PrefWindowComponent(source: Observable.empty())
  private let mainWindowManager: MainWindowManager

  @IBAction func debugSomething(sender: AnyObject!) {
    NSLog("debug sth...")
  }
  
  @IBAction func newDocument(sender: AnyObject!) {
    self.mainWindowManager.newMainWindow()
  }

  @IBAction func showPrefWindow(sender: AnyObject!) {
    self.prefWindowComponent.show()
  }

  override init() {
    self.mainWindowManager = MainWindowManager(prefWindowComponent: self.prefWindowComponent)
    super.init()
  }
  
  func applicationDidFinishLaunching(aNotification: NSNotification) {
//    let testView = InputTestView(frame: CGRect(x: 0, y: 0, width: 300, height: 300))
//    self.window.contentView?.addSubview(testView)
//    self.window.makeFirstResponder(testView)

    self.newDocument(self)
  }

  func applicationShouldTerminate(sender: NSApplication) -> NSApplicationTerminateReply {
    if self.mainWindowManager.hasDirtyWindows() {
      let alert = NSAlert()
      alert.addButtonWithTitle("Cancel")
      alert.addButtonWithTitle("Discard and Quit")
      alert.messageText = "There are windows with unsaved buffers!"
      alert.alertStyle = .WarningAlertStyle

      if alert.runModal() == NSAlertSecondButtonReturn {
        return .TerminateNow
      }

      return .TerminateCancel
    }

    return .TerminateNow
  }
}
