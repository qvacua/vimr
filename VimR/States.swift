//
// Created by Tae Won Ha on 1/13/17.
// Copyright (c) 2017 Tae Won Ha. All rights reserved.
//

import Foundation
import RxSwift

typealias ActionEmitter = Emitter<Any>

class Emitter<T> {

  let observable: Observable<T>

  init() {
    self.observable = self.subject.asObservable().observeOn(scheduler)
  }

  func emit(_ action: T) {
    self.subject.onNext(action)
  }

  deinit {
    self.subject.onCompleted()
  }

  fileprivate let scheduler = SerialDispatchQueueScheduler(qos: .userInitiated)
  fileprivate let subject = PublishSubject<T>()
}

class StateActionPair<S, A> {

  let state: S
  let action: A

  init(state: S, action: A) {
    self.state = state
    self.action = action
  }
}

class UuidAction<A>: CustomStringConvertible {

  let uuid: String
  let payload: A

  var description: String {
    return "UuidAction(uuid: \(uuid), payload: \(String(reflecting: payload)))"
  }

  init(uuid: String, action: A) {
    self.uuid = uuid
    self.payload = action
  }
}

class UuidState<S>: CustomStringConvertible {

  let uuid: String
  let payload: S

  var description: String {
    return "UuidAction(uuid: \(uuid), payload: \(String(reflecting: payload)))"
  }

  init(uuid: String, state: S) {
    self.uuid = uuid
    self.payload = state
  }
}

protocol Transformer {

  associatedtype Pair

  func transform(_ source: Observable<Pair>) -> Observable<Pair>
}

protocol PersistableState {

  init?(dict: [String: Any])

  func dict() -> [String: Any]
}

struct MainWindowStates: PersistableState {

  var last: MainWindow.State

  var current: [String: MainWindow.State]

  init(last: MainWindow.State) {
    self.last = last
    self.current = [:]
  }

  init?(dict: [String: Any]) {
    guard let lastDict: [String: Any] = PrefUtils.value(from: dict, for: MainWindowStates.last) else {
      return nil
    }

    guard let last = MainWindow.State(dict: lastDict) else {
      return nil
    }

    self.init(last: last)
  }

  func dict() -> [String: Any] {
    return [
      MainWindowStates.last: self.last.dict(),
    ]
  }

  fileprivate static let last = "last"
}

struct AppState: PersistableState {

  static let `default` = AppState(general: GeneralPrefState.default,
                                  appearance: AppearancePrefState.default,
                                  advanced: AdvancedPrefState.default,
                                  mainWindow: MainWindow.State.default)

  var general: GeneralPrefState
  var appearance: AppearancePrefState
  var advanced: AdvancedPrefState

  var mainWindows: MainWindowStates

  init(general: GeneralPrefState,
       appearance: AppearancePrefState,
       advanced: AdvancedPrefState,
       mainWindow: MainWindow.State) {
    self.general = general
    self.appearance = appearance
    self.advanced = advanced
    self.mainWindows = MainWindowStates(last: mainWindow)
  }

  init?(dict: [String: Any]) {
    guard let generalDict: [String: Any] = PrefUtils.value(from: dict, for: AppState.general),
          let appearanceDict: [String: Any] = PrefUtils.value(from: dict, for: AppState.appearance),
          let advancedDict: [String: Any] = PrefUtils.value(from: dict, for: AppState.advanced),
          let mainWindowDict: [String: Any] = PrefUtils.value(from: dict, for: AppState.mainWindow)
      else {
      return nil
    }

    guard let general = GeneralPrefState(dict: generalDict),
          let appearance = AppearancePrefState(dict: appearanceDict),
          let advanced = AdvancedPrefState(dict: advancedDict),
          let mainWindow = MainWindow.State(dict: mainWindowDict)
      else {
      return nil
    }

    self.init(general: general, appearance: appearance, advanced: advanced, mainWindow: mainWindow)
  }

  func dict() -> [String: Any] {
    return [
      AppState.general: self.general.dict(),
      AppState.appearance: self.appearance.dict(),
      AppState.advanced: self.advanced.dict(),
      AppState.mainWindow: self.mainWindows.dict(),
    ]
  }

