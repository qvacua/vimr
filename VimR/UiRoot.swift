/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import RxSwift

class UiRoot: UiComponent {

  typealias StateType = AppState

  required init(source: StateSource, emitter: ActionEmitter, state: StateType) {
    self.source = source
    self.emitter = emitter

    source
      .mapOmittingNil { $0 as? StateType }
      .observeOn(MainScheduler.instance)
      .subscribe(onNext: { [unowned self] state in
        let keys = Set(self.mainWindows.keys)
        let keysInState = Set(state.mainWindows.keys)

        keysInState
          .subtracting(self.mainWindows.keys)
          .flatMap { state.mainWindows[$0] }
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
    let mainWindow = MainWindow(source: source, emitter: self.emitter, state: state)
    self.mainWindows[state.uuid] = mainWindow

    mainWindow.show()
  }

  fileprivate let source: StateSource
  fileprivate let emitter: ActionEmitter
  fileprivate let disposeBag = DisposeBag()

  fileprivate var mainWindows = [String: MainWindow]()
}
