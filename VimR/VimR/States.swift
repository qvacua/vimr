/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import Commons
import NvimView
import RxSwift
import Workspace

struct AppState: Codable {
  enum OpenFilesFromApplicationsAction: String, Codable, CaseIterable {
    case inNewWindow
    case inCurrentWindow
  }

  enum AfterLastWindowAction: String, Codable {
    case doNothing = "do-nothing"
    case hide
    case quit
  }

  static let `default` = AppState()

  enum CodingKeys: String, CodingKey {
    case openNewMainWindowOnLaunch = "open-new-window-when-launching"
    case openNewMainWindowOnReactivation = "open-new-window-on-reactivation"
    case openFilesFromApplicationsAction = "open-files-from-applications-action"
    case afterLastWindowAction = "after-last-window-action"
    case activateAsciiImInNormalMode = "activate-ascii-im-in-normal-mode"
    case useSnapshotUpdate = "use-snapshot-update-channel"

    case openQuickly = "open-quickly"
    case mainWindowTemplate = "main-window"
  }

  var openNewMainWindowOnLaunch = true
  var openNewMainWindowOnReactivation = true

  var openFilesFromApplicationsAction = OpenFilesFromApplicationsAction.inNewWindow
  var afterLastWindowAction = AfterLastWindowAction.doNothing

  var activateAsciiImInNormalMode = true

  var useSnapshotUpdate = false

  var preferencesOpen = Marked(false)

  var mainWindowTemplate = MainWindow.State.default
  var currentMainWindowUuid: UUID?

  var mainWindows: [UUID: MainWindow.State] = [:]
  var currentMainWindow: MainWindow.State? {
    guard let uuid = self.currentMainWindowUuid else { return nil }
    return self.mainWindows[uuid]
  }

  var openQuickly = OpenQuicklyWindow.State.default

  var quit = false

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    self.openNewMainWindowOnLaunch = try container.decode(
      forKey: .openNewMainWindowOnLaunch,
      default: AppState.default.openNewMainWindowOnLaunch
    )
    self.openNewMainWindowOnReactivation = try container.decode(
      forKey: .openNewMainWindowOnReactivation,
      default: AppState.default.openNewMainWindowOnReactivation
    )
    self.openFilesFromApplicationsAction = try container.decode(
      forKey: .openFilesFromApplicationsAction,
      default: .inNewWindow
    )
    self.afterLastWindowAction = try container.decode(
      forKey: .afterLastWindowAction,
      default: .doNothing
    )
    self.activateAsciiImInNormalMode = try container.decode(
      forKey: .activateAsciiImInNormalMode,
      default: true
    )
    self.useSnapshotUpdate = try container.decode(
      forKey: .useSnapshotUpdate,
      default: AppState.default.useSnapshotUpdate
    )

    self.openQuickly = try container.decode(
      forKey: .openQuickly,
      default: OpenQuicklyWindow.State.default
    )
    self.mainWindowTemplate = try container.decode(
      forKey: .mainWindowTemplate,
      default: MainWindow.State.default
    )
  }

  // Use generated encode(to:)

  private init() {}
}

extension OpenQuicklyWindow {
  struct State: Codable {
    static let `default` = State()

    enum CodingKeys: String, CodingKey {
      case defaultUsesVcsIgnore = "default-uses-vcs-ignores"
    }

    var defaultUsesVcsIgnores = true
    var open = false

    init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)

