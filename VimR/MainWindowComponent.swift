/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import PureLayout
import RxSwift

enum MainWindowAction {
  case becomeKey(mainWindow: MainWindowComponent)
  case openQuickly(mainWindow: MainWindowComponent)
  case close(mainWindow: MainWindowComponent)
}

class MainWindowComponent: WindowComponent, NSWindowDelegate {

  private let fontManager = NSFontManager.sharedFontManager()

  private var defaultEditorFont: NSFont
  private var usesLigatures: Bool

  var uuid: String {
    return self.neoVimView.uuid
  }

  private var _cwd: NSURL = NSURL(fileURLWithPath: NSHomeDirectory(), isDirectory: true)
  var cwd: NSURL {
    get {
      self._cwd = self.neoVimView.cwd
      return self._cwd
    }

    set {
      let oldValue = self._cwd
      if oldValue == newValue {
        return
      }

      self._cwd = newValue
      self.neoVimView.cwd = newValue
      self.fileItemService.unmonitor(url: oldValue)
      self.fileItemService.monitor(url: newValue)
    }
  }
  private let fileItemService: FileItemService

  private let workspace: Workspace
  private let neoVimView: NeoVimView

  // TODO: Consider an option object for cwd, urls, etc...
  init(source: Observable<Any>,
       fileItemService: FileItemService,
       cwd: NSURL,
       urls: [NSURL] = [],
       initialData: PrefData)
  {
    self.neoVimView = NeoVimView(frame: CGRect.zero,
                                 config: NeoVimView.Config(useInteractiveZsh: initialData.advanced.useInteractiveZsh))
    self.neoVimView.translatesAutoresizingMaskIntoConstraints = false

    self.workspace = Workspace(mainView: self.neoVimView)

    self.defaultEditorFont = initialData.appearance.editorFont
    self.usesLigatures = initialData.appearance.editorUsesLigatures
    self.fileItemService = fileItemService
    self._cwd = cwd

    super.init(source: source, nibName: "MainWindow")

    self.window.delegate = self

    self.neoVimView.cwd = cwd
    self.neoVimView.delegate = self
    self.neoVimView.font = self.defaultEditorFont
    self.neoVimView.usesLigatures = self.usesLigatures
    self.neoVimView.open(urls: urls)

    // We don't call self.fileItemService.monitor(url: cwd) here since self.neoVimView.cwd = cwd causes the call
    // cwdChanged() and in that function we do monitor(...).

    self.window.makeFirstResponder(self.neoVimView)
    self.show()
  }

  func open(urls urls: [NSURL]) {
    self.neoVimView.open(urls: urls)
  }

  func isDirty() -> Bool {
    return self.neoVimView.hasDirtyDocs()
  }

  func closeAllNeoVimWindows() {
    self.neoVimView.closeAllWindows()
  }

  func closeAllNeoVimWindowsWithoutSaving() {
    self.neoVimView.closeAllWindowsWithoutSaving()
  }

  override func addViews() {
    self.window.contentView?.addSubview(self.workspace)
    self.workspace.autoPinEdgesToSuperviewEdges()
  }

  override func subscription(source source: Observable<Any>) -> Disposable {
    return source
      .filter { $0 is PrefData }
      .map { ($0 as! PrefData).appearance }
      .filter { [unowned self] appearanceData in
        !appearanceData.editorFont.isEqualTo(self.neoVimView.font)
          || appearanceData.editorUsesLigatures != self.neoVimView.usesLigatures
      }
      .subscribeNext { [unowned self] appearance in
        self.neoVimView.usesLigatures = appearance.editorUsesLigatures
        self.neoVimView.font = appearance.editorFont
    }
  }
}

// MARK: - File Menu Items
extension MainWindowComponent {
  
  @IBAction func newTab(sender: AnyObject!) {
    self.neoVimView.newTab()
  }

  @IBAction func openDocument(sender: AnyObject!) {
    let panel = NSOpenPanel()
    panel.canChooseDirectories = true
    panel.beginSheetModalForWindow(self.window) { result in
      guard result == NSFileHandlingPanelOKButton else {
        return
      }
      
      // The open panel can choose only one file.
      self.neoVimView.open(urls: panel.URLs)
    }
  }

