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
  case close(mainWindow: MainWindowComponent, mainWindowPrefData: MainWindowPrefData)
}

struct MainWindowPrefData {

  let isAllToolsVisible: Bool
  let isToolButtonsVisible: Bool

  let isFileBrowserVisible: Bool
  let fileBrowserWidth: Float
}

fileprivate enum Tool {

  case fileBrowser
}

class MainWindowComponent: WindowComponent, NSWindowDelegate, NSUserInterfaceValidations, WorkspaceDelegate {

  fileprivate static let nibName = "MainWindow"

  fileprivate var defaultEditorFont: NSFont
//  fileprivate var usesLigatures: Bool

  fileprivate var _cwd: URL = FileUtils.userHomeUrl

  fileprivate let fontManager = NSFontManager.shared()
  fileprivate let fileItemService: FileItemService

  fileprivate let workspace: Workspace
  fileprivate let neoVimView: NeoVimView
  fileprivate var tools = [Tool: WorkspaceToolComponent]()

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
  /**
   The init() method does not show the window. Call MainWindowComponent.show() to do so.
   */
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
    self.fileItemService = fileItemService
    self._cwd = cwd

    super.init(source: source, nibName: MainWindowComponent.nibName)

    self.window.delegate = self

    self.workspace.delegate = self

    // FIXME: We do not use [self.sink, source].toMergedObservables. If we do so, then self.sink seems to live as long
    // as source, i.e. forever. Thus, self (MainWindowComponent) does not get deallocated. Not nice...
    let fileBrowser = FileBrowserComponent(source: self.sink, fileItemService: fileItemService)
    let fileBrowserTool = WorkspaceToolComponent(title: "Files", viewComponent: fileBrowser, minimumDimension: 100)
    self.tools[.fileBrowser] = fileBrowserTool
    self.workspace.append(tool: fileBrowserTool, location: .left)

    self.addReactions()

    self.neoVimView.delegate = self
    self.neoVimView.font = self.defaultEditorFont
    self.neoVimView.usesLigatures = initialData.appearance.editorUsesLigatures
    self.neoVimView.linespacing = initialData.appearance.editorLinespacing
    
    self.neoVimView.cwd = cwd // This will publish the MainWindowAction.changeCwd action for the file browser.
    self.neoVimView.open(urls: urls)

    // We don't call self.fileItemService.monitor(url: cwd) here since self.neoVimView.cwd = cwd causes the call
    // cwdChanged() and in that function we do monitor(...).

    // By default the tool buttons are shown and no tools are shown.
    let mainWindowData = initialData.mainWindow
    fileBrowserTool.dimension = CGFloat(mainWindowData.fileBrowserWidth)

    if !mainWindowData.isAllToolsVisible {
      self.toggleAllTools(self)
    }

    if !mainWindowData.isToolButtonsVisible {
      self.toggleToolButtons(self)
    }

    if mainWindowData.isFileBrowserVisible {
      fileBrowserTool.toggle()
    }

