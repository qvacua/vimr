/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import RxSwift

struct AppState: SerializableState {

  static let `default` = AppState()

  var openNewMainWindowOnLaunch = true
  var openNewMainWindowOnReactivation = true

  var useSnapshotUpdate = false

  var preferencesOpen = Marked(false)

  var mainWindowTemplate = MainWindow.State.default
  var currentMainWindowUuid: String?

  var mainWindows: [String: MainWindow.State] = [:]
  var quitWhenNoMainWindow = false

  let root = FileItem(URL(fileURLWithPath: "/", isDirectory: true))

  var openQuickly = OpenQuicklyWindow.State.default

  init() {
    self.mainWindowTemplate.root = self.root
  }

  init?(dict: [String: Any]) {
    guard let openOnLaunch = PrefUtils.bool(from: dict, for: Keys.openNewOnLaunch),
          let openOnReactivation = PrefUtils.bool(from: dict, for: Keys.openNewOnReactivation),
          let useSnapshot = PrefUtils.bool(from: dict, for: Keys.useSnapshotUpdateChannel)
      else {
      return nil
    }

    self.openNewMainWindowOnLaunch = openOnLaunch
    self.openNewMainWindowOnReactivation = openOnReactivation
    self.useSnapshotUpdate = useSnapshot

    let openQuicklyDict = dict[Keys.OpenQuickly.key] as? [String: Any] ?? [:]
    self.openQuickly = OpenQuicklyWindow.State(dict: openQuicklyDict) ?? OpenQuicklyWindow.State.default

    let mainWindowDict = dict[Keys.MainWindow.key] as? [String: Any] ?? [:]
    self.mainWindowTemplate = MainWindow.State(dict: mainWindowDict) ?? MainWindow.State.default
  }

  func dict() -> [String: Any] {
    return [
      Keys.openNewOnLaunch: self.openNewMainWindowOnLaunch,
      Keys.openNewOnReactivation: self.openNewMainWindowOnReactivation,
      Keys.useSnapshotUpdateChannel: self.useSnapshotUpdate,

      Keys.OpenQuickly.key: self.openQuickly.dict(),

      Keys.MainWindow.key: self.mainWindowTemplate.dict(),
    ]
  }
}

extension OpenQuicklyWindow {

  struct State: SerializableState {

    static let `default` = State()

    var flatFileItems = Observable<[FileItem]>.empty()
    var cwd = FileUtils.userHomeUrl
    var ignorePatterns = Set(["*/.git", "*.o", "*.d", "*.dia"].map(FileItemIgnorePattern.init))
    var ignoreToken = Token()

    var open = false

    init() {

    }

    init?(dict: [String: Any]) {
      guard let patternsString = PrefUtils.string(from: dict, for: Keys.OpenQuickly.ignorePatterns) else {
        return nil
      }

      self.ignorePatterns = FileItemIgnorePattern.from(string: patternsString)
    }

    func dict() -> [String: Any] {
      return [
        Keys.OpenQuickly.ignorePatterns: FileItemIgnorePattern.toString(self.ignorePatterns)
      ]
    }
  }
}

struct PreviewState {

  static let `default` = PreviewState()

  enum Status {

    case none
    case notSaved
    case error
    case markdown
  }

  var status = Status.none

  var buffer: URL?
  var html: URL?
  var server: URL?

  var updateDate: Date

  var editorPosition = Marked(Position.beginning)
  var previewPosition = Marked(Position.beginning)
  var ignoreNextForward = false
  var ignoreNextReverse = false
  var forceNextReverse = false

  init(status: Status = .none,
       buffer: URL? = nil,
       html: URL? = nil,
       server: URL? = nil,
       updateDate: Date = Date()) {
    self.status = status
    self.buffer = buffer
    self.html = html
    self.server = server
    self.updateDate = updateDate
  }
}

struct HtmlPreviewState {

  static let `default` = HtmlPreviewState()

  var htmlFile: URL?
  var server: Marked<URL>?
}

struct AppearanceState: SerializableState {

  static let `default` = AppearanceState()

  var font = NSFont.userFixedPitchFont(ofSize: 13)!
  var linespacing: CGFloat = 1
  var usesLigatures = false

