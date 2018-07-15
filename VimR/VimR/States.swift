/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import RxSwift

struct AppState: Codable, SerializableState {

  enum AfterLastWindowAction: String, Codable {

    case doNothing = "do-nothing"
    case hide = "hide"
    case quit = "quit"
  }

  static let `default` = AppState()

  enum CodingKeys: String, CodingKey {

    case openNewMainWindowOnLaunch = "open-new-window-when-launching"
    case openNewMainWindowOnReactivation = "open-new-window-on-reactivation"
    case afterLastWindowAction = "after-last-window-action"
    case useSnapshotUpdate = "use-snapshot-update-channel"

    case openQuickly = "open-quickly"
    case mainWindowTemplate = "main-window"
  }

  var openNewMainWindowOnLaunch = true
  var openNewMainWindowOnReactivation = true

  var afterLastWindowAction = AfterLastWindowAction.doNothing

  var useSnapshotUpdate = false

  var preferencesOpen = Marked(false)

  var mainWindowTemplate = MainWindow.State.default
  var currentMainWindowUuid: String?

  var mainWindows: [String: MainWindow.State] = [:]

  var openQuickly = OpenQuicklyWindow.State.default

  var quit = false

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    self.openNewMainWindowOnLaunch = try container.decode(forKey: .openNewMainWindowOnLaunch,
                                                          default: AppState.default.openNewMainWindowOnLaunch)
    self.openNewMainWindowOnReactivation = try container.decode(
      forKey: .openNewMainWindowOnReactivation, default: AppState.default.openNewMainWindowOnReactivation
    )
    self.afterLastWindowAction = try container.decode(forKey: .afterLastWindowAction, default: .doNothing)
    self.useSnapshotUpdate = try container.decode(forKey: .useSnapshotUpdate,
                                                  default: AppState.default.useSnapshotUpdate)

    self.openQuickly = try container.decode(forKey: .openQuickly, default: OpenQuicklyWindow.State.default)
    self.mainWindowTemplate = try container.decode(forKey: .mainWindowTemplate, default: MainWindow.State.default)
  }

  // Use generated encode(to:)

  private init() {
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

    let jsonEncoder = JSONEncoder()
    let data = try? jsonEncoder.encode(self)

    let jsonDecoder = JSONDecoder()
    do {
      let test = try jsonDecoder.decode(AppState.self, from: data!)
      try data?.write(to: URL(fileURLWithPath: "/tmp/vimr.codable1.json"))
      try? jsonEncoder.encode(test).write(to: URL(fileURLWithPath: "/tmp/vimr.codable2.json"))
    } catch {
      stdoutLog.debug(error)
    }
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

  struct State: Codable, SerializableState {

    static let `default` = State()
    static let defaultIgnorePatterns = Set(["*/.git", "*.o", "*.d", "*.dia"].map(FileItemIgnorePattern.init))

    enum CodingKeys: String, CodingKey {

      case ignorePatterns = "ignore-patterns"
    }

    let root = FileItem(URL(fileURLWithPath: "/", isDirectory: true))

    var flatFileItems = Observable<[FileItem]>.empty()
    var cwd = FileUtils.userHomeUrl
    var ignorePatterns = State.defaultIgnorePatterns
    var ignoreToken = Token()

    var open = false

    init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      if let patternsAsString = try container.decodeIfPresent(String.self, forKey: .ignorePatterns) {
        self.ignorePatterns = FileItemIgnorePattern.from(string: patternsAsString)
      } else {
        self.ignorePatterns = State.defaultIgnorePatterns
      }
    }

    func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(FileItemIgnorePattern.toString(self.ignorePatterns), forKey: .ignorePatterns)
    }

    private init() {
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

  enum SearchAction {

    case none
    case forward
    case reverse
    case reload
  }

  var status = Status.none

  var buffer: URL?
  var html: URL?
  var server: URL?

  var updateDate: Date

  var editorPosition = Marked(Position.beginning)
  var previewPosition = Marked(Position.beginning)
  var lastSearch = SearchAction.none

  init(status: Status = .none,
       buffer: URL? = nil,
       html: URL? = nil,
       server: URL? = nil,
       updateDate: Date = Date(),
       editorPosition: Marked<Position> = Marked(.beginning),
       previewPosition: Marked<Position> = Marked(.beginning)
  ) {
    self.status = status
    self.buffer = buffer
    self.html = html
    self.server = server
    self.updateDate = updateDate
    self.editorPosition = editorPosition
    self.previewPosition = previewPosition
  }
}

struct HtmlPreviewState {

  static let `default` = HtmlPreviewState()

  var htmlFile: URL?
  var server: Marked<URL>?
}

struct AppearanceState: Codable, SerializableState {

