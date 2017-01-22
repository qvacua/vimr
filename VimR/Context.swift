/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import RxSwift

class StateContext {

  let stateSource: Observable<Any>
  let actionEmitter = Emitter<Any>()

  init() {
    self.stateSource = self.stateSubject.asObservable()
    let actionSource = self.actionEmitter.observable

    self.previewTransformer = PreviewTransformer(port: in_port_t(self.appState.baseServerUrl.port ?? 0))

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
      .subscribe(onNext: { pair in
        self.appState.mainWindows[pair.state.uuid] = pair.state.payload
        self.stateSubject.onNext(pair.state)
      })
      .addDisposableTo(self.disposeBag)

    actionSource.debug().subscribe().addDisposableTo(self.disposeBag)
    stateSource.debug().subscribe().addDisposableTo(self.disposeBag)
  }

  fileprivate let stateSubject = PublishSubject<Any>()
  fileprivate let scheduler = SerialDispatchQueueScheduler(qos: .userInitiated)
  fileprivate let disposeBag = DisposeBag()

  fileprivate var appState = AppState.default

  fileprivate let appDelegateTransformer = AppDelegateTransformer()
  fileprivate let uiRootTransformer = UiRootTransformer()
  fileprivate let mainWindowTransformer = MainWindowTransformer()
  fileprivate let previewTransformer: PreviewTransformer
}

extension Observable {

  fileprivate func transform<T:Transformer>(by transformers: [T]) -> Observable<Element> where T.Element == Element {
    return transformers.reduce(self) { (prevSource, transformer) in transformer.transform(prevSource) }
  }

  fileprivate func transform<T:Transformer>(by transformer: T) -> Observable<Element> where T.Element == Element {
    return transformer.transform(self)
  }
}