  init() {

  }

  init?(dict: [String: Any]) {
    guard let editorFontName = dict[Keys.Appearance.editorFontName] as? String,
          let fEditorFontSize = PrefUtils.float(from: dict, for: Keys.Appearance.editorFontSize),
          let fEditorLinespacing = PrefUtils.float(from: dict, for: Keys.Appearance.editorLinespacing),
          let editorUsesLigatures = PrefUtils.bool(from: dict, for: Keys.Appearance.editorUsesLigatures)
      else {
      return nil
    }

    self.font = PrefUtils.saneFont(editorFontName, fontSize: CGFloat(fEditorFontSize))
    self.linespacing = CGFloat(fEditorLinespacing)
    self.usesLigatures = editorUsesLigatures
  }

  func dict() -> [String: Any] {
    return [
      Keys.Appearance.editorFontName: self.font.fontName,
      Keys.Appearance.editorFontSize: Float(self.font.pointSize),
      Keys.Appearance.editorLinespacing: Float(self.linespacing),
      Keys.Appearance.editorUsesLigatures: self.usesLigatures,
    ]
  }
}

extension MainWindow {

  struct State: SerializableState {

    static let `default` = State(isAllToolsVisible: true, isToolButtonsVisible: true)

    var isAllToolsVisible = true
    var isToolButtonsVisible = true

    ////// transient

    // must be replaced
    var root = FileItem(URL(fileURLWithPath: "/", isDirectory: true))
    var lastFileSystemUpdate = Marked(FileItem(URL(fileURLWithPath: "/", isDirectory: true)))

    var tools = WorkspaceToolState.default
    var orderedTools = WorkspaceToolState.orderedDefault

    var preview = PreviewState.default
    var htmlPreview = HtmlPreviewState.default

    var previewTool = PreviewTool.State.default

    var fileBrowserShowHidden = false

    // neovim
    var uuid = UUID().uuidString
    var currentBuffer: NeoVimBuffer?
    var buffers = [NeoVimBuffer]()
    var cwd = FileUtils.userHomeUrl

    var isDirty = false

    var appearance = AppearanceState.default
    var useInteractiveZsh = false

    // transient^2
    var close = false

    // to be cleaned
    var urlsToOpen = [URL: OpenMode]()
    var viewToBeFocused: FocusableView? = FocusableView.neoVimView

    init(isAllToolsVisible: Bool, isToolButtonsVisible: Bool) {
      self.isAllToolsVisible = isAllToolsVisible
      self.isToolButtonsVisible = isToolButtonsVisible
    }

    init?(dict: [String: Any]) {
      guard let isAllToolsVisible = PrefUtils.bool(from: dict, for: Keys.MainWindow.allToolsVisible),
            let isToolButtonsVisible = PrefUtils.bool(from: dict, for: Keys.MainWindow.toolButtonsVisible),
            let orderedToolsAsString = dict[Keys.MainWindow.orderedTools] as? [String],
            let isShowHidden = PrefUtils.bool(from: dict, for: Keys.MainWindow.isShowHidden)
        else {
        return nil
      }

      self.isAllToolsVisible = isAllToolsVisible
      self.isToolButtonsVisible = isToolButtonsVisible

      let appearanceDict = dict[Keys.Appearance.key] as? [String: Any] ?? [:]
      self.appearance = AppearanceState(dict: appearanceDict) ?? AppearanceState.default

      self.orderedTools = orderedToolsAsString.flatMap { MainWindow.Tools(rawValue: $0) }
      let missingOrderedTools = MainWindow.Tools.all.subtracting(self.orderedTools)
      self.orderedTools.append(contentsOf: missingOrderedTools)

      let workspaceToolsDict = dict[Keys.WorkspaceTool.key] as? [String: [String: Any]] ?? [:]
      let toolKeys = workspaceToolsDict.keys.flatMap { MainWindow.Tools(rawValue: $0) }
      let missingToolKeys = MainWindow.Tools.all.subtracting(toolKeys)

      var tools = Array(toolKeys).toDict { tool in
        return WorkspaceToolState(dict: workspaceToolsDict[tool.rawValue]!) ?? WorkspaceToolState.default[tool]!
      }
      missingToolKeys.forEach { missingTool in
        tools[missingTool] = WorkspaceToolState.default[missingTool]!
      }

      self.tools = tools

      let previewToolDict = dict[Keys.PreviewTool.key] as? [String: Any] ?? [:]
      self.previewTool = PreviewTool.State(dict: previewToolDict) ?? PreviewTool.State.default

      self.fileBrowserShowHidden = isShowHidden
    }