      self.defaultUsesVcsIgnores = try container.decode(
        forKey: .defaultUsesVcsIgnore,
        default: OpenQuicklyWindow.State.default.defaultUsesVcsIgnores
      )
    }

    func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(self.defaultUsesVcsIgnores, forKey: .defaultUsesVcsIgnore)
    }

    private init() {}
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

  init(
    status: Status = .none,
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

struct AppearanceState: Codable {
  static let `default` = AppearanceState()

  enum CodingKeys: String, CodingKey {
    case usesCustomTab = "uses-custom-tab"
    case usesTheme = "uses-theme"
    case showsFileIcon = "shows-file-icon"
    case editorFontName = "editor-font-name"
    case editorFontSize = "editor-font-size"
    case editorLinespacing = "editor-linespacing"
    case editorCharacterspacing = "editor-characterspacing"
    case editorUsesLigatures = "editor-uses-ligatures"
    case editorFontSmoothing = "editor-font-smoothing"
  }

  var font = NSFont.userFixedPitchFont(ofSize: 13)!
  var linespacing: CGFloat = 1
  var characterspacing: CGFloat = 1
  var usesLigatures = true
  var fontSmoothing = FontSmoothing.systemSetting

  var usesCustomTab = true
  var usesTheme = true
  var showsFileIcon = true
  var theme = Marked(Theme.default)

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    if let fontName = try container.decodeIfPresent(String.self, forKey: .editorFontName),
       let fontSize = try container.decodeIfPresent(Double.self, forKey: .editorFontSize),
       let font = NSFont(name: fontName, size: fontSize)
    {
      self.font = font
    } else {
      self.font = NvimView.defaultFont
    }

    self
      .linespacing = try (container.decodeIfPresent(Double.self, forKey: .editorLinespacing) ?? 1.0)
    self
      .characterspacing = try (
        container
          .decodeIfPresent(Double.self, forKey: .editorCharacterspacing) ?? 1.0
      )
    self.usesLigatures = try container
      .decodeIfPresent(Bool.self, forKey: .editorUsesLigatures) ?? true
    self.fontSmoothing = try container.decodeIfPresent(
      FontSmoothing.self,
      forKey: .editorFontSmoothing
    ) ?? .systemSetting

    self.usesTheme = try container.decodeIfPresent(Bool.self, forKey: .usesTheme) ?? true
    self.usesCustomTab = try container.decodeIfPresent(Bool.self, forKey: .usesCustomTab) ?? true
    self.showsFileIcon = try container.decodeIfPresent(Bool.self, forKey: .showsFileIcon) ?? true
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    try container.encode(self.usesCustomTab, forKey: .usesCustomTab)
    try container.encode(self.usesTheme, forKey: .usesTheme)
    try container.encode(self.showsFileIcon, forKey: .showsFileIcon)
    try container.encode(self.font.fontName, forKey: .editorFontName)
    try container.encode(self.font.pointSize, forKey: .editorFontSize)
    try container.encode(self.linespacing, forKey: .editorLinespacing)
    try container.encode(self.characterspacing, forKey: .editorCharacterspacing)
    try container.encode(self.fontSmoothing, forKey: .editorFontSmoothing)
    try container.encode(self.usesLigatures, forKey: .editorUsesLigatures)
  }

  private init() {}
}

extension MainWindow {
  struct State: Codable {
    static let `default` = State(
      isAllToolsVisible: true,
      isToolButtonsVisible: true,
      nvimBinary: ""
    )

    static let defaultTools: [MainWindow.Tools: WorkspaceToolState] = [
      .fileBrowser: WorkspaceToolState(location: .left, dimension: 200, open: true),
      .buffersList: WorkspaceToolState(location: .left, dimension: 200, open: false),
      .preview: WorkspaceToolState(location: .right, dimension: 250, open: false),
      .htmlPreview: WorkspaceToolState(location: .right, dimension: 500, open: false),
    ]

    static let orderedDefault: [MainWindow.Tools] = [.fileBrowser, .buffersList, .preview,
                                                     .htmlPreview]

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

    var tools = MainWindow.State.defaultTools
    var orderedTools = MainWindow.State.orderedDefault

    var preview = PreviewState.default
    var htmlPreview = HtmlPreviewState.default

    var previewTool = MarkdownTool.State.default

    var fileBrowserShowHidden = false

    var isTemporarySession = false

    var customMarkdownProcessor = ""

    // neovim
    var uuid = UUID()
    var currentBuffer: NvimView.Buffer?
    var buffers = [NvimView.Buffer]()
    var cwd = FileUtils.userHomeUrl

    var isDirty = false

    var appearance = AppearanceState.default
    var useInteractiveZsh = false
    var nvimBinary: String = ""
    var nvimArgs: [String]?
    var cliPipePath: String?
    var envDict: [String: String]?

    var usesVcsIgnores = true

    var isLeftOptionMeta = false
    var isRightOptionMeta = false

