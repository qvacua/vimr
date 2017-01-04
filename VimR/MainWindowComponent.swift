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
  case changeCwd(mainWindow: MainWindowComponent, cwd: URL)
  case changeBufferList(mainWindow: MainWindowComponent, buffers: [NeoVimBuffer])
  case changeFileBrowserSelection(mainWindow: MainWindowComponent, url: URL)
  case close(mainWindow: MainWindowComponent, mainWindowPrefData: MainWindowPrefData)

  case toggleTool(tool: WorkspaceTool)
  case currentBufferChanged(mainWindow: MainWindowComponent, buffer: NeoVimBuffer)
}

struct MainWindowPrefData: StandardPrefData {

  fileprivate static let isAllToolsVisible = "is-all-tools-visible"
  fileprivate static let isToolButtonsVisible = "is-tool-buttons-visible"
  fileprivate static let toolPrefDatas = "tool-pref-datas"

  static let `default` = MainWindowPrefData(isAllToolsVisible: true,
                                            isToolButtonsVisible: true,
                                            toolPrefDatas: [
                                                ToolPrefData.defaults[.fileBrowser]!,
                                                ToolPrefData.defaults[.bufferList]!,
                                                ToolPrefData.defaults[.preview]!,
                                            ])

  var isAllToolsVisible: Bool
  var isToolButtonsVisible: Bool
  var toolPrefDatas: [ToolPrefData]

  init(isAllToolsVisible: Bool, isToolButtonsVisible: Bool, toolPrefDatas: [ToolPrefData]) {
    self.isAllToolsVisible = isAllToolsVisible
    self.isToolButtonsVisible = isToolButtonsVisible
    self.toolPrefDatas = toolPrefDatas
  }

  init?(dict: [String: Any]) {

    guard let isAllToolsVisible = PrefUtils.bool(from: dict, for: MainWindowPrefData.isAllToolsVisible),
          let isToolButtonsVisible = PrefUtils.bool(from: dict, for: MainWindowPrefData.isToolButtonsVisible),
          let toolDataDicts = dict[MainWindowPrefData.toolPrefDatas] as? [[String: Any]]
        else {
      return nil
    }

    // Add default tool pref data for missing identifiers.
    let toolDatas = toolDataDicts.flatMap { ToolPrefData(dict: $0) }
    let missingToolDatas = Set(ToolIdentifier.all)
        .subtracting(toolDatas.map { $0.identifier })
        .flatMap { ToolPrefData.defaults[$0] }

    self.init(isAllToolsVisible: isAllToolsVisible,
              isToolButtonsVisible: isToolButtonsVisible,
              toolPrefDatas: [ toolDatas, missingToolDatas ].flatMap { $0 })
  }

  func dict() -> [String: Any] {
    return [
      MainWindowPrefData.isAllToolsVisible: self.isAllToolsVisible,
      MainWindowPrefData.isToolButtonsVisible: self.isToolButtonsVisible,
      MainWindowPrefData.toolPrefDatas: self.toolPrefDatas.map { $0.dict() },
    ]
  }

  func toolPrefData(for identifier: ToolIdentifier) -> ToolPrefData {
    guard let data = self.toolPrefDatas.first(where: { $0.identifier == identifier }) else {
      preconditionFailure("[ERROR] No tool for \(identifier) found!")
    }

    return data
  }
}

