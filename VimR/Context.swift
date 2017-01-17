//
// Created by Tae Won Ha on 1/16/17.
// Copyright (c) 2017 Tae Won Ha. All rights reserved.
//

import Foundation
import RxSwift

class DummyService: Transformer {

  typealias State = MainWindowStates
  typealias Action = AppDelegate.Action

  func transform(_ source: Observable<StateActionPair<State, Action>>) -> Observable<StateActionPair<State, Action>> {
    NSLog("\(#function) dummy transform")
    return source
  }
}

class StateContext {

  let stateSource: Observable<Any>
  let actionEmitter = Emitter<Any>()

  init() {
    self.stateSource = self.stateSubject.asObservable()
    let actionSource = self.actionEmitter.observable

    actionSource
      .mapOmittingNil { $0 as? AppDelegate.Action }
      .map { StateActionPair(state: self.appState.mainWindows, action: $0) }
      .transform(by: [appDelegateTransformer])
      .map { $0.state }
      .subscribe(onNext: { state in
        self.appState.mainWindows = state
        self.stateSubject.onNext(state)
      })
      .addDisposableTo(self.disposeBag)

    actionSource
      .mapOmittingNil { $0 as? UuidAction<MainWindow.Action> }
      .map { StateActionPair(state: self.appState.mainWindows, action: $0) }
      .transform(by: self.uiRootTransformer)
      .map { $0.state }
      .subscribe(onNext: { state in
        self.appState.mainWindows = state
        self.stateSubject.onNext(state)
      })
      .addDisposableTo(self.disposeBag)

    actionSource
      .mapOmittingNil { $0 as? UuidAction<MainWindow.Action> }
      .mapOmittingNil { action in
        guard let mainWindowState = self.appState.mainWindows.current[action.uuid] else {
          return nil
        }

        return StateActionPair(state: UuidState(uuid: action.uuid, state: mainWindowState), action: action.payload)
      }
      .transform(by: self.mainWindowTransformer)
      .subscribe(onNext: { pair in
        self.appState.mainWindows.current[pair.state.uuid] = pair.state.payload
        self.stateSubject.onNext(pair.state)
      })
      .addDisposableTo(self.disposeBag)

    actionSource
      .subscribe(onNext: { action in
        NSLog("ACTION: \(action)")
      })
      .addDisposableTo(self.disposeBag)
    stateSource
      .subscribe(onNext: { state in
        NSLog("STATE : \(self.appState.mainWindows.current)")
      })
      .addDisposableTo(self.disposeBag)
  }

  fileprivate let stateSubject = PublishSubject<Any>()
  fileprivate let disposeBag = DisposeBag()

  fileprivate var appState = AppState.default

  fileprivate let appDelegateTransformer = AppDelegateTransformer()
  fileprivate let uiRootTransformer = UiRootTransformer()
  fileprivate let mainWindowTransformer = MainWindowTransformer()
}

extension Observable {

  fileprivate func transform<T:Transformer>(by transformers: [T]) -> Observable<Element> where T.Pair == Element {
    return transformers.reduce(self) { (prevSource, transformer) in transformer.transform(prevSource) }
  }

  fileprivate func transform<T:Transformer>(by transformer: T) -> Observable<Element> where T.Pair == Element {
    return transformer.transform(self)
  }
}
