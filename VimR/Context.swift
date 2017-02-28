/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import RxSwift

class Context {

  let stateSource: Observable<AppState>
  let actionEmitter = Emitter<Any>()

  init(_ state: AppState) {
    let baseServerUrl = URL(string: "http://localhost:\(NetUtils.openPort())")!

    self.appState = state

    self.stateSource = self.stateSubject.asObservable()
    let actionSource = self.actionEmitter.observable

    let openQuicklyTransformer = OpenQuicklyTransformer()
    let previewTransformer = PreviewTransformer(baseServerUrl: baseServerUrl)

    let previewService = PreviewService()

    // AppState
    Observable
      .of(
        actionSource
          .mapOmittingNil { $0 as? AppDelegate.Action }
          .map { self.appStateActionPair(for: $0) }
          .transform(by: AppDelegateTransformer(baseServerUrl: baseServerUrl))
          .filter { $0.modified }
          .map { $0.state },
        actionSource
          .mapOmittingNil { $0 as? UuidAction<MainWindow.Action> }
          .map { self.appStateActionPair(for: $0) }
          .transform(by: UiRootTransformer())
          .transform(by: openQuicklyTransformer.forMainWindow)
          .filter { $0.modified }
          .map { $0.state },
        actionSource
          .mapOmittingNil { $0 as? FileMonitor.Action }
          .map { self.appStateActionPair(for: $0) }
          .transform(by: FileMonitorTransformer())
          .filter { $0.modified }
          .map { $0.state },
        actionSource
          .mapOmittingNil { $0 as? OpenQuicklyWindow.Action }
          .map { self.appStateActionPair(for: $0) }
          .transform(by: openQuicklyTransformer.forOpenQuicklyWindow)
          .filter { $0.modified }
          .map { $0.state }
      )
      .merge()
      .subscribe(onNext: { state in
        self.appState = state
        self.stateSubject.onNext(self.appState)
      })
      .addDisposableTo(self.disposeBag)

    // MainWindow.State
    Observable
      .of(
        actionSource
          .mapOmittingNil { $0 as? UuidAction<MainWindow.Action> }
          .mapOmittingNil { self.mainWindowStateActionPair(for: $0) }
          .transform(by: MainWindowTransformer())
          .transform(by: previewTransformer.forMainWindow)
          .filter { $0.modified }
          .apply(to: previewService.forMainWindow)
          .apply(to: HttpServerService(port: baseServerUrl.port ?? 0))
          .map { $0.state },
        actionSource
          .mapOmittingNil { $0 as? UuidAction<PreviewTool.Action> }
          .mapOmittingNil { self.mainWindowStateActionPair(for: $0) }
          .transform(by: PreviewToolTransformer(baseServerUrl: baseServerUrl))
          .filter { $0.modified }
          .map { $0.state },
        actionSource
          .mapOmittingNil { $0 as? UuidAction<FileBrowser.Action> }
          .mapOmittingNil { self.mainWindowStateActionPair(for: $0) }
          .transform(by: FileBrowserTransformer())
          .filter { $0.modified }
          .map { $0.state },
        actionSource
          .mapOmittingNil { $0 as? UuidAction<OpenedFileList.Action> }
          .mapOmittingNil { self.mainWindowStateActionPair(for: $0) }
          .transform(by: OpenedFileListTransformer())
          .transform(by: previewTransformer.forOpenedFileList)
          .filter { $0.modified }
          .apply(to: previewService.forOpenedFileList)
          .map { $0.state }
      )
      .merge()
      .subscribe(onNext: { state in
        self.appState.mainWindows[state.uuid] = state.payload
        self.stateSubject.onNext(self.appState)
      })
      .addDisposableTo(self.disposeBag)

    // Preferences
    Observable
      .of(
        actionSource
          .mapOmittingNil { $0 as? PrefWindow.Action }
          .map { self.appStateActionPair(for: $0) }
          .transform(by: PrefWindowTransformer())
          .filter { $0.modified }
          .map { $0.state },
        actionSource
          .mapOmittingNil { $0 as? GeneralPref.Action }
          .map { self.appStateActionPair(for: $0) }
          .transform(by: GeneralPrefTransformer())
          .filter { $0.modified }
          .map { $0.state },
        actionSource
          .mapOmittingNil { $0 as? AppearancePref.Action }
          .map { self.appStateActionPair(for: $0) }
          .transform(by: AppearancePrefTransformer())
          .filter { $0.modified }
          .map { $0.state }
      )
      .merge()
      .subscribe(onNext: { state in
        self.appState = state
        self.stateSubject.onNext(self.appState)
      })
      .addDisposableTo(self.disposeBag)

#if DEBUG
//    actionSource.debug().subscribe().addDisposableTo(self.disposeBag)
//    stateSource.debug().subscribe().addDisposableTo(self.disposeBag)
#endif
  }

  deinit {
    self.stateSubject.onCompleted()
  }

  fileprivate let stateSubject = PublishSubject<AppState>()
  fileprivate let scheduler = SerialDispatchQueueScheduler(qos: .userInitiated)
  fileprivate let disposeBag = DisposeBag()

  fileprivate var appState: AppState

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

  fileprivate func transform<T:Transformer>(by transformer: T) -> Observable<Element> where T.Element == Element {
    return transformer.transform(self)
  }

  fileprivate func apply<S:Service>(to service: S) -> Observable<Element> where S.Element == Element {
    return self.do(onNext: service.apply)
  }
}