class MainWindowComponent: WindowComponent,
                           NeoVimViewDelegate,
                           NSWindowDelegate,
                           NSUserInterfaceValidations,
                           WorkspaceDelegate
{

  enum ScrollAction {

    case scroll
  }

  fileprivate static let nibName = "MainWindow"

  fileprivate var defaultEditorFont: NSFont

  fileprivate var _cwd: URL = FileUtils.userHomeUrl

  fileprivate let fontManager = NSFontManager.shared()
  fileprivate let fileItemService: FileItemService

  fileprivate let workspace: Workspace
  fileprivate let neoVimView: NeoVimView
  fileprivate var tools = [ToolIdentifier: WorkspaceToolComponent]()

  fileprivate let scrollFlow: EmbeddableComponent

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
    self.neoVimView.configureForAutoLayout()

    self.workspace = Workspace(mainView: self.neoVimView)

    self.defaultEditorFont = initialData.appearance.editorFont
    self.fileItemService = fileItemService

    self.scrollFlow = EmbeddableComponent(source: Observable.empty())

    super.init(source: source, nibName: MainWindowComponent.nibName)

    self.window.delegate = self
    self.workspace.delegate = self

    self.setupTools(with: initialData.mainWindow)

    self.neoVimView.delegate = self
    self.neoVimView.font = self.defaultEditorFont
    self.neoVimView.usesLigatures = initialData.appearance.editorUsesLigatures
    self.neoVimView.linespacing = initialData.appearance.editorLinespacing
    let neoVimViewCwd = self.neoVimView.cwd
    if neoVimViewCwd == cwd {
      self.fileItemService.monitor(url: cwd)
    } else {
      self.neoVimView.cwd = cwd // The above will publish the MainWindowAction.changeCwd action for the file browser.
    }
    self.neoVimView.open(urls: urls)

    self._cwd = cwd

    self.addReactions()

    self.window.makeFirstResponder(self.neoVimView)
  }

  fileprivate func setupTools(with mainWindowData: MainWindowPrefData) {
    // By default the tool buttons are shown and only the file browser tool is shown.
    let fileBrowserToolData = mainWindowData.toolPrefData(for: .fileBrowser)
    let bufferListToolData = mainWindowData.toolPrefData(for: .bufferList)
    let previewToolData = mainWindowData.toolPrefData(for: .preview)

    let fileBrowserData = fileBrowserToolData.toolData as? FileBrowserData ?? FileBrowserData.default

    // FIXME: We do not use [self.sink, source].toMergedObservables. If we do so, then self.sink seems to live as long
    // as source, i.e. forever. Thus, self (MainWindowComponent) does not get deallocated. Not nice...
    let fileBrowser = FileBrowserComponent(source: self.sink,
                                           fileItemService: self.fileItemService,
                                           initialData: fileBrowserData)
    let fileBrowserConfig = WorkspaceTool.Config(title: "Files",
                                                 view: fileBrowser,
                                                 minimumDimension: 100,
                                                 withInnerToolbar: true,
                                                 customToolbar: fileBrowser.innerCustomToolbar,
                                                 customMenuItems: fileBrowser.menuItems)
    let fileBrowserTool = WorkspaceToolComponent(toolIdentifier: .fileBrowser, config: fileBrowserConfig)
    self.tools[.fileBrowser] = fileBrowserTool

    let bufferList = BufferListComponent(source: self.sink, fileItemService: self.fileItemService)
    let bufferListConfig = WorkspaceTool.Config(title: "Buffers",
                                                view: bufferList,
                                                minimumDimension: 100,
                                                withInnerToolbar: true)
    let bufferListTool = WorkspaceToolComponent(toolIdentifier: .bufferList, config: bufferListConfig)
    self.tools[.bufferList] = bufferListTool

    let previewData = previewToolData.toolData as? PreviewComponent.PrefData ?? PreviewComponent.PrefData.default
    let preview = PreviewComponent(source: self.sink,
                                   scrollSource: self.scrollFlow.sink,
                                   initialData: previewData)
    let previewConfig = WorkspaceTool.Config(title: "Preview",
                                             view: preview,
                                             minimumDimension: 200,
                                             withInnerToolbar: true)
    let previewTool = WorkspaceToolComponent(toolIdentifier: .preview, config: previewConfig)
    preview.workspaceTool = previewTool
    self.tools[.preview] = previewTool

    self.workspace.append(tool: fileBrowserTool, location: fileBrowserToolData.location)
    self.workspace.append(tool: bufferListTool, location: bufferListToolData.location)
    self.workspace.append(tool: previewTool, location: previewToolData.location)

    fileBrowserTool.dimension = fileBrowserToolData.dimension
    bufferListTool.dimension = bufferListToolData.dimension
    previewTool.dimension = previewToolData.dimension

    if !mainWindowData.isAllToolsVisible {
      self.toggleAllTools(self)
    }

    if !mainWindowData.isToolButtonsVisible {
      self.toggleToolButtons(self)
    }

    if fileBrowserToolData.isVisible {
      fileBrowserTool.toggle()
    }

    if bufferListToolData.isVisible {
      bufferListTool.toggle()
    }

    if previewToolData.isVisible {
      previewTool.toggle()
    }
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
          self.neoVimView.open(urls: [url])

        case let FileBrowserAction.openInNewTab(url: url):
          self.neoVimView.openInNewTab(urls: [url])

        case let FileBrowserAction.openInCurrentTab(url: url):
          self.neoVimView.openInCurrentTab(url: url)

        case let FileBrowserAction.openInHorizontalSplit(url: url):
          self.neoVimView.openInHorizontalSplit(urls: [url])

        case let FileBrowserAction.openInVerticalSplit(url: url):
          self.neoVimView.openInVerticalSplit(urls: [url])

        case let FileBrowserAction.setAsWorkingDirectory(url: url):
          self.neoVimView.cwd = url

        case let FileBrowserAction.scrollToSource(cwd: cwd):
          guard let curBufUrl = self.neoVimView.currentBuffer()?.url else {
            return
          }

          guard curBufUrl.isContained(in: cwd) else {
            return
          }

          self.publish(event: MainWindowAction.changeFileBrowserSelection(mainWindow: self, url: curBufUrl))

        case let BufferListAction.open(buffer: buffer):
          self.neoVimView.select(buffer: buffer)

        case let PreviewComponent.Action.scroll(to: position):
          NSLog("\(position)")
          return

        default:
          NSLog("Not handled action: \(action)")
          return
        }

        self.window.makeFirstResponder(self.neoVimView)
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
        let curData = AppearancePrefData(editorFont: self.neoVimView.font,
                                         editorLinespacing: self.neoVimView.linespacing,
                                         editorUsesLigatures: self.neoVimView.usesLigatures)
        return appearanceData != curData
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

  func toggled(tool: WorkspaceTool) {
    self.publish(event: MainWindowAction.toggleTool(tool: tool))
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

    if curBuf.url == nil {
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
      if fileBrowserTool.viewComponent.view.isFirstResponder {
        fileBrowserTool.toggle()
        self.focusNeoVimView(self)
      } else {
        fileBrowserTool.viewComponent.view.beFirstResponder()
      }

      return
    }

    fileBrowserTool.toggle()
    fileBrowserTool.viewComponent.view.beFirstResponder()
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
    let font = self.fontManager.convert(curFont, toSize: min(curFont.pointSize + 1, NeoVimView.maxFontSize))
    self.neoVimView.font = font
  }

  @IBAction func makeFontSmaller(_ sender: Any?) {
    let curFont = self.neoVimView.font
    let font = self.fontManager.convert(curFont, toSize: max(curFont.pointSize - 1, NeoVimView.minFontSize))
    self.neoVimView.font = font
  }
}

