/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import RxSwift

struct AppState: SerializableState {

  enum AfterLastWindowAction: String {

    case doNothing = "do-nothing"
    case hide = "hide"
    case quit = "quit"
  }

  static let `default` = AppState()

  var openNewMainWindowOnLaunch = true
  var openNewMainWindowOnReactivation = true

  var afterLastWindowAction = AfterLastWindowAction.doNothing

  var useSnapshotUpdate = false

  var preferencesOpen = Marked(false)

  var mainWindowTemplate = MainWindow.State.default
  var currentMainWindowUuid: String?

  var mainWindows: [String: MainWindow.State] = [:]

  var openQuickly = OpenQuicklyWindow.State.default

  init() {

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

    let lastWindowActionString = PrefUtils.string(from: dict, for: Keys.afterLastWindowAction)
                                 ?? AfterLastWindowAction.doNothing.rawValue
    self.afterLastWindowAction = AfterLastWindowAction(rawValue: lastWindowActionString) ?? .doNothing

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
      Keys.afterLastWindowAction: self.afterLastWindowAction.rawValue,
      Keys.useSnapshotUpdateChannel: self.useSnapshotUpdate,

      Keys.OpenQuickly.key: self.openQuickly.dict(),

      Keys.MainWindow.key: self.mainWindowTemplate.dict(),
    ]
  }
}

extension OpenQuicklyWindow {

  struct State: SerializableState {

    static let `default` = State()

    let root = FileItem(URL(fileURLWithPath: "/", isDirectory: true))

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

  var usesTheme = true
  var showsFileIcon = true
  var theme = Marked(Theme.default)

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

    self.usesTheme = PrefUtils.bool(from: dict, for: Keys.Appearance.usesTheme, default: true)
    self.showsFileIcon = PrefUtils.bool(from: dict, for: Keys.Appearance.showsFileIcon, default: true)

    self.font = PrefUtils.saneFont(editorFontName, fontSize: CGFloat(fEditorFontSize))
    self.linespacing = CGFloat(fEditorLinespacing)
    self.usesLigatures = editorUsesLigatures
  }

  func dict() -> [String: Any] {
    return [
      Keys.Appearance.usesTheme: self.usesTheme,
      Keys.Appearance.showsFileIcon: self.showsFileIcon,
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
    var activeTools = [
      Tools.fileBrowser: true,
      Tools.buffersList: true,
      Tools.preview: true,
      Tools.htmlPreview: true,
    ]

    var frame = CGRect(x: 100, y: 100, width: 600, height: 400)

    ////// transient
    var lastFileSystemUpdate = Marked(FileUtils.userHomeUrl)

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
    var nvimArgs: [String]?
    var cliPipePath: String?

    // to be cleaned
    var urlsToOpen = [URL: OpenMode]()
    var currentBufferToSet: NeoVimBuffer?
    var cwdToSet: URL?
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

      // Stay compatible with 168
      self.useInteractiveZsh = PrefUtils.bool(from: dict, for: Keys.MainWindow.useInteractiveZsh, default: false)
      let frameString = PrefUtils.string(from: dict,
                                         for: Keys.MainWindow.frame,
                                         default: NSStringFromRect(self.frame))
      self.frame = NSRectFromString(frameString)

      self.isAllToolsVisible = isAllToolsVisible
      self.isToolButtonsVisible = isToolButtonsVisible

      let appearanceDict = dict[Keys.Appearance.key] as? [String: Any] ?? [:]
      self.appearance = AppearanceState(dict: appearanceDict) ?? AppearanceState.default

      self.orderedTools = orderedToolsAsString.flatMap { MainWindow.Tools(rawValue: $0) }
      let missingOrderedTools = MainWindow.Tools.all.subtracting(self.orderedTools)
      self.orderedTools.append(contentsOf: missingOrderedTools)

      // To stay compatible with 168 we do not guard against nil activeToolsAsString.
      let activeToolsAsString = dict[Keys.MainWindow.activeTools] as? [String: Bool] ?? [:]
      self.activeTools = activeToolsAsString.flatMapToDict { (key, value) in
        guard let toolId = MainWindow.Tools(rawValue: key) else {
          return nil
        }

        return (toolId, value)
      }
      let missingActiveTools = MainWindow.Tools.all.subtracting(self.activeTools.keys)
      missingActiveTools.forEach { self.activeTools[$0] = true }

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

        Keys.MainWindow.frame: NSStringFromRect(self.frame),

        Keys.Appearance.key: self.appearance.dict(),
        Keys.WorkspaceTool.key: self.tools.mapToDict { ($0.rawValue, $1.dict()) },

        Keys.MainWindow.orderedTools: self.orderedTools.map { $0.rawValue },
        Keys.MainWindow.activeTools: self.activeTools.mapToDict { ($0.rawValue, $1) },

        Keys.PreviewTool.key: self.previewTool.dict(),

        Keys.MainWindow.isShowHidden: self.fileBrowserShowHidden,
        Keys.MainWindow.useInteractiveZsh: self.useInteractiveZsh,
      ]
    }
  }
}

struct WorkspaceToolState: SerializableState {

  static let `default` = [
    MainWindow.Tools.fileBrowser: WorkspaceToolState(location: .left, dimension: 200, open: true),
    MainWindow.Tools.buffersList: WorkspaceToolState(location: .left, dimension: 200, open: false),
    MainWindow.Tools.preview: WorkspaceToolState(location: .right, dimension: 250, open: false),
    MainWindow.Tools.htmlPreview: WorkspaceToolState(location: .right, dimension: 500, open: false),
  ]

  static let `orderedDefault` = [
    MainWindow.Tools.fileBrowser,
    MainWindow.Tools.buffersList,
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

    guard let location = WorkspaceBarLocation(rawValue: locationRawValue) else {
      return nil
    }

    self.location = location
    self.dimension = CGFloat(fDimension)
    self.open = isOpen
  }

  func dict() -> [String: Any] {
    return [
      Keys.WorkspaceTool.location: self.location.rawValue,
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
