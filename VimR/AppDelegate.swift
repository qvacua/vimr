/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import RxSwift
import PureLayout
import Sparkle

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

  enum Action {

    case newMainWindow(urls: [URL], cwd: URL, nvimArgs: [String]?, cliPipePath: String?)
    case openInKeyWindow(urls: [URL], cwd: URL)

    case preferences
  }

  override init() {
    let baseServerUrl = URL(string: "http://localhost:\(NetUtils.openPort())")!

    var initialAppState: AppState
    if let stateDict = UserDefaults.standard.value(forKey: PrefService.compatibleVersion) as? [String: Any] {
      initialAppState = AppState(dict: stateDict) ?? .default
    } else {
      if let oldDict = UserDefaults.standard.value(forKey: PrefService.lastCompatibleVersion) as? [String: Any] {
        initialAppState = Pref128ToCurrentConverter.appState(from: oldDict)
      } else {
        initialAppState = .default
      }
    }
    initialAppState.mainWindowTemplate.htmlPreview.server = Marked(
      baseServerUrl.appendingPathComponent(HtmlPreviewToolReducer.selectFirstPath)
    )

    self.stateContext = Context(baseServerUrl: baseServerUrl, state: initialAppState)
    self.emit = self.stateContext.actionEmitter.typedEmit()

    self.openNewMainWindowOnLaunch = initialAppState.openNewMainWindowOnLaunch
    self.openNewMainWindowOnReactivation = initialAppState.openNewMainWindowOnReactivation
    self.useSnapshot = initialAppState.useSnapshotUpdate

    let source = self.stateContext.stateSource
    self.uiRoot = UiRoot(source: source, emitter: self.stateContext.actionEmitter, state: initialAppState)

    super.init()

    source
      .observeOn(MainScheduler.instance)
      .subscribe(onNext: { appState in
        self.hasMainWindows = !appState.mainWindows.isEmpty
        self.hasDirtyWindows = appState.mainWindows.values.reduce(false) { $1.isDirty ? true : $0 }

        self.openNewMainWindowOnLaunch = appState.openNewMainWindowOnLaunch
        self.openNewMainWindowOnReactivation = appState.openNewMainWindowOnReactivation

        if self.useSnapshot != appState.useSnapshotUpdate {
          self.useSnapshot = appState.useSnapshotUpdate
          self.setSparkleUrl(self.useSnapshot)
        }
      })
      .disposed(by: self.disposeBag)
  }

  fileprivate let stateContext: Context
  fileprivate let emit: (Action) -> Void

  fileprivate let uiRoot: UiRoot

  fileprivate var hasDirtyWindows = false
  fileprivate var hasMainWindows = false

  fileprivate var openNewMainWindowOnLaunch: Bool
  fileprivate var openNewMainWindowOnReactivation: Bool
  fileprivate var useSnapshot: Bool

  fileprivate let disposeBag = DisposeBag()

  fileprivate var launching = true

  fileprivate func setSparkleUrl(_ snapshot: Bool) {
    if snapshot {
      updater.feedURL = URL(
        string: "https://raw.githubusercontent.com/qvacua/vimr/develop/appcast_snapshot.xml"
      )
    } else {
      updater.feedURL = URL(
        string: "https://raw.githubusercontent.com/qvacua/vimr/master/appcast.xml"
      )
    }
  }
}

// MARK: - NSApplicationDelegate
extension AppDelegate {

  func applicationWillFinishLaunching(_: Notification) {
    self.launching = true

    let appleEventManager = NSAppleEventManager.shared()
    appleEventManager.setEventHandler(self,
                                      andSelector: #selector(AppDelegate.handle(getUrlEvent:replyEvent:)),
                                      forEventClass: UInt32(kInternetEventClass),
                                      andEventID: UInt32(kAEGetURL))
  }

  func applicationDidFinishLaunching(_: Notification) {
    self.launching = false

#if DEBUG
    NSApp.mainMenu?.items.first { $0.identifier == debugMenuItemIdentifier }?.isHidden = false
#endif
  }

  func applicationOpenUntitledFile(_ sender: NSApplication) -> Bool {
    if self.launching {
      if self.openNewMainWindowOnLaunch {
        self.newDocument(self)
        return true
      }
    } else {
      if self.openNewMainWindowOnReactivation {
        self.newDocument(self)
        return true
      }
    }

    return false
  }

  func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
    self.stateContext.savePrefs()

    if self.hasDirtyWindows && self.hasMainWindows {
      let alert = NSAlert()
      alert.addButton(withTitle: "Cancel")
      let discardAndQuitButton = alert.addButton(withTitle: "Discard and Quit")
      alert.messageText = "There are windows with unsaved buffers!"
      alert.alertStyle = .warning
      discardAndQuitButton.keyEquivalentModifierMask = .command
      discardAndQuitButton.keyEquivalent = "d"

      if alert.runModal() == .alertSecondButtonReturn {
        self.uiRoot.prepareQuit()
        return .terminateNow
      }

      return .terminateCancel
    }

    if self.hasMainWindows {
      self.uiRoot.prepareQuit()
      return .terminateNow
    }

