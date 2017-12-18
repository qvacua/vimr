/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

class Pref128ToCurrentConverter {

  static func appState(from oldDict: [String: Any]) -> AppState {
    guard let prefData = PrefData(dict: oldDict) else {
      return .default
    }

    var appState = AppState.default

    appState.openNewMainWindowOnLaunch = prefData.general.openNewWindowWhenLaunching
    appState.openNewMainWindowOnReactivation = prefData.general.openNewWindowOnReactivation

    appState.useSnapshotUpdate = prefData.advanced.useSnapshotUpdateChannel

    appState.openQuickly.ignorePatterns = prefData.general.ignorePatterns

    appState.mainWindowTemplate.useInteractiveZsh = prefData.advanced.useInteractiveZsh
    appState.mainWindowTemplate.isAllToolsVisible = prefData.mainWindow.isAllToolsVisible
    appState.mainWindowTemplate.isToolButtonsVisible = prefData.mainWindow.isAllToolsVisible

    appState.mainWindowTemplate.appearance.font = prefData.appearance.editorFont
    appState.mainWindowTemplate.appearance.usesLigatures = prefData.appearance.editorUsesLigatures
    appState.mainWindowTemplate.appearance.linespacing = prefData.appearance.editorLinespacing

    let toolPrefData = prefData.mainWindow.toolPrefDatas

    guard let fileBrowserData = toolPrefData.first(where: { $0.identifier == .fileBrowser }) else {
      return .default
    }

    appState.mainWindowTemplate.tools[.fileBrowser] = WorkspaceToolState(location: fileBrowserData.location,
                                                                         dimension: fileBrowserData.dimension,
                                                                         open: fileBrowserData.isVisible)
    appState.mainWindowTemplate.fileBrowserShowHidden = (fileBrowserData.toolData as! FileBrowserData).isShowHidden


    guard let previewData = toolPrefData.first(where: { $0.identifier == .preview }) else {
      return .default
    }

    guard let markdownData = (previewData.toolData as? PreviewComponent.PrefData)?
      .rendererDatas[MarkdownRenderer.identifier] as? MarkdownRenderer.PrefData
      else {
      return .default
    }

    appState.mainWindowTemplate.tools[.preview] = WorkspaceToolState(location: previewData.location,
                                                                     dimension: previewData.dimension,
                                                                     open: previewData.isVisible)
    appState.mainWindowTemplate.previewTool.isReverseSearchAutomatically = markdownData.isReverseSearchAutomatically
    appState.mainWindowTemplate.previewTool.isForwardSearchAutomatically = markdownData.isForwardSearchAutomatically
    appState.mainWindowTemplate.previewTool.isRefreshOnWrite = markdownData.isRefreshOnWrite

    guard let openedFilesData = toolPrefData.first(where: { $0.identifier == .bufferList }) else {
      return .default
    }

    appState.mainWindowTemplate.tools[.buffersList] = WorkspaceToolState(location: openedFilesData.location,
                                                                         dimension: openedFilesData.dimension,
                                                                         open: openedFilesData.isVisible)

    return appState
  }
}

private protocol StandardPrefData {

  init?(dict: [String: Any])

  func dict() -> [String: Any]
}

private struct EmptyPrefData: StandardPrefData {

  static let `default` = EmptyPrefData()

  init() {}

  init?(dict: [String: Any]) {
    self.init()
  }

  func dict() -> [String: Any] {
    return [:]
  }
}

private struct PrefData: StandardPrefData {

  private static let general = "general"
  private static let appearance = "appearance"
  private static let advanced = "advanced"
  private static let mainWindow = "mainWindow"

  static let `default` = PrefData(general: .default, appearance: .default, advanced: .default, mainWindow: .default)

  var general: GeneralPrefData
  var appearance: AppearancePrefData
  var advanced: AdvancedPrefData

  var mainWindow: MainWindowPrefData

  init(general: GeneralPrefData,
       appearance: AppearancePrefData,
       advanced: AdvancedPrefData,
       mainWindow: MainWindowPrefData) {
    self.general = general
    self.appearance = appearance
    self.advanced = advanced
    self.mainWindow = mainWindow
  }

