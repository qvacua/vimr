/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import RxSwift

class StateContext {

  let stateSource: Observable<AppState>
  let actionEmitter = Emitter<Any>()

  init(_ initialState: AppState) {
    let baseServerUrl = URL(string: "http://localhost:\(NetUtils.openPort())")!

    self.appState = initialState

    self.stateSource = self.stateSubject.asObservable()
    let actionSource = self.actionEmitter.observable

    let openQuicklyTransformer = OpenQuicklyTransformer()
    let previewTransformer = PreviewTransformer(baseServerUrl: baseServerUrl)

    let previewService = PreviewService()

    Observable
      .of(
        actionSource
          .mapOmittingNil { $0 as? AppDelegate.Action }
          .map { StateActionPair(state: self.appState, action: $0, modified: false) }
          .transform(by: AppDelegateTransformer(baseServerUrl: baseServerUrl))
          .filter { $0.modified }
          .map { $0.state },
        actionSource
          .mapOmittingNil { $0 as? UuidAction<MainWindow.Action> }
          .map { StateActionPair(state: self.appState, action: $0, modified: false) }
          .transform(by: UiRootTransformer())
          .transform(by: openQuicklyTransformer.forMainWindow)
          .filter { $0.modified }
          .map { $0.state },
        actionSource
          .mapOmittingNil { $0 as? FileMonitor.Action }
          .map { StateActionPair(state: self.appState, action: $0, modified: false) }
          .transform(by: FileMonitorTransformer())
          .filter { $0.modified }
          .map { $0.state },
        actionSource
          .mapOmittingNil { $0 as? OpenQuicklyWindow.Action }
          .map { StateActionPair(state: self.appState, action: $0, modified: false) }
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

    Observable
      .of(
        actionSource
          .mapOmittingNil { $0 as? UuidAction<MainWindow.Action> }
          .mapOmittingNil { action in
            guard let mainWindowState = self.appState.mainWindows[action.uuid] else {
              return nil
            }

            return StateActionPair(state: UuidState(uuid: action.uuid, state: mainWindowState),
                                   action: action.payload,
                                   modified: false)
          }
          .transform(by: MainWindowTransformer())
          .transform(by: previewTransformer.forMainWindow)
          .filter { $0.modified }
          .apply(to: previewService.forMainWindow)
          .apply(to: HttpServerService(port: baseServerUrl.port ?? 0))
          .map { $0.state },
        actionSource
          .mapOmittingNil { $0 as? UuidAction<PreviewTool.Action> }
          .mapOmittingNil { action in
            guard let mainWindowState = self.appState.mainWindows[action.uuid] else {
              return nil
            }

            return StateActionPair(state: UuidState(uuid: action.uuid, state: mainWindowState),
                                   action: action.payload,
                                   modified: false)
          }
          .transform(by: PreviewToolTransformer(baseServerUrl: baseServerUrl))
          .filter { $0.modified }
          .map { $0.state },
        actionSource
          .mapOmittingNil { $0 as? UuidAction<FileBrowser.Action> }
          .mapOmittingNil { action in
            guard let mainWindowState = self.appState.mainWindows[action.uuid] else {
              return nil
            }

            return StateActionPair(state: UuidState(uuid: action.uuid, state: mainWindowState),
                                   action: action.payload,
                                   modified: false)
          }
          .transform(by: FileBrowserTransformer())
          .filter { $0.modified }
          .map { $0.state },
        actionSource
          .mapOmittingNil { $0 as? UuidAction<OpenedFileList.Action> }
          .mapOmittingNil { action in
            guard let mainWindowState = self.appState.mainWindows[action.uuid] else {
              return nil
            }

            return StateActionPair(state: UuidState(uuid: action.uuid, state: mainWindowState),
                                   action: action.payload,
                                   modified: false)
          }
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

    Observable
      .of(
        actionSource
          .mapOmittingNil { $0 as? PrefWindow.Action }
          .map { StateActionPair(state: self.appState, action: $0, modified: false) }
          .transform(by: PrefWindowTransformer())
          .filter { $0.modified }
          .map { $0.state },
        actionSource
          .mapOmittingNil { $0 as? GeneralPref.Action }
          .map { StateActionPair(state: self.appState, action: $0, modified: false) }
          .transform(by: GeneralPrefTransformer())
          .filter { $0.modified }
          .map { $0.state },
        actionSource
          .mapOmittingNil { $0 as? AppearancePref.Action }
          .map { StateActionPair(state: self.appState, action: $0, modified: false) }
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
}

extension Observable {

  fileprivate func transform<T:Transformer>(by transformer: T) -> Observable<Element> where T.Element == Element {
    return transformer.transform(self)
  }

  fileprivate func apply<S:Service>(to service: S) -> Observable<Element> where S.Element == Element {
    return self.do(onNext: service.apply)
  }
}