  fileprivate static let general = "general"
  fileprivate static let appearance = "appearance"
  fileprivate static let advanced = "advanced"
  fileprivate static let mainWindow = "mainWindow"
}

struct GeneralPrefState: Equatable, PersistableState {

  static func ==(left: GeneralPrefState, right: GeneralPrefState) -> Bool {
    return left.openNewWindowWhenLaunching == right.openNewWindowWhenLaunching
           && left.openNewWindowOnReactivation == right.openNewWindowOnReactivation
           && left.ignorePatterns == right.ignorePatterns
  }

  static let `default` = GeneralPrefState(openNewWindowWhenLaunching: true,
                                          openNewWindowOnReactivation: true,
                                          ignorePatterns: GeneralPrefState.defaultIgnorePatterns)

  var openNewWindowWhenLaunching: Bool
  var openNewWindowOnReactivation: Bool
  var ignorePatterns: Set<FileItemIgnorePattern>

  init(openNewWindowWhenLaunching: Bool,
       openNewWindowOnReactivation: Bool,
       ignorePatterns: Set<FileItemIgnorePattern>) {
    self.openNewWindowWhenLaunching = openNewWindowWhenLaunching
    self.openNewWindowOnReactivation = openNewWindowOnReactivation
    self.ignorePatterns = ignorePatterns
  }

  init?(dict: [String: Any]) {
    guard let openNewWinWhenLaunching = PrefUtils.bool(from: dict, for: GeneralPrefState.openNewWindowWhenLaunching),
          let openNewWinOnReactivation = PrefUtils.bool(from: dict, for: GeneralPrefState.openNewWindowOnReactivation),
          let ignorePatternsStr = dict[GeneralPrefState.ignorePatterns] as? String
      else {
      return nil
    }

    self.init(openNewWindowWhenLaunching: openNewWinWhenLaunching,
              openNewWindowOnReactivation: openNewWinOnReactivation,
              ignorePatterns: PrefUtils.ignorePatterns(fromString: ignorePatternsStr))
  }

  func dict() -> [String: Any] {
    return [
      GeneralPrefState.openNewWindowWhenLaunching: self.openNewWindowWhenLaunching,
      GeneralPrefState.openNewWindowOnReactivation: self.openNewWindowOnReactivation,
      GeneralPrefState.ignorePatterns: PrefUtils.ignorePatternString(fromSet: self.ignorePatterns),
    ]
  }


  fileprivate static let defaultIgnorePatterns = Set(
    ["*/.git", "*.o", "*.d", "*.dia"].map(FileItemIgnorePattern.init)
  )
  fileprivate static let openNewWindowWhenLaunching = "open-new-window-when-launching"
  fileprivate static let openNewWindowOnReactivation = "open-new-window-on-reactivation"
  fileprivate static let ignorePatterns = "ignore-patterns"
}

struct AppearancePrefState: Equatable, PersistableState {

  static func ==(left: AppearancePrefState, right: AppearancePrefState) -> Bool {
    return left.editorUsesLigatures == right.editorUsesLigatures
           && left.editorFont.isEqual(to: right.editorFont)
           && left.editorLinespacing == right.editorLinespacing
  }

  static let `default` = AppearancePrefState(editorFont: NeoVimView.defaultFont,
                                             editorLinespacing: NeoVimView.defaultLinespacing,
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
    guard let editorFontName = dict[AppearancePrefState.editorFontName] as? String,
          let fEditorFontSize = PrefUtils.float(from: dict, for: AppearancePrefState.editorFontSize),
          let fEditorLinespacing = PrefUtils.float(from: dict, for: AppearancePrefState.editorLinespacing),
          let editorUsesLigatures = PrefUtils.bool(from: dict, for: AppearancePrefState.editorUsesLigatures)
      else {
      return nil
    }

    self.init(editorFont: PrefUtils.saneFont(editorFontName, fontSize: CGFloat(fEditorFontSize)),
              editorLinespacing: CGFloat(fEditorLinespacing),
              editorUsesLigatures: editorUsesLigatures)
  }

