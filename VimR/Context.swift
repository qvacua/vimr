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
    self.appDelegateTransformer = AppDelegateTransformer(baseServerUrl: initialState.baseServerUrl)
    self.previewTransformer = PreviewTransformer(baseServerUrl: initialState.baseServerUrl)
    self.httpServerService = HttpServerService(port: initialState.baseServerUrl.port ?? 0)

    self.appState = initialState

    self.stateSource = self.stateSubject.asObservable()
    let actionSource = self.actionEmitter.observable/*.do(onNext: { _ in
      self.appState.mainWindows.keys.forEach { self.appState.mainWindows[$0]?.resetInstantStates() }
    })*/

    Observable
      .of(
        actionSource
          .mapOmittingNil { $0 as? AppDelegate.Action }
          .map { StateActionPair(state: self.appState, action: $0, modified: false) }
          .transform(by: self.appDelegateTransformer)
          .filter { $0.modified }
          .map { $0.state },
        actionSource
          .mapOmittingNil { $0 as? UuidAction<MainWindow.Action> }
          .map { StateActionPair(state: self.appState, action: $0, modified: false) }
          .transform(by: self.uiRootTransformer)
          .filter { $0.modified }
          .map { $0.state }
      )
      .merge()
      .subscribe(onNext: { state in
        self.appState = state
        self.stateSubject.onNext(self.appState)
      })
      .addDisposableTo(self.disposeBag)

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
      .transform(by: self.mainWindowTransformer)
      .transform(by: self.previewTransformer)
      .filter { $0.modified }
      .apply(to: self.previewService)
      .apply(to: self.httpServerService)
      .map { $0.state }
      .subscribe(onNext: { state in
        self.appState.mainWindows[state.uuid] = state.payload
        self.stateSubject.onNext(self.appState)
      })
      .addDisposableTo(self.disposeBag)

#if DEBUG
    actionSource.debug().subscribe().addDisposableTo(self.disposeBag)
    stateSource.debug().subscribe().addDisposableTo(self.disposeBag)
#endif
  }

  fileprivate let stateSubject = PublishSubject<AppState>()
  fileprivate let scheduler = SerialDispatchQueueScheduler(qos: .userInitiated)
  fileprivate let disposeBag = DisposeBag()

  fileprivate var appState: AppState

  fileprivate let appDelegateTransformer: AppDelegateTransformer
  fileprivate let uiRootTransformer = UiRootTransformer()
  fileprivate let mainWindowTransformer = MainWindowTransformer()
  fileprivate let previewTransformer: PreviewTransformer

  fileprivate let previewService = PreviewNewService()
  fileprivate let httpServerService: HttpServerService
}

extension Observable {

  fileprivate func transform<T:Transformer>(by transformer: T) -> Observable<Element> where T.Element == Element {
    return transformer.transform(self)
  }

  fileprivate func apply<S:Service>(to service: S) -> Observable<Element> where S.Element == Element {
    return self.do(onNext: service.apply)
  }
}