  static let `default` = AppearanceState()

  enum CodingKeys: String, CodingKey {

    case usesTheme = "uses-theme"
    case showsFileIcon = "shows-file-icon"
    case editorFontName = "editor-font-name"
    case editorFontSize = "editor-font-size"
    case editorLinespacing = "editor-linespacing"
    case editorUsesLigatures = "editor-uses-ligatures"
  }

  var font = NSFont.userFixedPitchFont(ofSize: 13)!
  var linespacing: CGFloat = 1
  var usesLigatures = false

  var usesTheme = true
  var showsFileIcon = true
  var theme = Marked(Theme.default)

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    if let fontName = try container.decodeIfPresent(String.self, forKey: .editorFontName),
       let fontSize = try container.decodeIfPresent(Float.self, forKey: .editorFontSize),
       let font = NSFont(name: fontName, size: CGFloat(fontSize)) {
      self.font = font
    } else {
      self.font = NvimView.defaultFont
    }

    self.linespacing = CGFloat(try container.decodeIfPresent(Float.self, forKey: .editorLinespacing) ?? 1.0)
    self.usesLigatures = try container.decodeIfPresent(Bool.self, forKey: .editorUsesLigatures) ?? true

    self.usesTheme = try container.decodeIfPresent(Bool.self, forKey: .usesTheme) ?? true
    self.showsFileIcon = try container.decodeIfPresent(Bool.self, forKey: .showsFileIcon) ?? true
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    try container.encode(self.usesTheme, forKey: .usesTheme)
    try container.encode(self.showsFileIcon, forKey: .showsFileIcon)
    try container.encode(self.font.fontName, forKey: .editorFontName)
    try container.encode(self.font.pointSize, forKey: .editorFontSize)
    try container.encode(self.linespacing, forKey: .editorLinespacing)
    try container.encode(self.usesLigatures, forKey: .editorUsesLigatures)
  }

  private init() {
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

  struct State: Codable, SerializableState {

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
    var goToLineFromCli: Marked<Int>?
    var lastFileSystemUpdate = Marked(FileUtils.userHomeUrl)

    var tools = WorkspaceToolState.defaultTools
    var orderedTools = WorkspaceToolState.orderedDefault

    var preview = PreviewState.default
    var htmlPreview = HtmlPreviewState.default

    var previewTool = PreviewTool.State.default

    var fileBrowserShowHidden = false

    var trackpadScrollResistance = 5.0
    var useLiveResize = false

    // neovim
    var uuid = UUID().uuidString
    var currentBuffer: NvimView.Buffer?
    var buffers = [NvimView.Buffer]()
    var cwd = FileUtils.userHomeUrl

    var isDirty = false

    var appearance = AppearanceState.default
    var useInteractiveZsh = false
    var nvimArgs: [String]?
    var cliPipePath: String?
    var envDict: [String: String]?

    var isLeftOptionMeta = false
    var isRightOptionMeta = false

    // to be cleaned
    var urlsToOpen = [URL: OpenMode]()
    var currentBufferToSet: NvimView.Buffer?
    var cwdToSet: URL?
    var viewToBeFocused: FocusableView? = FocusableView.neoVimView

    init(isAllToolsVisible: Bool, isToolButtonsVisible: Bool) {
      self.isAllToolsVisible = isAllToolsVisible
      self.isToolButtonsVisible = isToolButtonsVisible
    }

    enum CodingKeys: String, CodingKey {

      case allToolsVisible = "is-all-tools-visible"
      case toolButtonsVisible = "is-tool-buttons-visible"
      case orderedTools = "ordered-tools"
      case activeTools = "active-tools"
      case frame = "frame"

      case isLeftOptionMeta = "is-left-option-meta"
      case isRightOptionMeta = "is-right-option-meta"

      case trackpadScrollResistance = "trackpad-scroll-resistance"
      case useInteractiveZsh = "use-interactive-zsh"
      case useLiveResize = "use-live-resize"
      case isShowHidden = "is-show-hidden"

      case appearance = "appearance"
      case workspaceTools = "workspace-tool"
      case previewTool = "preview-tool"
    }

    init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)

      self.isLeftOptionMeta = try container.decode(forKey: .isLeftOptionMeta, default: State.default.isLeftOptionMeta)
      self.isRightOptionMeta = try container.decode(forKey: .isRightOptionMeta,
                                                    default: State.default.isRightOptionMeta)
      self.useInteractiveZsh = try container.decode(forKey: .useInteractiveZsh,
                                                    default: State.default.useInteractiveZsh)
      self.trackpadScrollResistance = try container.decode(forKey: .trackpadScrollResistance,
                                                           default: State.default.trackpadScrollResistance)
      self.useLiveResize = try container.decode(forKey: .useLiveResize, default: State.default.useLiveResize)
      if let frameRawValue = try container.decodeIfPresent(String.self, forKey: .frame) {
        self.frame = NSRectFromString(frameRawValue)
      } else {
        self.frame = CGRect(x: 100, y: 100, width: 600, height: 400)
      }

      self.isAllToolsVisible = try container.decode(forKey: .allToolsVisible, default: State.default.isAllToolsVisible)
      self.isToolButtonsVisible = try container.decode(forKey: .toolButtonsVisible,
                                                       default: State.default.isToolButtonsVisible)

      self.appearance = try container.decode(forKey: .appearance, default: State.default.appearance)

      self.orderedTools = try container.decode(forKey: .orderedTools, default: State.default.orderedTools)
      let missingOrderedTools = MainWindow.Tools.all.subtracting(self.orderedTools)
      self.orderedTools.append(contentsOf: missingOrderedTools)

      // See [1]
      let rawActiveTools: [String: Bool] = try container.decode(forKey: .activeTools, default: [:])
      self.activeTools = rawActiveTools.flatMapToDict { (key, value) in
        guard let toolId = MainWindow.Tools(rawValue: key) else {
          return nil
        }

        return (toolId, value)
      }
      let missingActiveTools = MainWindow.Tools.all.subtracting(self.activeTools.keys)
      missingActiveTools.forEach { self.activeTools[$0] = true }

      let rawTools: [String: WorkspaceToolState] = try container.decode(forKey: .workspaceTools, default: [:])
      self.tools = rawTools.flatMapToDict { (key, value) in
        guard let tool = MainWindow.Tools(rawValue: key) else {
          return nil
        }

        return (tool, value)
      }
      let missingTools = MainWindow.Tools.all.subtracting(self.tools.keys)
      missingTools.forEach { missingTool in
        self.tools[missingTool] = WorkspaceToolState.defaultTools[missingTool]!
      }

      self.previewTool = try container.decode(forKey: .previewTool, default: State.default.previewTool)
      self.fileBrowserShowHidden = try container.decode(forKey: .isShowHidden,
                                                        default: State.default.fileBrowserShowHidden)
    }

    func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)

      try container.encode(self.isAllToolsVisible, forKey: .allToolsVisible)
      try container.encode(self.isToolButtonsVisible, forKey: .toolButtonsVisible)
      try container.encode(NSStringFromRect(self.frame), forKey: .frame)
      try container.encode(self.trackpadScrollResistance, forKey: .trackpadScrollResistance)
      try container.encode(self.useLiveResize, forKey: .useLiveResize)
      try container.encode(self.isLeftOptionMeta, forKey: .isLeftOptionMeta)
      try container.encode(self.isRightOptionMeta, forKey: .isRightOptionMeta)

      // See [1]
      try container.encode(Dictionary(uniqueKeysWithValues: self.tools.map { k, v in (k.rawValue, v) }),
                           forKey: .workspaceTools)
      try container.encode(Dictionary(uniqueKeysWithValues: self.activeTools.map { k, v in (k.rawValue, v) }),
                           forKey: .activeTools)

      try container.encode(self.appearance, forKey: .appearance)
      try container.encode(self.orderedTools, forKey: .orderedTools)
      try container.encode(self.previewTool, forKey: .previewTool)
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
      self.isLeftOptionMeta = PrefUtils.bool(from: dict, for: Keys.MainWindow.isLeftOptionMeta, default: false)
      self.isRightOptionMeta = PrefUtils.bool(from: dict, for: Keys.MainWindow.isRightOptionMeta, default: false)

      self.useInteractiveZsh = PrefUtils.bool(from: dict, for: Keys.MainWindow.useInteractiveZsh, default: false)
      self.trackpadScrollResistance = PrefUtils.value(from: dict,
                                                      for: Keys.MainWindow.trackpadScrollResistance,
                                                      default: 5.0)
      self.useLiveResize = PrefUtils.bool(from: dict, for: Keys.MainWindow.useLiveResize, default: false)
      let frameString = PrefUtils.string(from: dict,
                                         for: Keys.MainWindow.frame,
                                         default: NSStringFromRect(self.frame))
      self.frame = NSRectFromString(frameString)

      self.isAllToolsVisible = isAllToolsVisible
      self.isToolButtonsVisible = isToolButtonsVisible

      let appearanceDict = dict[Keys.Appearance.key] as? [String: Any] ?? [:]
      self.appearance = AppearanceState(dict: appearanceDict) ?? AppearanceState.default

      self.orderedTools = orderedToolsAsString.compactMap { MainWindow.Tools(rawValue: $0) }
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
      let toolKeys = workspaceToolsDict.keys.compactMap { MainWindow.Tools(rawValue: $0) }
      let missingToolKeys = MainWindow.Tools.all.subtracting(toolKeys)

      var tools = Array(toolKeys).toDict { tool in
        return WorkspaceToolState(dict: workspaceToolsDict[tool.rawValue]!) ?? WorkspaceToolState.defaultTools[tool]!
      }
      missingToolKeys.forEach { missingTool in
        tools[missingTool] = WorkspaceToolState.defaultTools[missingTool]!
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

        Keys.MainWindow.trackpadScrollResistance: self.trackpadScrollResistance,
        Keys.MainWindow.useLiveResize: self.useLiveResize,

        Keys.Appearance.key: self.appearance.dict(),
        Keys.WorkspaceTool.key: self.tools.mapToDict { ($0.rawValue, $1.dict()) },

        Keys.MainWindow.isLeftOptionMeta: self.isLeftOptionMeta,
        Keys.MainWindow.isRightOptionMeta: self.isRightOptionMeta,

        Keys.MainWindow.orderedTools: self.orderedTools.map { $0.rawValue },
        Keys.MainWindow.activeTools: self.activeTools.mapToDict { ($0.rawValue, $1) },

        Keys.PreviewTool.key: self.previewTool.dict(),

        Keys.MainWindow.isShowHidden: self.fileBrowserShowHidden,
        Keys.MainWindow.useInteractiveZsh: self.useInteractiveZsh,
      ]
    }
  }
}