  @IBAction func openQuickly(sender: AnyObject!) {
    self.publish(event: MainWindowAction.openQuickly(mainWindow: self))
  }

  @IBAction func saveDocument(sender: AnyObject!) {
    let curBuf = self.neoVimView.currentBuffer()
    
    if curBuf.fileName == nil {
      self.savePanelSheet { self.neoVimView.saveCurrentTab(url: $0) }
      return
    }
    
    self.neoVimView.saveCurrentTab()
  }
  
  @IBAction func saveDocumentAs(sender: AnyObject!) {
    self.savePanelSheet { url in
      self.neoVimView.saveCurrentTab(url: url)
      
      if self.neoVimView.isCurrentBufferDirty() {
        self.neoVimView.openInNewTab(urls: [url])
      } else {
        self.neoVimView.openInCurrentTab(url: url)
      }
    }
  }
  
  private func savePanelSheet(action action: (NSURL) -> Void) {
    let panel = NSSavePanel()
    panel.beginSheetModalForWindow(self.window) { result in
      guard result == NSFileHandlingPanelOKButton else {
        return
      }
      
      let showAlert: () -> Void = {
        let alert = NSAlert()
        alert.addButtonWithTitle("OK")
        alert.messageText = "Invalid File Name"
        alert.informativeText = "The file name you have entered cannot be used. Please use a different name."
        alert.alertStyle = .WarningAlertStyle
        
        alert.runModal()
      }
      
      guard let url = panel.URL else {
        showAlert()
        return
      }
      
      guard url.path != nil else {
        showAlert()
        return
      }
      
      action(url)
    }
  }
}

// MARK: - Font Menu Items
extension MainWindowComponent {

  @IBAction func resetFontSize(sender: AnyObject!) {
    self.neoVimView.font = self.defaultEditorFont
  }

  @IBAction func makeFontBigger(sender: AnyObject!) {
    let curFont = self.neoVimView.font
    let font = self.fontManager.convertFont(curFont,
                                            toSize: min(curFont.pointSize + 1, PrefStore.maximumEditorFontSize))
    self.neoVimView.font = font
  }

  @IBAction func makeFontSmaller(sender: AnyObject!) {
    let curFont = self.neoVimView.font
    let font = self.fontManager.convertFont(curFont,
                                            toSize: max(curFont.pointSize - 1, PrefStore.minimumEditorFontSize))
    self.neoVimView.font = font
  }
}

// MARK: - NeoVimViewDelegate
extension MainWindowComponent: NeoVimViewDelegate {

  func setTitle(title: String) {
    self.window.title = title
  }

  func setDirtyStatus(dirty: Bool) {
    self.windowController.setDocumentEdited(dirty)
  }

  func cwdChanged() {
    let old = self._cwd
    self._cwd = self.neoVimView.cwd
    self.fileItemService.unmonitor(url: old)
    self.fileItemService.monitor(url: self._cwd)
  }
  
  func neoVimStopped() {
    self.windowController.close()
  }
}

// MARK: - NSWindowDelegate
extension MainWindowComponent {
  
  func windowDidBecomeKey(_: NSNotification) {
    self.publish(event: MainWindowAction.becomeKey(mainWindow: self))
  }

  func windowWillClose(notification: NSNotification) {
    self.fileItemService.unmonitor(url: self._cwd)
    self.publish(event: MainWindowAction.close(mainWindow: self))
  }

  func windowShouldClose(sender: AnyObject) -> Bool {
    if self.neoVimView.isCurrentBufferDirty() {
      let alert = NSAlert()
      alert.addButtonWithTitle("Cancel")
      alert.addButtonWithTitle("Discard and Close")
      alert.messageText = "The current buffer has unsaved changes!"
      alert.alertStyle = .WarningAlertStyle
      alert.beginSheetModalForWindow(self.window) { response in
        if response == NSAlertSecondButtonReturn {
          self.neoVimView.closeCurrentTabWithoutSaving()
        }
      }

      return false
    }

    self.neoVimView.closeCurrentTab()
    return false
  }
}