    // There are no open main window, then just quit.
    return .terminateNow
  }

  // For drag & dropping files on the App icon.
  func application(_ sender: NSApplication, openFiles filenames: [String]) {
    let urls = filenames.map { URL(fileURLWithPath: $0) }
    self.emit(.newMainWindow(urls: urls, cwd: FileUtils.userHomeUrl, nvimArgs: nil, cliPipePath: nil))

    sender.reply(toOpenOrPrint: .success)
  }
}

// MARK: - AppleScript
extension AppDelegate {

  @objc func handle(getUrlEvent event: NSAppleEventDescriptor, replyEvent: NSAppleEventDescriptor) {
    guard let urlString = event.paramDescriptor(forKeyword: UInt32(keyDirectObject))?.stringValue else {
      return
    }

    guard let url = URL(string: urlString) else {
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

    let rawParams = url.query?.components(separatedBy: "&") ?? []

    guard let pipePath = queryParam(pipePathPrefix, from: rawParams, transforming: identity).first else {
      let alert = NSAlert()
      alert.alertStyle = .informational
      alert.messageText = "Outdated Command Line Tool?"
      alert.informativeText = "It seems that the installed vimr command line tool is outdated." +
                              "Please re-install it from the General Preferences."
      alert.runModal()

      return
    }

    guard FileManager.default.fileExists(atPath: pipePath) else {
      // Use pipePath as a kind of nonce
      return
    }

    let dict = try? FileManager.default.attributesOfItem(atPath: pipePath) as NSDictionary
    guard dict?.filePosixPermissions() == 0o600 else {
      // Use pipePath as a kind of nonce
      return
    }

    let urls = queryParam(filePrefix, from: rawParams, transforming: { URL(fileURLWithPath: $0) })
    let cwd = queryParam(cwdPrefix,
                         from: rawParams,
                         transforming: { URL(fileURLWithPath: $0) }).first ?? FileUtils.userHomeUrl
    let wait = queryParam(waitPrefix, from: rawParams, transforming: { $0 == "true" ? true : false }).first ?? false

    if wait == false {
      _ = Darwin.close(Darwin.open(pipePath, O_WRONLY))
    }

    // If we don't do this, the window is active, but not in front.
    NSApp.activate(ignoringOtherApps: true)

    switch action {

    case .activate, .newWindow:
      self.emit(.newMainWindow(urls: urls, cwd: cwd, nvimArgs: nil, cliPipePath: pipePath))

    case .open:
      self.emit(.openInKeyWindow(urls: urls, cwd: cwd))

    case .separateWindows:
      urls.forEach { self.emit(.newMainWindow(urls: [$0], cwd: cwd, nvimArgs: nil, cliPipePath: pipePath)) }

    case .nvim:
      self.emit(.newMainWindow(urls: [],
                               cwd: cwd,
                               nvimArgs: queryParam(nvimArgsPrefix, from: rawParams, transforming: identity),
                               cliPipePath: pipePath))

    }
  }

  fileprivate func queryParam<T>(_ prefix: String,
                                 from rawParams: [String],
                                 transforming transform: (String) -> T) -> [T] {

    return rawParams
      .filter { $0.hasPrefix(prefix) }
      .flatMap { $0.without(prefix: prefix).removingPercentEncoding }
      .map(transform)
  }
}

// MARK: - IBActions
extension AppDelegate {

  @IBAction func checkForUpdates(_ sender: Any?) {
    updater.checkForUpdates(sender)
  }

  @IBAction func newDocument(_ sender: Any?) {
    self.emit(.newMainWindow(urls: [], cwd: FileUtils.userHomeUrl, nvimArgs: nil, cliPipePath: nil))
  }

  @IBAction func openInNewWindow(_ sender: Any?) {
    self.openDocument(sender)
  }

  @IBAction func showPrefWindow(_ sender: Any?) {
    self.emit(.preferences)
  }

  // Invoked when no main window is open.
  @IBAction func openDocument(_: Any?) {
    let panel = NSOpenPanel()
    panel.canChooseDirectories = true
    panel.allowsMultipleSelection = true
    panel.begin { result in
      guard result == .OK else {
        return
      }

      let urls = panel.urls
      let commonParentUrl = FileUtils.commonParent(of: urls)

      self.emit(.newMainWindow(urls: urls, cwd: commonParentUrl, nvimArgs: nil, cliPipePath: nil))
    }
  }
}

/// Keep the rawValues in sync with Action in the `vimr` Python script.
fileprivate enum VimRUrlAction: String {
  case activate = "activate"
  case open = "open"
  case newWindow = "open-in-new-window"
  case separateWindows = "open-in-separate-windows"
  case nvim = "nvim"
}

fileprivate let updater = SUUpdater()

fileprivate let debugMenuItemIdentifier = NSUserInterfaceItemIdentifier("debug-menu-item")

fileprivate let filePrefix = "file="
fileprivate let cwdPrefix = "cwd="
fileprivate let nvimArgsPrefix = "nvim-args="
fileprivate let pipePathPrefix = "pipe-path="
fileprivate let waitPrefix = "wait="
