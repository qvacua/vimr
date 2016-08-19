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
  
  private var quitWhenAllWindowsAreClosed = false
  private var launching = true

  override init() {
    self.actionSink = self.actionSubject.asObservable()
    self.changeSink = self.changeSubject.asObservable()

    self.prefStore = PrefStore(source: self.actionSink)

    self.prefWindowComponent = PrefWindowComponent(source: self.changeSink, initialData: self.prefStore.data)
    self.mainWindowManager = MainWindowManager(source: self.changeSink, initialData: self.prefStore.data)

    super.init()
    
    self.mainWindowManager.sink
      .filter { $0 is MainWindowEvent }
      .map { $0 as! MainWindowEvent }
      .filter { $0 == MainWindowEvent.allWindowsClosed }
      .subscribeNext { [unowned self] mainWindowEvent in
        if self.quitWhenAllWindowsAreClosed {
          NSApp.stop(self)
        }
      }
      .addDisposableTo(self.disposeBag)

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
    
    var actualArguments = Array(Process.arguments[1..<Process.arguments.count])
    actualArguments = actualArguments.reverse()
    
    while let arg = actualArguments.popLast() {
      switch (arg) {
      case "--cwd":
        let cwd = actualArguments.popLast()
        NSFileManager.defaultManager().changeCurrentDirectoryPath(cwd!)
        print("changing folder to \(cwd)")
      default:
        if (arg.characters.first == "-") {
          // unsupported option, skip the rest
          break
        }
      }
    }
  }
}

// MARK: - NSApplicationDelegate
extension AppDelegate {

  func applicationWillFinishLaunching(_: NSNotification) {
    self.launching = true
  }

  func applicationDidFinishLaunching(_: NSNotification) {
//    let testView = InputTestView(frame: CGRect(x: 0, y: 0, width: 300, height: 300))
//    self.window.contentView?.addSubview(testView)
//    self.window.makeFirstResponder(testView)

    self.launching = false

    #if DEBUG
      self.debugMenu.hidden = false
    #endif
  }

  func applicationOpenUntitledFile(sender: NSApplication) -> Bool {
    if self.launching {
      if self.prefStore.data.general.openNewWindowWhenLaunching {
        self.newDocument(self)
        return true
      }
    } else {
      if self.prefStore.data.general.openNewWindowOnReactivation {
        self.newDocument(self)
        return true
      }
    }

    return false
  }

  func applicationShouldTerminate(sender: NSApplication) -> NSApplicationTerminateReply {
    if self.mainWindowManager.hasDirtyWindows() {
      let alert = NSAlert()
      alert.addButtonWithTitle("Cancel")
      alert.addButtonWithTitle("Discard and Quit")
      alert.messageText = "There are windows with unsaved buffers!"
      alert.alertStyle = .WarningAlertStyle

      if alert.runModal() == NSAlertSecondButtonReturn {
        self.mainWindowManager.closeAllWindowsWithoutSaving()
        self.quitWhenAllWindowsAreClosed = true
        return .TerminateCancel
      }

      return .TerminateCancel
    }

    return .TerminateNow
  }
  
  // For drag & dropping files on the App icon.
  func application(sender: NSApplication, openFiles filenames: [String]) {
    let urls = filenames.map { NSURL(fileURLWithPath: $0) }
    self.mainWindowManager.newMainWindow(urls: urls)
    sender.replyToOpenOrPrint(.Success)
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

  // Invoked when no main window is open.
  @IBAction func openDocument(sender: AnyObject!) {
    let panel = NSOpenPanel()
    panel.canChooseDirectories = true
    panel.beginWithCompletionHandler { result in
      guard result == NSFileHandlingPanelOKButton else {
        return
      }

      self.mainWindowManager.newMainWindow(urls: panel.URLs)
    }
  }
}
