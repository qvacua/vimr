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
  case changeCwd(mainWindow: MainWindowComponent)
  case close(mainWindow: MainWindowComponent)
}

fileprivate enum Tool {

  case fileBrowser
}

class MainWindowComponent: WindowComponent, NSWindowDelegate, WorkspaceDelegate {

  fileprivate static let nibName = "MainWindow"

  fileprivate var defaultEditorFont: NSFont
  fileprivate var usesLigatures: Bool

  fileprivate var _cwd: URL = URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true)

  fileprivate let fontManager = NSFontManager.shared()
  fileprivate let fileItemService: FileItemService

  fileprivate let workspace: Workspace
  fileprivate let neoVimView: NeoVimView
  fileprivate var tools = [Tool: WorkspaceTool]()

  // MARK: - API
  var uuid: String {
    return self.neoVimView.uuid
  }

  var cwd: URL {
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

  // TODO: Consider an option object for cwd, urls, etc...
  init(source: Observable<Any>,
       fileItemService: FileItemService,
       cwd: URL,
       urls: [URL] = [],
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

    super.init(source: source, nibName: MainWindowComponent.nibName)

    self.window.delegate = self
    self.workspace.delegate = self

    let fileBrowser = FileBrowserComponent(source: self.sink, fileItemService: fileItemService)
    let fileBrowserTool = WorkspaceTool(title: "Files", view: fileBrowser)
    self.tools[.fileBrowser] = fileBrowserTool
    self.workspace.append(tool: fileBrowserTool, location: .left)

    // FIXME: temporarily for dev
    fileBrowserTool.dimension = 200
    self.workspace.bars[.left]?.toggle(fileBrowserTool)

    self.neoVimView.cwd = cwd // This will publish the MainWindowAction.changeCwd action for the file browser.
    self.neoVimView.delegate = self
    self.neoVimView.font = self.defaultEditorFont
    self.neoVimView.usesLigatures = self.usesLigatures
    self.neoVimView.open(urls: urls)

    // We don't call self.fileItemService.monitor(url: cwd) here since self.neoVimView.cwd = cwd causes the call
    // cwdChanged() and in that function we do monitor(...).

    self.window.makeFirstResponder(self.neoVimView)
    self.show()
  }

  func open(urls: [URL]) {
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

  // MARK: - WindowComponent
  override func addViews() {
    self.window.contentView?.addSubview(self.workspace)
    self.workspace.autoPinEdgesToSuperviewEdges()
  }

  override func subscription(source: Observable<Any>) -> Disposable {
    return source
      .filter { $0 is PrefData }
      .map { ($0 as! PrefData).appearance }
      .filter { [unowned self] appearanceData in
        !appearanceData.editorFont.isEqual(to: self.neoVimView.font)
          || appearanceData.editorUsesLigatures != self.neoVimView.usesLigatures
      }
      .subscribe(onNext: { [unowned self] appearance in
        self.neoVimView.usesLigatures = appearance.editorUsesLigatures
        self.neoVimView.font = appearance.editorFont
    })
  }
}

// MARK: - WorkspaceDelegate
extension MainWindowComponent {

  func resizeWillStart(workspace: Workspace) {
    self.neoVimView.enterResizeMode()
  }

  func resizeDidEnd(workspace: Workspace) {
    self.neoVimView.exitResizeMode()
  }
}

// MARK: - File Menu Items
extension MainWindowComponent {
  
  @IBAction func newTab(_ sender: Any?) {
    self.neoVimView.newTab()
  }

  @IBAction func openDocument(_ sender: Any?) {
    let panel = NSOpenPanel()
    panel.canChooseDirectories = true
    panel.beginSheetModal(for: self.window) { result in
      guard result == NSFileHandlingPanelOKButton else {
        return
      }
      
      // The open panel can choose only one file.
      self.neoVimView.open(urls: panel.urls)
    }
  }

  @IBAction func openQuickly(_ sender: Any?) {
    self.publish(event: MainWindowAction.openQuickly(mainWindow: self))
  }

  @IBAction func saveDocument(_ sender: Any?) {
    let curBuf = self.neoVimView.currentBuffer()
    
    if curBuf.fileName == nil {
      self.savePanelSheet { self.neoVimView.saveCurrentTab(url: $0) }
      return
    }
    
    self.neoVimView.saveCurrentTab()
  }
  
  @IBAction func saveDocumentAs(_ sender: Any?) {
    self.savePanelSheet { url in
      self.neoVimView.saveCurrentTab(url: url)
      
      if self.neoVimView.isCurrentBufferDirty() {
        self.neoVimView.openInNewTab(urls: [url])
      } else {
        self.neoVimView.openInCurrentTab(url: url)
      }
    }
  }
  
  fileprivate func savePanelSheet(action: @escaping (URL) -> Void) {
    let panel = NSSavePanel()
    panel.beginSheetModal(for: self.window) { result in
      guard result == NSFileHandlingPanelOKButton else {
        return
      }
      
      let showAlert: () -> Void = {
        let alert = NSAlert()
        alert.addButton(withTitle: "OK")
        alert.messageText = "Invalid File Name"
        alert.informativeText = "The file name you have entered cannot be used. Please use a different name."
        alert.alertStyle = .warning
        
        alert.runModal()
      }
      
      guard let url = panel.url else {
        showAlert()
        return
      }
      
      action(url)
    }
  }
}

// MARK: - Font Menu Items
extension MainWindowComponent {

  @IBAction func resetFontSize(_ sender: Any?) {
    self.neoVimView.font = self.defaultEditorFont
  }

  @IBAction func makeFontBigger(_ sender: Any?) {
    let curFont = self.neoVimView.font
    let font = self.fontManager.convert(curFont,
                                            toSize: min(curFont.pointSize + 1, PrefStore.maximumEditorFontSize))
    self.neoVimView.font = font
  }

  @IBAction func makeFontSmaller(_ sender: Any?) {
    let curFont = self.neoVimView.font
    let font = self.fontManager.convert(curFont,
                                            toSize: max(curFont.pointSize - 1, PrefStore.minimumEditorFontSize))
    self.neoVimView.font = font
  }
}

// MARK: - NeoVimViewDelegate
extension MainWindowComponent: NeoVimViewDelegate {

  func set(title: String) {
    self.window.title = title
  }

  func set(dirtyStatus: Bool) {
    self.windowController.setDocumentEdited(dirtyStatus)
  }

  func cwdChanged() {
    let old = self._cwd
    self._cwd = self.neoVimView.cwd
    self.fileItemService.unmonitor(url: old)
    self.fileItemService.monitor(url: self._cwd)

    self.publish(event: MainWindowAction.changeCwd(mainWindow: self))
  }
  
  func neoVimStopped() {
    self.windowController.close()
  }
}

// MARK: - NSWindowDelegate
extension MainWindowComponent {
  
  func windowDidBecomeKey(_: Notification) {
    self.publish(event: MainWindowAction.becomeKey(mainWindow: self))
  }

  func windowWillClose(_ notification: Notification) {
    self.fileItemService.unmonitor(url: self._cwd)
    self.publish(event: MainWindowAction.close(mainWindow: self))
  }

  func windowShouldClose(_ sender: Any) -> Bool {
    if self.neoVimView.isCurrentBufferDirty() {
      let alert = NSAlert()
      alert.addButton(withTitle: "Cancel")
      alert.addButton(withTitle: "Discard and Close")
      alert.messageText = "The current buffer has unsaved changes!"
      alert.alertStyle = .warning
      alert.beginSheetModal(for: self.window, completionHandler: { response in
        if response == NSAlertSecondButtonReturn {
          self.neoVimView.closeCurrentTabWithoutSaving()
        }
      }) 

      return false
    }

    self.neoVimView.closeCurrentTab()
    return false
  }
}
