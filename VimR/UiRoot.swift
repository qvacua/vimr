/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import RxSwift

class UiRoot: UiComponent {

  typealias StateType = AppState

  required init(source: Observable<StateType>, emitter: ActionEmitter, state: StateType) {
    self.source = source
    self.emitter = emitter

    source
      .observeOn(MainScheduler.instance)
      .subscribe(onNext: { [unowned self] state in
        let uuids = Set(self.mainWindows.keys)
        let uuidsInState = Set(state.mainWindows.keys)

        uuidsInState
          .subtracting(self.mainWindows.keys)
          .flatMap { state.mainWindows[$0] }
          .forEach(self.createNewMainWindow)

        uuids
          .subtracting(uuidsInState)
          .forEach {
            self.mainWindows.removeValue(forKey: $0)
          }

      })
      .addDisposableTo(self.disposeBag)
  }

  fileprivate func createNewMainWindow(with state: MainWindow.State) {
    let mainWindow = MainWindow(source: source.mapOmittingNil { $0.mainWindows[state.uuid] },
                                emitter: self.emitter,
                                state: state)
    self.mainWindows[state.uuid] = mainWindow

    mainWindow.show()
  }

  fileprivate let source: Observable<AppState>
  fileprivate let emitter: ActionEmitter
  fileprivate let disposeBag = DisposeBag()

  fileprivate var mainWindows = [String: MainWindow]()
}
