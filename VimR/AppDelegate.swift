/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import RxSwift
import PureLayout

private let filePrefix = "file="
private let cwdPrefix = "cwd="

/// Keep the rawValues in sync with Action in the `vimr` Python script.
private enum VimRUrlAction: String {
  case activate = "activate"
  case open = "open"
  case newWindow = "open-in-new-window"
  case separateWindows = "open-in-separate-windows"
}

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
  private let openQuicklyWindowManager: OpenQuicklyWindowManager
  private let prefWindowComponent: PrefWindowComponent

  private let fileItemService = FileItemService()
  
  private var quitWhenAllWindowsAreClosed = false
  private var launching = true

  override init() {
    self.actionSink = self.actionSubject.asObservable()
    self.changeSink = self.changeSubject.asObservable()

    self.prefStore = PrefStore(source: self.actionSink)

    self.fileItemService.set(ignorePatterns: Set([ "*/.git", "*.o", "*.d", "*.dia" ].map(FileItemIgnorePattern.init)))

    self.prefWindowComponent = PrefWindowComponent(source: self.changeSink, initialData: self.prefStore.data)
    self.mainWindowManager = MainWindowManager(source: self.changeSink,
                                               fileItemService: self.fileItemService,
                                               initialData: self.prefStore.data)
    self.openQuicklyWindowManager = OpenQuicklyWindowManager(source: self.changeSink,
                                                             fileItemService: self.fileItemService)

    super.init()

    self.mainWindowManager.sink
      .filter { $0 is MainWindowEvent || $0 is MainWindowAction }
      .subscribeNext { [unowned self] event in
        switch event {
        case let MainWindowAction.openQuickly(mainWindow: mainWindow):
          self.openQuicklyWindowManager.open(forMainWindow: mainWindow)
        case MainWindowEvent.allWindowsClosed:
          if self.quitWhenAllWindowsAreClosed {
            NSApp.stop(self)
          }
        default:
          return
        }
      }.addDisposableTo(self.disposeBag)

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
}

// MARK: - NSApplicationDelegate
extension AppDelegate {

  func applicationWillFinishLaunching(_: NSNotification) {
    self.launching = true
    
    let appleEventManager = NSAppleEventManager.sharedAppleEventManager()
    appleEventManager.setEventHandler(self,
                                      andSelector: #selector(AppDelegate.handleGetUrlEvent(_:withReplyEvent:)),
                                      forEventClass: UInt32(kInternetEventClass),
                                      andEventID: UInt32(kAEGetURL))
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
        self.quitWhenAllWindowsAreClosed = true
        self.mainWindowManager.closeAllWindowsWithoutSaving()
      }

      return .TerminateCancel
    }

    if self.mainWindowManager.hasMainWindow() {
      self.quitWhenAllWindowsAreClosed = true
      self.mainWindowManager.closeAllWindows()

      return .TerminateCancel
    }

    // There are no open main window, then just quit.
    return .TerminateNow
  }
  
  // For drag & dropping files on the App icon.
  func application(sender: NSApplication, openFiles filenames: [String]) {
    let urls = filenames.map { NSURL(fileURLWithPath: $0) }
    self.mainWindowManager.newMainWindow(urls: urls)
    sender.replyToOpenOrPrint(.Success)
  }
}

// MARK: - AppleScript
extension AppDelegate {
  
  func handleGetUrlEvent(event: NSAppleEventDescriptor, withReplyEvent: NSAppleEventDescriptor) {
    guard let urlString = event.paramDescriptorForKeyword(UInt32(keyDirectObject))?.stringValue else {
      return
    }
    
    guard let url = NSURL(string: urlString) else {
      return
    }
    
    guard url.scheme == "vimr" else {
      return
    }
    
    guard let rawAction = url.host else {
      return
    }
    
    guard let action = VimRUrlAction(rawValue: rawAction) else {
      return
    }
    
    let queryParams = url.query?.componentsSeparatedByString("&")
    let urls = queryParams?
      .filter { $0.hasPrefix(filePrefix) }
      .flatMap { $0.without(prefix: filePrefix).stringByRemovingPercentEncoding }
      .map { NSURL(fileURLWithPath: $0) } ?? []
    let cwd = queryParams?
      .filter { $0.hasPrefix(cwdPrefix) }
      .flatMap { $0.without(prefix: cwdPrefix).stringByRemovingPercentEncoding }
      .map { NSURL(fileURLWithPath: $0) }
      .first ?? NSURL(fileURLWithPath: NSHomeDirectory(), isDirectory: true)
    
    switch action {
    case .activate, .newWindow:
      self.mainWindowManager.newMainWindow(urls: urls, cwd: cwd)
      return
    case .open:
      self.mainWindowManager.openInKeyMainWindow(urls: urls, cwd: cwd)
      return
    case .separateWindows:
      urls.forEach { self.mainWindowManager.newMainWindow(urls: [$0], cwd: cwd) }
      return
    }
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