  func dict() -> [String: Any] {
    return [
      AppearancePrefState.editorFontName: self.editorFont.fontName,
      AppearancePrefState.editorFontSize: Float(self.editorFont.pointSize),
      AppearancePrefState.editorLinespacing: Float(self.editorLinespacing),
      AppearancePrefState.editorUsesLigatures: self.editorUsesLigatures,
    ]
  }

  fileprivate static let editorFontName = "editor-font-name"
  fileprivate static let editorFontSize = "editor-font-size"
  fileprivate static let editorLinespacing = "editor-linespacing"
  fileprivate static let editorUsesLigatures = "editor-uses-ligatures"
}

struct AdvancedPrefState: Equatable, PersistableState {

  static func ==(left: AdvancedPrefState, right: AdvancedPrefState) -> Bool {
    return left.useSnapshotUpdateChannel == right.useSnapshotUpdateChannel
           && left.useInteractiveZsh == right.useInteractiveZsh
  }

  static let `default` = AdvancedPrefState(useSnapshotUpdateChannel: false, useInteractiveZsh: false)

  let useSnapshotUpdateChannel: Bool
  let useInteractiveZsh: Bool

  init(useSnapshotUpdateChannel: Bool, useInteractiveZsh: Bool) {
    self.useSnapshotUpdateChannel = useSnapshotUpdateChannel
    self.useInteractiveZsh = useInteractiveZsh
  }

  init?(dict: [String: Any]) {
    guard let useSnapshot = PrefUtils.bool(from: dict, for: AdvancedPrefState.useSnapshotUpdateChannel),
          let useInteractiveZsh = PrefUtils.bool(from: dict, for: AdvancedPrefState.useInteractiveZsh)
      else {
      return nil
    }

    self.init(useSnapshotUpdateChannel: useSnapshot, useInteractiveZsh: useInteractiveZsh)
  }

  func dict() -> [String: Any] {
    return [
      AdvancedPrefState.useSnapshotUpdateChannel: self.useSnapshotUpdateChannel,
      AdvancedPrefState.useInteractiveZsh: self.useInteractiveZsh,
    ]
  }

  fileprivate static let useSnapshotUpdateChannel = "use-snapshot-update-channel"
  fileprivate static let useInteractiveZsh = "use-interactive-zsh"
}

extension MainWindow {

  struct State: PersistableState {

    static let `default` = State(isAllToolsVisible: true,
                                 isToolButtonsVisible: true)

    var isAllToolsVisible = true
    var isToolButtonsVisible = true

    // transient
    var uuid = UUID().uuidString
    var buffers = [NeoVimBuffer]()
    var cwd = FileUtils.userHomeUrl

    var isDirty = false

    var font = NSFont.userFixedPitchFont(ofSize: 13)!
    var linespacing: CGFloat = 1
    var isUseLigatures = false
    var isUseInteractiveZsh = false

    // transient^2
    var urlsToOpen = [URL: OpenMode]()

    init(isAllToolsVisible: Bool, isToolButtonsVisible: Bool) {
      self.isAllToolsVisible = isAllToolsVisible
      self.isToolButtonsVisible = isToolButtonsVisible
    }

    init?(dict: [String: Any]) {
      guard let isAllToolsVisible = PrefUtils.bool(from: dict, for: State.isAllToolsVisible),
            let isToolButtonsVisible = PrefUtils.bool(from: dict, for: State.isToolButtonsVisible)
        else {
        return nil
      }

      self.init(isAllToolsVisible: isAllToolsVisible, isToolButtonsVisible: isToolButtonsVisible)
    }

    func dict() -> [String: Any] {
      return [
        State.isAllToolsVisible: self.isAllToolsVisible,
        State.isToolButtonsVisible: self.isToolButtonsVisible,
      ]
    }

    fileprivate static let isAllToolsVisible = "is-all-tools-visible"
    fileprivate static let isToolButtonsVisible = "is-tool-buttons-visible"
  }
}

