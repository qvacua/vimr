/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import RxSwift

class Context {

  let stateSource: Observable<AppState>
  let actionEmitter = ActionEmitter()

  init(baseServerUrl: URL, state: AppState) {

    self.appState = state

    self.stateSource = self.stateSubject.asObservable()

    self.httpService = HttpServerService(port: baseServerUrl.port!)

    let openQuicklyReducer = OpenQuicklyReducer()
    let markdownReducer = MarkdownReducer(baseServerUrl: baseServerUrl)

    let prefService = PrefService()
    let htmlPreviewToolReducer = HtmlPreviewToolReducer(baseServerUrl: baseServerUrl)
    let previewService = PreviewService()

    // AppState
    Observable
      .of(
        self.actionSourceForAppState()
            .reduce(by: AppDelegateReducer(baseServerUrl: baseServerUrl))
            .filterMapPair(),
        self.actionSourceForAppState()
            .reduce(by: UiRootReducer())
            .reduce(by: openQuicklyReducer.forMainWindow)
            .filter { $0.modified }
            .apply(to: prefService.forMainWindow)
            .map { $0.state },
        self.actionSourceForAppState()
            .reduce(by: FileMonitorReducer())
            .filterMapPair(),
        self.actionSourceForAppState()
            .reduce(by: openQuicklyReducer.forOpenQuicklyWindow)
            .filterMapPair()
      )
      .merge()
      .subscribe(onNext: self.emitAppState)
      .disposed(by: self.disposeBag)

    // MainWindow.State
    Observable
      .of(
        self.actionSourceForMainWindow()
            .reduce(by: MainWindowReducer())
            .reduce(by: markdownReducer.forMainWindow)
            .filter { $0.modified }
            .apply(to: previewService.forMainWindow)
            .apply(to: self.httpService.forMainWindow)
            .map { $0.state },
        self.actionSourceForMainWindow()
            .reduce(by: PreviewToolReducer(baseServerUrl: baseServerUrl))
            .filterMapPair(),
        self.actionSourceForMainWindow()
            .reduce(by: htmlPreviewToolReducer)
            .filter { $0.modified }
            .apply(to: self.httpService.forHtmlPreviewTool)
            .map { $0.state },
        self.actionSourceForMainWindow()
            .reduce(by: FileBrowserReducer())
            .filterMapPair(),
        self.actionSourceForMainWindow()
            .reduce(by: OpenedFileListReducer())
            .reduce(by: markdownReducer.forOpenedFileList)
            .filter { $0.modified }
            .apply(to: previewService.forOpenedFileList)
            .map { $0.state }
      )
      .merge()
      .subscribe(onNext: self.emitAppState)
      .disposed(by: self.disposeBag)

    // Preferences
    Observable
      .of(
        self.actionSourceForAppState()
            .reduce(by: PrefWindowReducer())
            .filterMapPair(),
        self.actionSourceForAppState()
            .reduce(by: GeneralPrefReducer())
            .filterMapPair(),
        self.actionSourceForAppState()
            .reduce(by: AppearancePrefReducer())
            .filterMapPair(),
        self.actionSourceForAppState()
            .reduce(by: AdvancedPrefReducer())
            .filterMapPair()
      )
      .merge()
      .apply(to: prefService.forPrefPanes)
      .subscribe(onNext: self.emitAppState)
      .disposed(by: self.disposeBag)

#if DEBUG
//    actionSource.debug().subscribe().disposed(by: self.disposeBag)
//    stateSource.debug().subscribe().disposed(by: self.disposeBag)
#endif
  }

  deinit {
    self.stateSubject.onCompleted()
  }

  fileprivate let httpService: HttpServerService

  fileprivate let stateSubject = PublishSubject<AppState>()
  fileprivate let scheduler = SerialDispatchQueueScheduler(qos: .userInitiated)
  fileprivate let disposeBag = DisposeBag()

  fileprivate var appState: AppState

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

extension Observable {

  fileprivate func reduce<R:Reducer>(by reducer: R) -> Observable<Element> where R.Pair == Element {
    return reducer.reduce(self)
  }

  fileprivate func apply<S:Service>(to service: S) -> Observable<Element> where S.Pair == Element {
    return self.do(onNext: service.apply)
  }

  fileprivate func apply<S:StateService>(to service: S) -> Observable<Element> where S.StateType == Element {
    return self.do(onNext: service.apply)
  }

  fileprivate func filterMapPair<S, A>() -> Observable<S> where Element == StateActionPair<S, A> {
    return self
      .filter { $0.modified }
      .map { $0.state }
  }
}