    self.window.makeFirstResponder(self.neoVimView)
  }

  func open(urls: [URL]) {
    self.neoVimView.open(urls: urls)
    self.window.makeFirstResponder(self.neoVimView)
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

  // MARK: - Private
  fileprivate func addReactions() {
    self.tools.values
      .map { $0.sink }
      .toMergedObservables()
      .subscribe(onNext: { [unowned self] action in
        switch action {
        case let FileBrowserAction.open(url: url):
          self.open(urls: [url])
        default:
          NSLog("unrecognized action: \(action)")
          return
        }
      })
      .addDisposableTo(self.disposeBag)
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
          || appearanceData.editorLinespacing != self.neoVimView.linespacing
      }
      .observeOn(MainScheduler.instance)
      .subscribe(onNext: { [unowned self] appearance in
        self.neoVimView.usesLigatures = appearance.editorUsesLigatures
        self.neoVimView.font = appearance.editorFont
        self.neoVimView.linespacing = appearance.editorLinespacing
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

// MARK: - File Menu Item Actions
extension MainWindowComponent {
  
  @IBAction func newTab(_ sender: Any?) {
    self.neoVimView.newTab()
  }

  @IBAction func openDocument(_ sender: Any?) {
    let panel = NSOpenPanel()
    panel.canChooseDirectories = true
    panel.allowsMultipleSelection = true
    panel.beginSheetModal(for: self.window) { result in
      guard result == NSFileHandlingPanelOKButton else {
        return
      }
      
      let urls = panel.urls
      if self.neoVimView.allBuffers().count == 1 {
        let isTransient = self.neoVimView.allBuffers().first?.isTransient ?? false
        if isTransient {
          self.neoVimView.cwd = FileUtils.commonParent(of: urls)
        }
      }
      self.neoVimView.open(urls: urls)
    }
  }

  @IBAction func openQuickly(_ sender: Any?) {
    self.publish(event: MainWindowAction.openQuickly(mainWindow: self))
  }

  @IBAction func saveDocument(_ sender: Any?) {
    guard let curBuf = self.neoVimView.currentBuffer() else {
      return
    }
    
    if curBuf.fileName == nil {
      self.savePanelSheet { self.neoVimView.saveCurrentTab(url: $0) }
      return
    }
    
    self.neoVimView.saveCurrentTab()
  }
  
  @IBAction func saveDocumentAs(_ sender: Any?) {
    if self.neoVimView.currentBuffer() == nil {
      return
    }

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

// MARK: - Tools Menu Item Actions
extension MainWindowComponent {

  @IBAction func toggleAllTools(_ sender: Any?) {
    self.workspace.toggleAllTools()
    self.focusNeoVimView(self)
  }

  @IBAction func toggleToolButtons(_ sender: Any?) {
    self.workspace.toggleToolButtons()
  }

  @IBAction func toggleFileBrowser(_ sender: Any?) {
    let fileBrowserTool = self.tools[.fileBrowser]!

    if fileBrowserTool.isSelected {
      if fileBrowserTool.viewComponent.isFirstResponder {
        fileBrowserTool.toggle()
        self.focusNeoVimView(self)
      } else {
        fileBrowserTool.viewComponent.beFirstResponder()
      }

      return
    }

    fileBrowserTool.toggle()
    fileBrowserTool.viewComponent.beFirstResponder()
  }

  @IBAction func focusNeoVimView(_ sender: Any?) {
    self.window.makeFirstResponder(self.neoVimView)
  }
}

// MARK: - Font Menu Item Actions
extension MainWindowComponent {

  @IBAction func resetFontSize(_ sender: Any?) {
    self.neoVimView.font = self.defaultEditorFont
  }

  @IBAction func makeFontBigger(_ sender: Any?) {
    let curFont = self.neoVimView.font
    let font = self.fontManager.convert(curFont, toSize: min(curFont.pointSize + 1, PrefStore.maxEditorFontSize))
    self.neoVimView.font = font
  }

  @IBAction func makeFontSmaller(_ sender: Any?) {
    let curFont = self.neoVimView.font
    let font = self.fontManager.convert(curFont, toSize: max(curFont.pointSize - 1, PrefStore.minEditorFontSize))
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

    let fileBrowser = self.tools[.fileBrowser]!
    let prefData = MainWindowPrefData(isAllToolsVisible: self.workspace.isAllToolsVisible,
                                      isToolButtonsVisible: self.workspace.isToolButtonsVisible,
                                      isFileBrowserVisible: self.workspace.bars[.left]?.isOpen ?? true,
                                      fileBrowserWidth: Float(fileBrowser.dimension))

    self.publish(event: MainWindowAction.close(mainWindow: self, mainWindowPrefData: prefData))
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

// MARK: - NSUserInterfaceValidationsProtocol
extension MainWindowComponent {

  public func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
    let canSave = self.neoVimView.currentBuffer() != nil
    let canSaveAs = canSave
    let canOpen = canSave
    let canOpenQuickly = canSave
    let canFocusNeoVimView = self.window.firstResponder != self.neoVimView

    guard let action = item.action else {
      return true
    }

    switch action {
    case #selector(focusNeoVimView(_:)):
      return canFocusNeoVimView

    case #selector(openDocument(_:)):
      return canOpen

    case #selector(openQuickly(_:)):
      return canOpenQuickly

    case #selector(saveDocument(_:)):
      return canSave

    case #selector(saveDocumentAs(_:)):
      return canSaveAs

    default:
      return true
    }
  }
}
