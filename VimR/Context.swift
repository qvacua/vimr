/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import RxSwift

class Context {

  let stateSource: Observable<AppState>
  let actionEmitter = Emitter<Any>()

  init(baseServerUrl: URL, state: AppState) {

    self.appState = state

    self.stateSource = self.stateSubject.asObservable()
    let actionSource = self.actionEmitter.observable

    self.httpService = HttpServerService(port: baseServerUrl.port!)

    let openQuicklyReducer = OpenQuicklyReducer()
    let markdownReducer = MarkdownReducer(baseServerUrl: baseServerUrl)

    let prefService = PrefService()
    let htmlPreviewToolReducer = HtmlPreviewToolReducer(baseServerUrl: baseServerUrl)
    let previewService = PreviewService()

    // For clean quit
    stateSource
      .filter { $0.quitWhenNoMainWindow && $0.mainWindows.isEmpty }
      .subscribe(onNext: { state in NSApp.stop(self) })
      .addDisposableTo(self.disposeBag)

    // AppState
    Observable
      .of(
        actionSource
          .mapOmittingNil { $0 as? AppDelegate.Action }
          .map { self.appStateActionPair(for: $0) }
          .reduce(by: AppDelegateReducer(baseServerUrl: baseServerUrl))
          .filter { $0.modified }
          .map { $0.state },
        actionSource
          .mapOmittingNil { $0 as? UuidAction<MainWindow.Action> }
          .map { self.appStateActionPair(for: $0) }
          .reduce(by: UiRootReducer())
          .reduce(by: openQuicklyReducer.forMainWindow)
          .filter { $0.modified }
          .apply(to: prefService.forMainWindow)
          .map { $0.state },
        actionSource
          .mapOmittingNil { $0 as? FileMonitor.Action }
          .map { self.appStateActionPair(for: $0) }
          .reduce(by: FileMonitorReducer())
          .filter { $0.modified }
          .map { $0.state },
        actionSource
          .mapOmittingNil { $0 as? OpenQuicklyWindow.Action }
          .map { self.appStateActionPair(for: $0) }
          .reduce(by: openQuicklyReducer.forOpenQuicklyWindow)
          .filter { $0.modified }
          .map { $0.state }
      )
      .merge()
      .subscribe(onNext: self.emitAppState)
      .addDisposableTo(self.disposeBag)

    // MainWindow.State
    Observable
      .of(
        actionSource
          .mapOmittingNil { $0 as? UuidAction<MainWindow.Action> }
          .mapOmittingNil { self.mainWindowStateActionPair(for: $0) }
          .reduce(by: MainWindowReducer())
          .reduce(by: markdownReducer.forMainWindow)
          .filter { $0.modified }
          .apply(to: previewService.forMainWindow)
          .apply(to: self.httpService.forMainWindow)
          .map { $0.state },
        actionSource
          .mapOmittingNil { $0 as? UuidAction<PreviewTool.Action> }
          .mapOmittingNil { self.mainWindowStateActionPair(for: $0) }
          .reduce(by: PreviewToolReducer(baseServerUrl: baseServerUrl))
          .filter { $0.modified }
          .map { $0.state },
        actionSource
          .mapOmittingNil { $0 as? UuidAction<HtmlPreviewTool.Action> }
          .mapOmittingNil { self.mainWindowStateActionPair(for: $0) }
          .reduce(by: htmlPreviewToolReducer)
          .filter { $0.modified }
          .apply(to: self.httpService.forHtmlPreviewTool)
          .map { $0.state },
        actionSource
          .mapOmittingNil { $0 as? UuidAction<FileBrowser.Action> }
          .mapOmittingNil { self.mainWindowStateActionPair(for: $0) }
          .reduce(by: FileBrowserReducer())
          .filter { $0.modified }
          .map { $0.state },
        actionSource
          .mapOmittingNil { $0 as? UuidAction<OpenedFileList.Action> }
          .mapOmittingNil { self.mainWindowStateActionPair(for: $0) }
          .reduce(by: OpenedFileListReducer())
          .reduce(by: markdownReducer.forOpenedFileList)
          .filter { $0.modified }
          .apply(to: previewService.forOpenedFileList)
          .map { $0.state }
      )
      .merge()
      .subscribe(onNext: self.emitAppState)
      .addDisposableTo(self.disposeBag)

    // Preferences
    Observable
      .of(
        actionSource
          .mapOmittingNil { $0 as? PrefWindow.Action }
          .map { self.appStateActionPair(for: $0) }
          .reduce(by: PrefWindowReducer())
          .filter { $0.modified }
          .map { $0.state },
        actionSource
          .mapOmittingNil { $0 as? GeneralPref.Action }
          .map { self.appStateActionPair(for: $0) }
          .reduce(by: GeneralPrefReducer())
          .filter { $0.modified }
          .map { $0.state },
        actionSource
          .mapOmittingNil { $0 as? AppearancePref.Action }
          .map { self.appStateActionPair(for: $0) }
          .reduce(by: AppearancePrefReducer())
          .filter { $0.modified }
          .map { $0.state },
        actionSource
          .mapOmittingNil { $0 as? AdvancedPref.Action }
          .map { self.appStateActionPair(for: $0) }
          .reduce(by: AdvancedPrefReducer())
          .filter { $0.modified }
          .map { $0.state }
      )
      .merge()
      .apply(to: prefService.forPrefPanes)
      .subscribe(onNext: self.emitAppState)
      .addDisposableTo(self.disposeBag)

#if DEBUG
//    actionSource.debug().subscribe().addDisposableTo(self.disposeBag)
//    stateSource
//      .filter { $0.mainWindows.values.count > 0 }
//      .map { Array($0.mainWindows.values)[0].preview }
//      .debug()
//      .subscribe(onNext: { state in
//      })
//      .addDisposableTo(self.disposeBag)
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
      if self.appState.mainWindows[uuid]?.close == true {
        self.appState.mainWindows.removeValue(forKey: uuid)
        return
      }

      self.appState.mainWindows[uuid]?.viewToBeFocused = nil
      self.appState.mainWindows[uuid]?.urlsToOpen.removeAll()
    }
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

  fileprivate func reduce<T:Reducer>(by transformer: T) -> Observable<Element> where T.Pair == Element {
    return transformer.reduce(self)
  }

  // If the following is used, the compiler does not finish...
//  fileprivate func transform<T:Reducer>(by transformers: [T]) -> Observable<Element> where T.Element == Element {
//    return transformers.reduce(self) { (result: Observable<Element>, transformer: T) -> Observable<Element> in
//      transformer.transform(result)
//    }
//  }

  fileprivate func apply<S:Service>(to service: S) -> Observable<Element> where S.Pair == Element {
    return self.do(onNext: service.apply)
  }

  fileprivate func apply<S:StateService>(to service: S) -> Observable<Element> where S.StateType == Element {
    return self.do(onNext: service.apply)
  }
}