    // to be cleaned
    var urlsToOpen = [URL: OpenMode]()
    var currentBufferToSet: NvimView.Buffer?
    var cwdToSet: URL?
    var viewToBeFocused: FocusableView? = FocusableView.neoVimView

    init(isAllToolsVisible: Bool, isToolButtonsVisible: Bool, nvimBinary: String) {
      self.isAllToolsVisible = isAllToolsVisible
      self.isToolButtonsVisible = isToolButtonsVisible
      self.nvimBinary = nvimBinary
    }

    enum CodingKeys: String, CodingKey {
      case allToolsVisible = "is-all-tools-visible"
      case toolButtonsVisible = "is-tool-buttons-visible"
      case orderedTools = "ordered-tools"
      case activeTools = "active-tools"
      case frame

      case isLeftOptionMeta = "is-left-option-meta"
      case isRightOptionMeta = "is-right-option-meta"

      case useInteractiveZsh = "use-interactive-zsh"
      case nvimBinary = "nvim-binary"

      case useLiveResize = "use-live-resize"
      case isShowHidden = "is-show-hidden"
      case customMarkdownProcessor = "custom-markdown-processor"

      case appearance
      case workspaceTools = "workspace-tool"
      case previewTool = "preview-tool"
    }

    init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)

      self.isLeftOptionMeta = try container.decode(
        forKey: .isLeftOptionMeta,
        default: State.default.isLeftOptionMeta
      )
      self.isRightOptionMeta = try container.decode(
        forKey: .isRightOptionMeta,
        default: State.default.isRightOptionMeta
      )
      self.useInteractiveZsh = try container.decode(
        forKey: .useInteractiveZsh,
        default: State.default.useInteractiveZsh
      )
      self.nvimBinary = try container.decodeIfPresent(String.self, forKey: .nvimBinary) ?? State
        .default.nvimBinary

      if let frameRawValue = try container.decodeIfPresent(String.self, forKey: .frame) {
        self.frame = NSRectFromString(frameRawValue)
      } else {
        self.frame = CGRect(x: 100, y: 100, width: 600, height: 400)
      }

      self.isAllToolsVisible = try container.decode(
        forKey: .allToolsVisible,
        default: State.default.isAllToolsVisible
      )
      self.isToolButtonsVisible = try container.decode(
        forKey: .toolButtonsVisible,
        default: State.default.isToolButtonsVisible
      )

      self.customMarkdownProcessor = try container.decode(
        forKey: .customMarkdownProcessor,
        default: State.default.customMarkdownProcessor
      )

      self.appearance = try container.decode(forKey: .appearance, default: State.default.appearance)

      self.orderedTools = try container.decode(
        forKey: .orderedTools,
        default: State.default.orderedTools
      )
      let missingOrderedTools = MainWindow.Tools.all.subtracting(self.orderedTools)
      self.orderedTools.append(contentsOf: missingOrderedTools)

      // See [1]
      let rawActiveTools: [String: Bool] = try container.decode(forKey: .activeTools, default: [:])
      self.activeTools = rawActiveTools.flatMapToDict { key, value in
        guard let toolId = MainWindow.Tools(rawValue: key) else {
          return nil
        }

        return (toolId, value)
      }
      let missingActiveTools = MainWindow.Tools.all.subtracting(self.activeTools.keys)
      missingActiveTools.forEach { self.activeTools[$0] = true }

      let rawTools: [String: WorkspaceToolState] = try container
        .decode(forKey: .workspaceTools, default: [:])
      self.tools = rawTools.flatMapToDict { key, value in
        guard let tool = MainWindow.Tools(rawValue: key) else {
          return nil
        }

        return (tool, value)
      }
      let missingTools = MainWindow.Tools.all.subtracting(self.tools.keys)
      for missingTool in missingTools {
        self.tools[missingTool] = MainWindow.State.defaultTools[missingTool]!
      }