  init?(dict: [String: Any]) {
    guard let generalDict: [String: Any] = PrefUtils.value(from: dict, for: PrefData.general),
          let appearanceDict: [String: Any] = PrefUtils.value(from: dict, for: PrefData.appearance),
          let advancedDict: [String: Any] = PrefUtils.value(from: dict, for: PrefData.advanced),
          let mainWindowDict: [String: Any] = PrefUtils.value(from: dict, for: PrefData.mainWindow)
      else {
      return nil
    }

    guard let general = GeneralPrefData(dict: generalDict),
          let appearance = AppearancePrefData(dict: appearanceDict),
          let advanced = AdvancedPrefData(dict: advancedDict),
          let mainWindow = MainWindowPrefData(dict: mainWindowDict)
      else {
      return nil
    }

    self.init(general: general, appearance: appearance, advanced: advanced, mainWindow: mainWindow)
  }

  func dict() -> [String: Any] {
    return [
      PrefData.general: self.general.dict(),
      PrefData.appearance: self.appearance.dict(),
      PrefData.advanced: self.advanced.dict(),
      PrefData.mainWindow: self.mainWindow.dict(),
    ]
  }
}

private struct GeneralPrefData: Equatable, StandardPrefData {

  private static let openNewWindowWhenLaunching = "open-new-window-when-launching"
  private static let openNewWindowOnReactivation = "open-new-window-on-reactivation"
  private static let ignorePatterns = "ignore-patterns"

  private static let defaultIgnorePatterns = Set(
    [ "*/.git", "*.o", "*.d", "*.dia" ].map(FileItemIgnorePattern.init)
  )

  static func ==(left: GeneralPrefData, right: GeneralPrefData) -> Bool {
    return left.openNewWindowWhenLaunching == right.openNewWindowWhenLaunching
           && left.openNewWindowOnReactivation == right.openNewWindowOnReactivation
           && left.ignorePatterns == right.ignorePatterns
  }

  static let `default` = GeneralPrefData(openNewWindowWhenLaunching: true,
                                         openNewWindowOnReactivation: true,
                                         ignorePatterns: GeneralPrefData.defaultIgnorePatterns)

  var openNewWindowWhenLaunching: Bool
  var openNewWindowOnReactivation: Bool
  var ignorePatterns: Set<FileItemIgnorePattern>

  init(openNewWindowWhenLaunching: Bool,
       openNewWindowOnReactivation: Bool,
       ignorePatterns: Set<FileItemIgnorePattern>)
  {
    self.openNewWindowWhenLaunching  = openNewWindowWhenLaunching
    self.openNewWindowOnReactivation = openNewWindowOnReactivation
    self.ignorePatterns = ignorePatterns
  }

  init?(dict: [String: Any]) {
    guard let openNewWinWhenLaunching = PrefUtils.bool(from: dict, for: GeneralPrefData.openNewWindowWhenLaunching),
          let openNewWinOnReactivation = PrefUtils.bool(from: dict, for: GeneralPrefData.openNewWindowOnReactivation),
          let ignorePatternsStr = dict[GeneralPrefData.ignorePatterns] as? String
      else {
      return nil
    }

    self.init(openNewWindowWhenLaunching: openNewWinWhenLaunching,
              openNewWindowOnReactivation: openNewWinOnReactivation,
              ignorePatterns: PrefUtils.ignorePatterns(fromString: ignorePatternsStr))
  }

  func dict() -> [String: Any] {
    return [
      GeneralPrefData.openNewWindowWhenLaunching: self.openNewWindowWhenLaunching,
      GeneralPrefData.openNewWindowOnReactivation: self.openNewWindowOnReactivation,
      GeneralPrefData.ignorePatterns: PrefUtils.ignorePatternString(fromSet: self.ignorePatterns),
    ]
  }
}

private struct AppearancePrefData: Equatable, StandardPrefData {