// MARK: - NeoVimViewDelegate
extension MainWindowComponent {

  func neoVimStopped() {
    self.windowController.close()
  }

  func set(title: String) {
    self.window.title = title
  }

  func set(dirtyStatus: Bool) {
    self.windowController.setDocumentEdited(dirtyStatus)
  }

  func cwdChanged() {
    let old = self._cwd
    self._cwd = self.neoVimView.cwd

    // FIXME: This can still happen...
    if old == self._cwd {
      return
    }

    self.fileItemService.unmonitor(url: old)
    self.fileItemService.monitor(url: self._cwd)

    self.publish(event: MainWindowAction.changeCwd(mainWindow: self, cwd: self._cwd))
  }

  func bufferListChanged() {
    let buffers = self.neoVimView.allBuffers()
    self.publish(event: MainWindowAction.changeBufferList(mainWindow: self, buffers: buffers))
  }

  func currentBufferChanged(_ currentBuffer: NeoVimBuffer) {
    self.publish(event: MainWindowAction.currentBufferChanged(mainWindow: self, buffer: currentBuffer))
  }

  func ipcBecameInvalid(reason: String) {
    let alert = NSAlert()
    alert.addButton(withTitle: "Close")
    alert.messageText = "Sorry, an error occurred."
    alert.informativeText = "VimR encountered an error from which it cannot recover. This window will now close.\n"
      + reason
    alert.alertStyle = .critical
    alert.beginSheetModal(for: self.window) { [weak self] response in
      self?.windowController.close()
    }
  }

  func scroll() {
    self.scrollFlow.publish(event: ScrollAction.scroll)
  }
}

// MARK: - NSWindowDelegate
extension MainWindowComponent {

  func windowDidBecomeKey(_: Notification) {
    self.publish(event: MainWindowAction.becomeKey(mainWindow: self))
  }

  func windowWillClose(_ notification: Notification) {
    self.fileItemService.unmonitor(url: self._cwd)

    let prefData = MainWindowPrefData(isAllToolsVisible: self.workspace.isAllToolsVisible,
                                      isToolButtonsVisible: self.workspace.isToolButtonsVisible,
                                      toolPrefDatas: self.toolPrefDatas())

    // When exiting full screen, often, some delegate methods of NSWindow get called after deallocation. This is just
    // a quick-and-dirty fix.
    // TODO: fix it for real...
    self.windowController.window?.delegate = nil

    self.publish(event: MainWindowAction.close(mainWindow: self, mainWindowPrefData: prefData))
  }

  fileprivate func toolPrefDatas() -> [ToolPrefData] {
    let fileBrowser = self.tools[.fileBrowser]!
    let fileBrowserData = ToolPrefData(identifier: .fileBrowser,
                                       location: fileBrowser.location,
                                       isVisible: fileBrowser.isSelected,
                                       dimension: fileBrowser.dimension,
                                       toolData: fileBrowser.toolData)

    let bufferList = self.tools[.bufferList]!
    let bufferListData = ToolPrefData(identifier: .bufferList,
                                      location: bufferList.location,
                                      isVisible: bufferList.isSelected,
                                      dimension: bufferList.dimension)

    let preview = self.tools[.preview]!
    let previewData = ToolPrefData(identifier: .preview,
                                   location: preview.location,
                                   isVisible: preview.isSelected,
                                   dimension: preview.dimension,
                                   toolData: preview.toolData)

    return [ fileBrowserData, bufferListData, previewData ]
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
