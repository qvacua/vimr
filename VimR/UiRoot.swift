//
// Created by Tae Won Ha on 1/16/17.
// Copyright (c) 2017 Tae Won Ha. All rights reserved.
//

import Cocoa
import RxSwift

class UiRoot: UiComponent {

  typealias StateType = MainWindowStates

  required init(source: Observable<StateType>, emitter: ActionEmitter, state: StateType) {
    self.source = source
    self.emitter = emitter

    source
      .observeOn(MainScheduler.instance)
      .subscribe(onNext: { [unowned self] state in
        let keys = Set(self.mainWindows.keys)
        let keysInState = Set(state.current.keys)

        keysInState
          .subtracting(self.mainWindows.keys)
          .flatMap { state.current[$0] }
          .forEach(self.createNewMainWindow)

        keys
          .subtracting(keysInState)
          .forEach {
            self.mainWindows.removeValue(forKey: $0)
          }

      })
      .addDisposableTo(self.disposeBag)
  }

  fileprivate func createNewMainWindow(with state: MainWindow.State) {
    let mainWindow = MainWindow(source: self.source.mapOmittingNil { $0.current[state.uuid] },
                                emitter: self.emitter,
                                state: state)
    self.mainWindows[state.uuid] = mainWindow

    mainWindow.show()
  }

  fileprivate let source: Observable<StateType>
  fileprivate let emitter: ActionEmitter
  fileprivate let disposeBag = DisposeBag()

  fileprivate var mainWindows = [String: MainWindow]()
}