  private static let editorFontName = "editor-font-name"
  private static let editorFontSize = "editor-font-size"
  private static let editorLinespacing = "editor-linespacing"
  private static let editorUsesLigatures = "editor-uses-ligatures"

  static func ==(left: AppearancePrefData, right: AppearancePrefData) -> Bool {
    return left.editorUsesLigatures == right.editorUsesLigatures
           && left.editorFont.isEqual(to: right.editorFont)
           && left.editorLinespacing == right.editorLinespacing
  }

  static let `default` = AppearancePrefData(editorFont: NvimView.defaultFont,
                                            editorLinespacing: NvimView.defaultLinespacing,
                                            editorUsesLigatures: false)

  var editorFont: NSFont
  var editorLinespacing: CGFloat
  var editorUsesLigatures: Bool

  init(editorFont: NSFont, editorLinespacing: CGFloat, editorUsesLigatures: Bool) {
    self.editorFont = editorFont
    self.editorLinespacing = editorLinespacing
    self.editorUsesLigatures = editorUsesLigatures
  }

  init?(dict: [String: Any]) {
    guard let editorFontName = dict[AppearancePrefData.editorFontName] as? String,
          let fEditorFontSize = PrefUtils.float(from: dict, for: AppearancePrefData.editorFontSize),
          let fEditorLinespacing = PrefUtils.float(from: dict, for: AppearancePrefData.editorLinespacing),
          let editorUsesLigatures = PrefUtils.bool(from: dict, for: AppearancePrefData.editorUsesLigatures)
      else {
      return nil
    }

    self.init(editorFont: PrefUtils.saneFont(editorFontName, fontSize: CGFloat(fEditorFontSize)),
              editorLinespacing: CGFloat(fEditorLinespacing),
              editorUsesLigatures: editorUsesLigatures)
  }

  func dict() -> [String: Any] {
    return [
      AppearancePrefData.editorFontName: self.editorFont.fontName,
      AppearancePrefData.editorFontSize: Float(self.editorFont.pointSize),
      AppearancePrefData.editorLinespacing: Float(self.editorLinespacing),
      AppearancePrefData.editorUsesLigatures: self.editorUsesLigatures,
    ]
  }
}

private struct AdvancedPrefData: Equatable, StandardPrefData {

  private static let useSnapshotUpdateChannel = "use-snapshot-update-channel"
  private static let useInteractiveZsh = "use-interactive-zsh"

  static func ==(left: AdvancedPrefData, right: AdvancedPrefData) -> Bool {
    return left.useSnapshotUpdateChannel == right.useSnapshotUpdateChannel
           && left.useInteractiveZsh == right.useInteractiveZsh
  }

  static let `default` = AdvancedPrefData(useSnapshotUpdateChannel: false, useInteractiveZsh: false)

  let useSnapshotUpdateChannel: Bool
  let useInteractiveZsh: Bool

  init(useSnapshotUpdateChannel: Bool, useInteractiveZsh: Bool) {
    self.useSnapshotUpdateChannel = useSnapshotUpdateChannel
    self.useInteractiveZsh = useInteractiveZsh
  }

  init?(dict: [String: Any]) {
    guard let useSnapshot = PrefUtils.bool(from: dict, for: AdvancedPrefData.useSnapshotUpdateChannel),
          let useInteractiveZsh = PrefUtils.bool(from: dict, for: AdvancedPrefData.useInteractiveZsh)
      else {
      return nil
    }

    self.init(useSnapshotUpdateChannel: useSnapshot, useInteractiveZsh: useInteractiveZsh)
  }

  func dict() -> [String: Any] {
    return [
      AdvancedPrefData.useSnapshotUpdateChannel: self.useSnapshotUpdateChannel,
      AdvancedPrefData.useInteractiveZsh: self.useInteractiveZsh,
    ]
  }
}

private enum ToolIdentifier: String {

  case fileBrowser = "com.qvacua.vimr.tool.file-browser"
  case bufferList = "com.qvacua.vimr.tool.buffer-list"
  case preview = "com.qvacua.vimr.tool.preview"

  static let all = [ fileBrowser, bufferList, preview ]
}