    func dict() -> [String: Any] {
      return [
        Keys.MainWindow.allToolsVisible: self.isAllToolsVisible,
        Keys.MainWindow.toolButtonsVisible: self.isToolButtonsVisible,

        Keys.Appearance.key: self.appearance.dict(),
        Keys.WorkspaceTool.key: Array(self.tools.keys.map { $0.rawValue })
          .toDict { self.tools[MainWindow.Tools(rawValue: $0)!]!.dict() },

        Keys.MainWindow.orderedTools: self.orderedTools.map { $0.rawValue },

        Keys.PreviewTool.key: self.previewTool.dict(),

        Keys.MainWindow.isShowHidden: self.fileBrowserShowHidden,
      ]
    }
  }
}

struct WorkspaceToolState: SerializableState {

  static let `default` = [
    MainWindow.Tools.fileBrowser: WorkspaceToolState(location: .left, dimension: 200, open: true),
    MainWindow.Tools.openedFilesList: WorkspaceToolState(location: .left, dimension: 200, open: false),
    MainWindow.Tools.preview: WorkspaceToolState(location: .right, dimension: 250, open: false),
    MainWindow.Tools.htmlPreview: WorkspaceToolState(location: .right, dimension: 500, open: false),
  ]

  static let `orderedDefault` = [
    MainWindow.Tools.fileBrowser,
    MainWindow.Tools.openedFilesList,
    MainWindow.Tools.preview,
    MainWindow.Tools.htmlPreview,
  ]

  var location = WorkspaceBarLocation.left
  var dimension = CGFloat(200)
  var open = false

  init(location: WorkspaceBarLocation, dimension: CGFloat, open: Bool) {
    self.location = location
    self.dimension = dimension
    self.open = open
  }

  init?(dict: [String: Any]) {
    guard let locationRawValue = dict[Keys.WorkspaceTool.location] as? String,
          let isOpen = PrefUtils.bool(from: dict, for: Keys.WorkspaceTool.open),
          let fDimension = PrefUtils.float(from: dict, for: Keys.WorkspaceTool.dimension)
      else {
      return nil
    }

    guard let location = PrefUtils.location(from: locationRawValue) else {
      return nil
    }

    self.location = location
    self.dimension = CGFloat(fDimension)
    self.open = isOpen
  }

  func dict() -> [String: Any] {
    return [
      Keys.WorkspaceTool.location: PrefUtils.locationAsString(for: self.location),
      Keys.WorkspaceTool.open: self.open,
      Keys.WorkspaceTool.dimension: Float(self.dimension),
    ]
  }
}

extension PreviewTool {

  struct State: SerializableState {

    static let `default` = State()

    var isForwardSearchAutomatically = false
    var isReverseSearchAutomatically = false
    var isRefreshOnWrite = true

    init() {

    }

    init?(dict: [String: Any]) {
      guard let isForward = PrefUtils.bool(from: dict, for: Keys.PreviewTool.forwardSearchAutomatically),
            let isReverse = PrefUtils.bool(from: dict, for: Keys.PreviewTool.reverseSearchAutomatically),
            let isRefreshOnWrite = PrefUtils.bool(from: dict, for: Keys.PreviewTool.refreshOnWrite)
        else {
        return nil
      }

      self.isRefreshOnWrite = isRefreshOnWrite
      self.isForwardSearchAutomatically = isForward
      self.isReverseSearchAutomatically = isReverse
    }

    func dict() -> [String: Any] {
      return [
        Keys.PreviewTool.forwardSearchAutomatically: self.isForwardSearchAutomatically,
        Keys.PreviewTool.reverseSearchAutomatically: self.isReverseSearchAutomatically,
        Keys.PreviewTool.refreshOnWrite: self.isRefreshOnWrite,
      ]
    }
  }
}
