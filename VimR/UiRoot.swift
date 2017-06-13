/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import RxSwift

class UiRoot: UiComponent {

  typealias StateType = AppState

  var hasMainWindows: Bool {
    return !self.mainWindows.isEmpty
  }

  required init(source: Observable<StateType>, emitter: ActionEmitter, state: StateType) {
    self.source = source
    self.emitter = emitter

    self.fileMonitor = FileMonitor(source: source, emitter: emitter, state: state)
    self.openQuicklyWindow = OpenQuicklyWindow(source: source, emitter: emitter, state: state)
    self.prefWindow = PrefWindow(source: source, emitter: emitter, state: state)

    source
      .observeOn(MainScheduler.instance)
      .subscribe(onNext: { [unowned self] state in
        let uuidsInState = Set(state.mainWindows.keys)

        uuidsInState
          .subtracting(self.mainWindows.keys)
          .flatMap { state.mainWindows[$0] }
          .forEach(self.createNewMainWindow)

        self.mainWindows.keys
          .filter { !uuidsInState.contains($0) }
          .forEach(self.removeMainWindow)

        guard self.mainWindows.isEmpty else {
          return
        }

        switch state.afterLastWindowAction {

        case .doNothing: return
        case .hide: NSApp.hide(self)
        case .quit: NSApp.terminate(self)

        }
      })
      .disposed(by: self.disposeBag)
  }

  // The following should only be used when Cmd-Q'ing
  func prepareQuit() {
    self.mainWindows.values.forEach { $0.quitNeoVimWithoutSaving() }
  }

  fileprivate let source: Observable<AppState>
  fileprivate let emitter: ActionEmitter
  fileprivate let disposeBag = DisposeBag()

  fileprivate let fileMonitor: FileMonitor
  fileprivate let openQuicklyWindow: OpenQuicklyWindow
  fileprivate let prefWindow: PrefWindow

  fileprivate var mainWindows = [String: MainWindow]()
  fileprivate var subjectForMainWindows = [String: PublishSubject<MainWindow.State>]()
  fileprivate var disposables = [String: Disposable]()

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
}