      self.previewTool = try container.decode(
        forKey: .previewTool,
        default: State.default.previewTool
      )
      self.fileBrowserShowHidden = try container.decode(
        forKey: .isShowHidden,
        default: State.default
          .fileBrowserShowHidden
      )
    }

    func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)

      try container.encode(self.isAllToolsVisible, forKey: .allToolsVisible)
      try container.encode(self.isToolButtonsVisible, forKey: .toolButtonsVisible)
      try container.encode(NSStringFromRect(self.frame), forKey: .frame)
      try container.encode(self.customMarkdownProcessor, forKey: .customMarkdownProcessor)
      try container.encode(self.isLeftOptionMeta, forKey: .isLeftOptionMeta)
      try container.encode(self.isRightOptionMeta, forKey: .isRightOptionMeta)
      try container.encode(self.useInteractiveZsh, forKey: .useInteractiveZsh)
      try container.encode(self.nvimBinary, forKey: .nvimBinary)
      try container.encode(self.fileBrowserShowHidden, forKey: .isShowHidden)

      // See [1]
      try container.encode(
        Dictionary(uniqueKeysWithValues: self.tools.map { k, v in (k.rawValue, v) }),
        forKey: .workspaceTools
      )
      try container.encode(
        Dictionary(uniqueKeysWithValues: self.activeTools.map { k, v in (k.rawValue, v) }),
        forKey: .activeTools
      )

      try container.encode(self.appearance, forKey: .appearance)
      try container.encode(self.orderedTools, forKey: .orderedTools)
      try container.encode(self.previewTool, forKey: .previewTool)
    }
  }
}

struct WorkspaceToolState: Codable {
  static let `default` = WorkspaceToolState()

  enum CodingKeys: String, CodingKey {
    case location
    case open = "is-visible"
    case dimension
  }

  var location = WorkspaceBarLocation.left
  var dimension = 200.0
  var open = false

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    self.location = try container.decode(
      forKey: .location,
      default: WorkspaceToolState.default.location
    )
    self.dimension = try container.decode(
      forKey: .dimension,
      default: WorkspaceToolState.default.dimension
    )
    self.open = try container.decode(
      forKey: .open,
      default: WorkspaceToolState.default.open
    )
  }

  // Use generated encode(to:)

  private init() {}

  init(location: WorkspaceBarLocation, dimension: CGFloat, open: Bool) {
    self.location = location
    self.dimension = dimension
    self.open = open
  }
}

extension MarkdownTool {
  struct State: Codable {
    static let `default` = State()

    enum CodingKeys: String, CodingKey {
      case forwardSearchAutomatically = "is-forward-search-automatically"
      case reverseSearchAutomatically = "is-reverse-search-automatically"
      case refreshOnWrite = "is-refresh-on-write"
    }

    var isForwardSearchAutomatically = false
    var isReverseSearchAutomatically = false
    var isRefreshOnWrite = true

    private init() {}

    init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)

      self.isForwardSearchAutomatically = try container.decode(
        forKey: .forwardSearchAutomatically,
        default: State.default
          .isForwardSearchAutomatically
      )
      self.isReverseSearchAutomatically = try container.decode(
        forKey: .reverseSearchAutomatically,
        default: State.default
          .isReverseSearchAutomatically
      )
      self.isRefreshOnWrite = try container.decode(
        forKey: .refreshOnWrite,
        default: State.default.isRefreshOnWrite
      )
    }

    func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)

      try container.encode(self.isForwardSearchAutomatically, forKey: .forwardSearchAutomatically)
      try container.encode(self.isReverseSearchAutomatically, forKey: .reverseSearchAutomatically)
      try container.encode(self.isRefreshOnWrite, forKey: .refreshOnWrite)
    }
  }
}

private extension KeyedDecodingContainer where K: CodingKey {
  func decode<T: Decodable>(forKey key: K, default: T) throws -> T {
    try self.decodeIfPresent(T.self, forKey: key) ?? `default`
  }
}

/**
 [1] Swift 4.2 has a bug: Only when a `Dictionary` has `String` or `Int` keys, it is encoded to dictionary.
     This means that `Dictionary`s with `enum SomeEnum: String, Codable` keys are encoded as `Array`s.
     The same problem persists also for decoding.
     <https://forums.swift.org/t/json-encoding-decoding-weird-encoding-of-dictionary-with-enum-values/12995>
 */