private struct MainWindowPrefData: StandardPrefData {

  private static let isAllToolsVisible = "is-all-tools-visible"
  private static let isToolButtonsVisible = "is-tool-buttons-visible"
  private static let toolPrefDatas = "tool-pref-datas"

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
              toolPrefDatas: [toolDatas, missingToolDatas].flatMap { $0 })
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

private struct ToolPrefData: StandardPrefData {

  private static let identifier = "identifier"
  private static let location = "location"
  private static let isVisible = "is-visible"
  private static let dimension = "dimension"
  private static let toolData = "tool-data"

  static let defaults: [ToolIdentifier: ToolPrefData] = [
    .fileBrowser: ToolPrefData(identifier: .fileBrowser,
                               location: .left,
                               isVisible: true,
                               dimension: 200,
                               toolData: FileBrowserData.default),
    .bufferList: ToolPrefData(identifier: .bufferList,
                              location: .left,
                              isVisible: false,
                              dimension: 200,
                              toolData: EmptyPrefData.default),
    .preview: ToolPrefData(identifier: .preview,
                           location: .right,
                           isVisible: false,
                           dimension: 300,
                           toolData: PreviewComponent.PrefData.default),
  ]

  var identifier: ToolIdentifier
  var location: WorkspaceBarLocation
  var isVisible: Bool
  var dimension: CGFloat
  var toolData: StandardPrefData

  init(identifier: ToolIdentifier,
       location: WorkspaceBarLocation,
       isVisible: Bool,
       dimension: CGFloat,
       toolData: StandardPrefData = EmptyPrefData.default) {
    self.identifier = identifier
    self.location = location
    self.isVisible = isVisible
    self.dimension = dimension
    self.toolData = toolData
  }

  func dict() -> [String: Any] {
    return [
      ToolPrefData.identifier: self.identifier.rawValue,
      ToolPrefData.location: self.location.rawValue,
      ToolPrefData.isVisible: self.isVisible,
      ToolPrefData.dimension: Float(self.dimension),
      ToolPrefData.toolData: self.toolData.dict()
    ]
  }

  init?(dict: [String: Any]) {
    guard let identifierRawValue = dict[ToolPrefData.identifier] as? String,
          let locationRawValue = dict[ToolPrefData.location] as? String,
          let isVisible = PrefUtils.bool(from: dict, for: ToolPrefData.isVisible),
          let fDimension = PrefUtils.float(from: dict, for: ToolPrefData.dimension),
          let toolDataDict = PrefUtils.dict(from: dict, for: ToolPrefData.toolData)
      else {
      return nil
    }

    guard let identifier = ToolIdentifier(rawValue: identifierRawValue),
          let location = WorkspaceBarLocation(rawValue: locationRawValue)
      else {
      return nil
    }

    let toolData: StandardPrefData
    switch identifier {
    case .fileBrowser:
      toolData = FileBrowserData(dict: toolDataDict) ?? FileBrowserData.default
    case .preview:
      toolData = PreviewComponent.PrefData(dict: toolDataDict) ?? PreviewComponent.PrefData.default
    default:
      toolData = EmptyPrefData.default
    }

    self.init(identifier: identifier,
              location: location,
              isVisible: isVisible,
              dimension: CGFloat(fDimension),
              toolData: toolData)
  }
}

private class PreviewComponent {

  struct PrefData: StandardPrefData {

    private static let rendererDatas = "renderer-datas"

    private static let rendererPrefDataFns = [
      MarkdownRenderer.identifier: MarkdownRenderer.prefData,
    ]

    private static let rendererDefaultPrefDatas = [
      MarkdownRenderer.identifier: MarkdownRenderer.PrefData.default,
    ]

    static let `default` = PrefData(rendererDatas: PrefData.rendererDefaultPrefDatas)

    var rendererDatas: [String: StandardPrefData]

    init(rendererDatas: [String: StandardPrefData]) {
      self.rendererDatas = rendererDatas
    }

