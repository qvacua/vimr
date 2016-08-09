/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import RxSwift
import PureLayout

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

  @IBOutlet var debugMenu: NSMenuItem!

  private let disposeBag = DisposeBag()

  private let changeSubject = PublishSubject<Any>()
  private let changeSink: Observable<Any>

  private let actionSubject = PublishSubject<Any>()
  private let actionSink: Observable<Any>

  private let prefStore: PrefStore

  private let mainWindowManager: MainWindowManager
  private let prefWindowComponent: PrefWindowComponent

  override init() {
    self.actionSink = self.actionSubject.asObservable()
    self.changeSink = self.changeSubject.asObservable()

    self.prefStore = PrefStore(source: self.actionSink)

    self.prefWindowComponent = PrefWindowComponent(source: self.changeSink, initialData: self.prefStore.data)
    self.mainWindowManager = MainWindowManager(source: self.changeSink, initialData: self.prefStore.data)

    super.init()

    [ self.prefStore ]
      .map { $0.sink }
      .toMergedObservables()
      .subscribe(self.changeSubject)
      .addDisposableTo(self.disposeBag)

    [ self.prefWindowComponent ]
      .map { $0.sink }
      .toMergedObservables()
      .subscribe(self.actionSubject)
      .addDisposableTo(self.disposeBag)
  }

  func applicationDidFinishLaunching(aNotification: NSNotification) {
//    let testView = InputTestView(frame: CGRect(x: 0, y: 0, width: 300, height: 300))
//    self.window.contentView?.addSubview(testView)
//    self.window.makeFirstResponder(testView)

    #if DEBUG
      self.debugMenu.hidden = false
    #endif

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

// MARK: - IBActions
extension AppDelegate {

  @IBAction func showPrefWindow(sender: AnyObject!) {
    self.prefWindowComponent.show()
  }
  
  @IBAction func newDocument(sender: AnyObject!) {
    self.mainWindowManager.newMainWindow()
  }
  
  @IBAction func newTab(sender: AnyObject!) {
  }
  
  @IBAction func openDocument(sender: AnyObject!) {
  }
  
  @IBAction func openInTab(sender: AnyObject!) {
  }
}