struct WorkspaceToolState: Codable, SerializableState {

  static let `default` = WorkspaceToolState()

  static let defaultTools = [
    MainWindow.Tools.fileBrowser: WorkspaceToolState(location: .left, dimension: 200, open: true),
    MainWindow.Tools.buffersList: WorkspaceToolState(location: .left, dimension: 200, open: false),
    MainWindow.Tools.preview: WorkspaceToolState(location: .right, dimension: 250, open: false),
    MainWindow.Tools.htmlPreview: WorkspaceToolState(location: .right, dimension: 500, open: false),
  ]

  static let orderedDefault = [
    MainWindow.Tools.fileBrowser,
    MainWindow.Tools.buffersList,
    MainWindow.Tools.preview,
    MainWindow.Tools.htmlPreview,
  ]

  enum CodingKeys: String, CodingKey {

    case location = "location"
    case `open` = "is-visible"
    case dimension = "dimension"
  }

  var location = WorkspaceBarLocation.left
  var dimension = CGFloat(200)
  var open = false

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    self.location = try container.decode(forKey: .location, default: WorkspaceToolState.default.location)
    self.dimension = CGFloat(try container.decode(forKey: .dimension, default: WorkspaceToolState.default.dimension))
    self.open = try container.decode(forKey: .open, default: WorkspaceToolState.default.open)
  }

  // Use generated encode(to:)

  private init() {
  }

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

  struct State: Codable, SerializableState {

    static let `default` = State()

    enum CodingKeys: String, CodingKey {

      case forwardSearchAutomatically = "is-forward-search-automatically"
      case reverseSearchAutomatically = "is-reverse-search-automatically"
      case refreshOnWrite = "is-refresh-on-write"
    }

    var isForwardSearchAutomatically = false
    var isReverseSearchAutomatically = false
    var isRefreshOnWrite = true

    private init() {
    }

    init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)

      self.isForwardSearchAutomatically = try container.decode(forKey: .forwardSearchAutomatically,
                                                               default: State.default.isForwardSearchAutomatically)
      self.isReverseSearchAutomatically = try container.decode(forKey: .reverseSearchAutomatically,
                                                               default: State.default.isReverseSearchAutomatically)
      self.isRefreshOnWrite = try container.decode(forKey: .refreshOnWrite, default: State.default.isRefreshOnWrite)
    }

    func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)

      try container.encode(self.isForwardSearchAutomatically, forKey: .forwardSearchAutomatically)
      try container.encode(self.isReverseSearchAutomatically, forKey: .reverseSearchAutomatically)
      try container.encode(self.isRefreshOnWrite, forKey: .refreshOnWrite)
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

fileprivate extension KeyedDecodingContainer where K: CodingKey {

  fileprivate func decode<T: Decodable>(forKey key: K, `default`: T) throws -> T {
    return try self.decodeIfPresent(T.self, forKey: key) ?? `default`
  }
}

/**
 [1] Swift 4.2 has a bug: Only when a `Dictionary` has `String` or `Int` keys, it is encoded to dictionary.
     This means that `Dictionary`s with `enum SomeEnum: String, Codable` keys are encoded as `Array`s.
     The same problem persists also for decoding.
     <https://forums.swift.org/t/json-encoding-decoding-weird-encoding-of-dictionary-with-enum-values/12995>
 */
