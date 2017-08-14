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
    self.openQuicklyWindow = OpenQuicklyWindow(source: source, emitter: emitter, state: state)
    self.prefWindow = PrefWindow(source: source, emitter: emitter, state: state)

    source
      .observeOn(MainScheduler.instance)
      .subscribe(onNext: { [unowned self] state in
        let uuidsInState = Set(state.mainWindows.keys)

        uuidsInState
          .subtracting(self.mainWindows.keys)
          .flatMap { state.mainWindows[$0] }
          .map(self.newMainWindow)
          .forEach {
            self.mainWindows[$0.uuid] = $0
            $0.show()
          }

        if self.mainWindows.isEmpty {
          // We exit here if there are no main windows open. Otherwise, when hide/quit after last main window is active,
          // you have to be really quick to open a new window when re-activating VimR w/o automatic new main window.
          return
        }

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

  fileprivate func newMainWindow(with state: MainWindow.State) -> MainWindow {
    let subject = PublishSubject<MainWindow.State>()
    let source = self.source.mapOmittingNil { $0.mainWindows[state.uuid] }

    self.subjectForMainWindows[state.uuid] = subject
    self.disposables[state.uuid] = source.subscribe(subject)

    return MainWindow(source: subject.asObservable(), emitter: self.emitter, state: state)
  }

  fileprivate func removeMainWindow(with uuid: String) {
    self.subjectForMainWindows[uuid]?.onCompleted()
    self.disposables[uuid]?.dispose()

    self.subjectForMainWindows.removeValue(forKey: uuid)
    self.disposables.removeValue(forKey: uuid)
    self.mainWindows.removeValue(forKey: uuid)
  }
}