//struct ToolsState: PersistableState {
//
//  static let `default` = ToolsState(fileBrowser: FileBrowserComponent.State.default,
//                                    bufferList: BufferListComponent.State.default,
//                                    preview: PreviewComponent.State.default)
//
//  var fileBrowser: FileBrowserComponent.State
//  var bufferList: BufferListComponent.State
//  var preview: PreviewComponent.State
//
//  init(fileBrowser: FileBrowserComponent.State,
//       bufferList: BufferListComponent.State,
//       preview: PreviewComponent.State) {
//    self.fileBrowser = fileBrowser
//    self.bufferList = bufferList
//    self.preview = preview
//  }
//
//  init?(dict: [String: Any]) {
//    guard let fileBrowserDict = dict[FileBrowserComponent.identifier] as? [String: Any],
//          let bufferListDict = dict[BufferListComponent.identifier] as? [String: Any],
//          let previewDict = dict[PreviewComponent.identifier] as? [String: Any]
//      else {
//      return nil
//    }
//
//    guard let fileBrowser = FileBrowserComponent.State(dict: fileBrowserDict),
//          let bufferList = BufferListComponent.State(dict: bufferListDict),
//          let preview = PreviewComponent.State(dict: previewDict)
//      else {
//      return nil
//    }
//
//    self.init(fileBrowser: fileBrowser, bufferList: bufferList, preview: preview)
//  }
//
//  func dict() -> [String: Any] {
//    return [
//      FileBrowserComponent.identifier: self.fileBrowser.dict(),
//      BufferListComponent.identifier: self.bufferList.dict(),
//      PreviewComponent.identifier: self.preview.dict(),
//    ]
//  }
//}
//
//struct ToolState: PersistableState {
//
//  static let identifier = "tool-state"
//  static let `default` = ToolState(location: .left, isVisible: false, dimension: 200)
//
//  var location: WorkspaceBarLocation
//  var isVisible: Bool
//  var dimension: CGFloat
//
//  init(location: WorkspaceBarLocation, isVisible: Bool, dimension: CGFloat) {
//    self.location = location
//    self.isVisible = isVisible
//    self.dimension = dimension
//  }
//
//  init?(dict: [String: Any]) {
//    guard let locationRawValue = dict[ToolState.location] as? String,
//          let isVisible = PrefUtils.bool(from: dict, for: ToolState.isVisible),
//          let fDimension = PrefUtils.float(from: dict, for: ToolState.dimension)
//      else {
//      return nil
//    }
//
//    guard let location = PrefUtils.location(from: locationRawValue) else {
//      return nil
//    }
//
//    self.init(location: location, isVisible: isVisible, dimension: CGFloat(fDimension))
//  }
//
//  func dict() -> [String: Any] {
//    return [
//      ToolState.location: PrefUtils.locationAsString(for: self.location),
//      ToolState.isVisible: self.isVisible,
//      ToolState.dimension: Float(self.dimension),
//    ]
//  }
//
//  fileprivate static let location = "location"
//  fileprivate static let isVisible = "is-visible"
//  fileprivate static let dimension = "dimension"
//}
//
//extension FileBrowserComponent {
//
//  struct State: PersistableState {
//
//    static let `default` = State(isShowHidden: false, toolState: ToolState.default)
//
//    var isShowHidden: Bool
//    var toolState: ToolState
//
//    init(isShowHidden: Bool, toolState: ToolState) {
//      self.isShowHidden = isShowHidden
//      self.toolState = toolState
//    }
//
//    init?(dict: [String: Any]) {
//      guard let isShowHidden = PrefUtils.bool(from: dict, for: State.isShowHidden),
//            let toolStateDict = dict[ToolState.identifier] as? [String: Any]
//        else {
//        return nil
//      }
//
//      guard let toolState = ToolState(dict: toolStateDict) else {
//        return nil
//      }
//
//      self.init(isShowHidden: isShowHidden, toolState: toolState)
//    }
//
//    func dict() -> [String: Any] {
//      return [
//        ToolState.identifier: self.toolState,
//        State.isShowHidden: self.isShowHidden,
//      ]
//    }
//
//    fileprivate static let isShowHidden = "is-show-hidden"
//  }
//}
//
//extension BufferListComponent {
//
//  struct State: PersistableState {
//
//    static let `default` = State(toolState: ToolState.default)
//
//    var toolState: ToolState
//
//    init(toolState: ToolState) {
//      self.toolState = toolState
//    }
//
//    init?(dict: [String: Any]) {
//      guard let toolStateDict = dict[ToolState.identifier] as? [String: Any] else {
//        return nil
//      }
//
//      guard let toolState = ToolState(dict: toolStateDict) else {
//        return nil
//      }
//
//      self.init(toolState: toolState)
//    }
//
//    func dict() -> [String: Any] {
//      return [
//        ToolState.identifier: self.toolState,
//      ]
//    }
//  }
//}
//
//extension PreviewComponent {
//
//  struct State: PersistableState {
//
//    static let `default` = State(markdown: MarkdownRenderer.State.default, toolState: ToolState.default)
//
//    var markdown: MarkdownRenderer.State
//    var toolState: ToolState
//
//    init(markdown: MarkdownRenderer.State, toolState: ToolState) {
//      self.markdown = markdown
//      self.toolState = toolState
//    }
//
//    init?(dict: [String: Any]) {
//      guard let markdownDict = dict[MarkdownRenderer.identifier] as? [String: Any],
//            let toolStateDict = dict[ToolState.identifier] as? [String: Any]
//        else {
//        return nil
//      }
//
//      guard let markdown = MarkdownRenderer.State(dict: markdownDict) else {
//        return nil
//      }
//
//      guard let toolState = ToolState(dict: toolStateDict) else {
//        return nil
//      }
//
//      self.init(markdown: markdown, toolState: toolState)
//    }
//
//    func dict() -> [String: Any] {
//      return [
//        ToolState.identifier: self.toolState,
//        MarkdownRenderer.identifier: self.markdown.dict(),
//      ]
//    }
//  }
//}
//
//extension MarkdownRenderer {
//
//  struct State: PersistableState {
//
//    static let `default` = State(isForwardSearchAutomatically: false,
//                                 isReverseSearchAutomatically: false,
//                                 isRefreshOnWrite: true,
//                                 renderTime: Date.distantPast)
//
//    var isForwardSearchAutomatically: Bool
//    var isReverseSearchAutomatically: Bool
//    var isRefreshOnWrite: Bool
//
//    // transient
//    var renderTime: Date
//
//    init(isForwardSearchAutomatically: Bool,
//         isReverseSearchAutomatically: Bool,
//         isRefreshOnWrite: Bool,
//         renderTime: Date) {
//      self.isForwardSearchAutomatically = isForwardSearchAutomatically
//      self.isReverseSearchAutomatically = isReverseSearchAutomatically
//      self.isRefreshOnWrite = isRefreshOnWrite
//      self.renderTime = renderTime
//    }
//
//    init?(dict: [String: Any]) {
//      guard let isForward = PrefUtils.bool(from: dict, for: State.isForwardSearchAutomatically) else {
//        return nil
//      }
//
//      guard let isReverse = PrefUtils.bool(from: dict, for: State.isReverseSearchAutomatically) else {
//        return nil
//      }
//
//      guard let isRefreshOnWrite = PrefUtils.bool(from: dict, for: State.isRefreshOnWrite) else {
//        return nil
//      }
//
//      self.init(isForwardSearchAutomatically: isForward,
//                isReverseSearchAutomatically: isReverse,
//                isRefreshOnWrite: isRefreshOnWrite,
//                renderTime: Date.distantPast)
//    }
//
//    func dict() -> [String: Any] {
//      return [
//        State.isForwardSearchAutomatically: self.isForwardSearchAutomatically,
//        State.isReverseSearchAutomatically: self.isReverseSearchAutomatically,
//        State.isRefreshOnWrite: self.isRefreshOnWrite,
//      ]
//    }
//
//    fileprivate static let isForwardSearchAutomatically = "is-forward-search-automatically"
//    fileprivate static let isReverseSearchAutomatically = "is-reverse-search-automatically"
//    fileprivate static let isRefreshOnWrite = "is-refresh-on-write"
//  }
//}
