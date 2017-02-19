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

    self.fileMonitor = FileMonitor(source: source, emitter: emitter, state: state)

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
          .forEach { uuid in
            self.mainWindows[uuid]?.closeAllNeoVimWindowsWithoutSaving()
            self.removeMainWindow(with: uuid)
          }

        // remove already closed windows
        state.mainWindows
          .filter { (uuid, mainWindow) in return mainWindow.isClosed }
          .forEach { (uuid, _) in self.removeMainWindow(with: uuid) }

        if state.quitWhenNoMainWindow && self.mainWindows.isEmpty {
          NSApp.stop(self)
        }
      })
      .addDisposableTo(self.disposeBag)
  }

  fileprivate func createNewMainWindow(with state: MainWindow.State) {
    let subject = PublishSubject<MainWindow.State>()
    let source = self.source.mapOmittingNil { $0.mainWindows[state.uuid] }

    self.subjectForMainWindows[state.uuid] = subject
    self.disposables[state.uuid] = source.subscribe(subject)

    let mainWindow = MainWindow(source: subject.asObservable(), emitter: self.emitter, state: state)
    self.mainWindows[state.uuid] = mainWindow
    mainWindow.show()
  }

  fileprivate func removeMainWindow(with uuid: String) {
    self.subjectForMainWindows[uuid]?.onCompleted()
    self.disposables[uuid]?.dispose()

    self.subjectForMainWindows.removeValue(forKey: uuid)
    self.disposables.removeValue(forKey: uuid)
    self.mainWindows.removeValue(forKey: uuid)
  }

  fileprivate let source: Observable<AppState>
  fileprivate let emitter: ActionEmitter
  fileprivate let disposeBag = DisposeBag()

  fileprivate var mainWindows = [String: MainWindow]()
  fileprivate var subjectForMainWindows = [String: PublishSubject<MainWindow.State>]()
  fileprivate var disposables = [String: Disposable]()

  fileprivate let fileMonitor: FileMonitor
}
