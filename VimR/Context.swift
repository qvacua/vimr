/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import RxSwift

class Context {

  let stateSource: Observable<AppState>
  let actionEmitter = ActionEmitter()

  // The following should only be used when Cmd-Q'ing
  func savePrefs() {
    self.prefService.applyPref(from: self.appState)
  }

  init(baseServerUrl: URL, state: AppState) {
    self.appState = state
    self.stateSource = self.stateSubject.asObservable()

    let openQuicklyReducer = OpenQuicklyReducer()
    let markdownReducer = MarkdownReducer(baseServerUrl: baseServerUrl)

    let previewService = PreviewService()
    let httpService: HttpServerService = HttpServerService(port: baseServerUrl.port!)

    // AppState
    Observable
      .of(
        self.actionSourceForAppState()
          .reduce(by: AppDelegateReducer(baseServerUrl: baseServerUrl).reduce)
          .filterMapPair(),
        self.actionSourceForAppState()
          .reduce(by: UiRootReducer().reduce)
          .reduce(by: openQuicklyReducer.reduceMainWindow)
          .filter { $0.modified }
          .apply(self.prefService.applyMainWindow)
          .map { $0.state },
        self.actionSourceForAppState()
          .reduce(by: FileMonitorReducer().reduce)
          .filterMapPair(),
        self.actionSourceForAppState()
          .reduce(by: openQuicklyReducer.reduceOpenQuicklyWindow)
          .filterMapPair()
      )
      .merge()
      .subscribe(onNext: self.emitAppState)
      .disposed(by: self.disposeBag)

    // MainWindow.State
    Observable
      .of(
        self.actionSourceForMainWindow()
          .reduce(by: MainWindowReducer().reduce)
          .reduce(by: markdownReducer.reduceMainWindow)
          .filter { $0.modified }
          .apply(previewService.applyMainWindow)
          .apply(httpService.applyMainWindow)
          .map { $0.state },
        self.actionSourceForMainWindow()
          .reduce(by: PreviewToolReducer(baseServerUrl: baseServerUrl).reduce)
          .filterMapPair(),
        self.actionSourceForMainWindow()
          .reduce(by: HtmlPreviewToolReducer(baseServerUrl: baseServerUrl).reduce)
          .filter { $0.modified }
          .apply(httpService.applyHtmlPreview)
          .map { $0.state },
        self.actionSourceForMainWindow()
          .reduce(by: FileBrowserReducer().reduce)
          .filterMapPair(),
        self.actionSourceForMainWindow()
          .reduce(by: BuffersListReducer().reduce)
          .reduce(by: markdownReducer.reduceOpenedFileList)
          .filter { $0.modified }
          .apply(previewService.applyOpenedFileList)
          .map { $0.state }
      )
      .merge()
      .subscribe(onNext: self.emitAppState)
      .disposed(by: self.disposeBag)

    // Preferences
    Observable
      .of(
        self.prefStateSource(by: PrefWindowReducer().reduce, prefService: prefService),
        self.prefStateSource(by: GeneralPrefReducer().reduce, prefService: prefService),
        self.prefStateSource(by: ToolsPrefReducer().reduce, prefService: prefService),
        self.prefStateSource(by: AppearancePrefReducer().reduce, prefService: prefService),
        self.prefStateSource(by: AdvancedPrefReducer().reduce, prefService: prefService)
      )
      .merge()
      .subscribe(onNext: self.emitAppState)
      .disposed(by: self.disposeBag)

#if DEBUG
//    self.actionEmitter.observable.debug().subscribe().disposed(by: self.disposeBag)
//    stateSource.debug().subscribe().disposed(by: self.disposeBag)
#endif
  }

  deinit {
    self.stateSubject.onCompleted()
  }

  fileprivate let stateSubject = PublishSubject<AppState>()
  fileprivate let scheduler = SerialDispatchQueueScheduler(qos: .userInitiated)
  fileprivate let disposeBag = DisposeBag()

  fileprivate var appState: AppState

  fileprivate let prefService = PrefService()

  fileprivate func emitAppState(_ mainWindow: UuidState<MainWindow.State>) {
    self.appState.mainWindows[mainWindow.uuid] = mainWindow.payload
    self.stateSubject.onNext(self.appState)

    self.cleanUpAppState()
  }

  fileprivate func emitAppState(_ appState: AppState) {
    self.appState = appState
    self.stateSubject.onNext(self.appState)

    self.cleanUpAppState()
  }

  fileprivate func cleanUpAppState() {
    self.appState.mainWindows.keys.forEach { uuid in
      self.appState.mainWindows[uuid]?.cwdToSet = nil
      self.appState.mainWindows[uuid]?.currentBufferToSet = nil
      self.appState.mainWindows[uuid]?.viewToBeFocused = nil
      self.appState.mainWindows[uuid]?.urlsToOpen.removeAll()
    }
  }

  fileprivate func actionSourceForAppState<ActionType>() -> Observable<StateActionPair<AppState, ActionType>> {
    return self.actionEmitter.observable
      .mapOmittingNil { $0 as? ActionType }
      .map { self.appStateActionPair(for: $0) }
  }

  fileprivate func actionSourceForMainWindow<ActionType>()
      -> Observable<StateActionPair<UuidState<MainWindow.State>, ActionType>> {
    return self.actionEmitter.observable
      .mapOmittingNil { $0 as? UuidAction<ActionType> }
      .mapOmittingNil { self.mainWindowStateActionPair(for: $0) }
  }

  fileprivate func prefStateSource<ActionType>(
    by reduce: @escaping (StateActionPair<AppState, ActionType>) -> StateActionPair<AppState, ActionType>,
    prefService: PrefService
  ) -> Observable<AppState> {
    return self.actionSourceForAppState()
      .reduce(by: reduce)
      .filter { $0.modified }
      .apply(self.prefService.applyPref)
      .map { $0.state }
  }

  fileprivate func appStateActionPair<ActionType>(for action: ActionType) -> StateActionPair<AppState, ActionType> {
    return StateActionPair(state: self.appState, action: action, modified: false)
  }

  fileprivate func mainWindowStateActionPair<ActionType>(for action: UuidAction<ActionType>)
      -> StateActionPair<UuidState<MainWindow.State>, ActionType>? {
    guard let mainWindowState = self.appState.mainWindows[action.uuid] else {
      return nil
    }

    return StateActionPair(state: UuidState(uuid: action.uuid, state: mainWindowState),
                           action: action.payload,
                           modified: false)
  }
}