    init?(dict: [String: Any]) {
      guard let rendererDataDict = dict[PrefData.rendererDatas] as? [String: [String: Any]] else {
        return nil
      }

      let storedRendererDatas: [(String, StandardPrefData)] = rendererDataDict.flatMap { (identifier, dict) in
        guard let prefDataFn = PrefData.rendererPrefDataFns[identifier] else {
          return nil
        }

        guard let prefData = prefDataFn(dict) else {
          return nil
        }

        return (identifier, prefData)
      }

      let missingRendererDatas: [(String, StandardPrefData)] = Set(PrefData.rendererDefaultPrefDatas.keys)
        .subtracting(storedRendererDatas.map { $0.0 })
        .flatMap { identifier in
          guard let data = PrefData.rendererDefaultPrefDatas[identifier] else {
            return nil
          }

          return (identifier, data)
        }

      self.init(rendererDatas: tuplesToDict([storedRendererDatas, missingRendererDatas].flatMap { $0 }))
    }

    func dict() -> [String: Any] {
      return [
        PrefData.rendererDatas: self.rendererDatas.mapToDict { (key, value) in (key, value.dict()) }
      ]
    }
  }
}

private class MarkdownRenderer {

  static let identifier = "com.qvacua.vimr.tool.preview.markdown"

  static func prefData(from dict: [String: Any]) -> StandardPrefData? {
    return PrefData(dict: dict)
  }

  struct PrefData: StandardPrefData {

    private static let identifier = "identifier"
    private static let isForwardSearchAutomatically = "is-forward-search-automatically"
    private static let isReverseSearchAutomatically = "is-reverse-search-automatically"
    private static let isRefreshOnWrite = "is-refresh-on-write"

    static let `default` = PrefData(isForwardSearchAutomatically: false,
                                    isReverseSearchAutomatically: false,
                                    isRefreshOnWrite: true)

    var isForwardSearchAutomatically: Bool
    var isReverseSearchAutomatically: Bool
    var isRefreshOnWrite: Bool

    init(isForwardSearchAutomatically: Bool, isReverseSearchAutomatically: Bool, isRefreshOnWrite: Bool) {
      self.isForwardSearchAutomatically = isForwardSearchAutomatically
      self.isReverseSearchAutomatically = isReverseSearchAutomatically
      self.isRefreshOnWrite = isRefreshOnWrite
    }

    init?(dict: [String: Any]) {
      guard PrefUtils.string(from: dict, for: PrefData.identifier) == MarkdownRenderer.identifier else {
        return nil
      }

      guard let isForward = PrefUtils.bool(from: dict, for: PrefData.isForwardSearchAutomatically) else {
        return nil
      }

      guard let isReverse = PrefUtils.bool(from: dict, for: PrefData.isReverseSearchAutomatically) else {
        return nil
      }

      guard let isRefreshOnWrite = PrefUtils.bool(from: dict, for: PrefData.isRefreshOnWrite) else {
        return nil
      }

      self.init(isForwardSearchAutomatically: isForward,
                isReverseSearchAutomatically: isReverse,
                isRefreshOnWrite: isRefreshOnWrite)
    }

    func dict() -> [String: Any] {
      return [
        PrefData.identifier: MarkdownRenderer.identifier,
        PrefData.isForwardSearchAutomatically: self.isForwardSearchAutomatically,
        PrefData.isReverseSearchAutomatically: self.isReverseSearchAutomatically,
        PrefData.isRefreshOnWrite: self.isRefreshOnWrite,
      ]
    }
  }
}

private struct FileBrowserData: StandardPrefData {

  private static let isShowHidden = "is-show-hidden"

  static let `default` = FileBrowserData(isShowHidden: false)

  var isShowHidden: Bool

  init(isShowHidden: Bool) {
    self.isShowHidden = isShowHidden
  }

  init?(dict: [String: Any]) {
    guard let isShowHidden = PrefUtils.bool(from: dict, for: FileBrowserData.isShowHidden) else {
      return nil
    }

    self.init(isShowHidden: isShowHidden)
  }

  func dict() -> [String: Any] {
    return [
      FileBrowserData.isShowHidden: self.isShowHidden
    ]
  }
}
