/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import RxSwift

class UiRoot: UiComponent {

  typealias StateType = AppState

  enum Action {

    case quit
  }

  required init(
    source: Observable<StateType>,
    emitter: ActionEmitter,
    state: StateType
  ) {
    self.source = source
    self.emitter = emitter
    self.emit = emitter.typedEmit()

    self.fileMonitor = FileMonitor(source: source, emitter: emitter, state: state)
    self.openQuicklyWindow = OpenQuicklyWindow(source: source, emitter: emitter, state: state)
    self.prefWindow = PrefWindow(source: source, emitter: emitter, state: state)

    source
      .observeOn(MainScheduler.instance)
      .subscribe(onNext: { state in
        let uuidsInState = Set(state.mainWindows.keys)

        uuidsInState
          .subtracting(self.mainWindows.keys)
          .compactMap { state.mainWindows[$0] }
          .map(self.newMainWindow)
          .forEach { mainWindow in
            self.mainWindows[mainWindow.uuid] = mainWindow
            mainWindow.show()
          }

        if self.mainWindows.isEmpty {
          // We exit here if there are no main windows open.
          // Otherwise, when hide/quit after last main window is active,
          // you have to be really quick to open a new window
          // when re-activating VimR w/o automatic new main window.
          return
        }

        self.mainWindows.keys
          .filter { !uuidsInState.contains($0) }
          .forEach(self.removeMainWindow)

        guard self.mainWindows.isEmpty else { return }

        switch state.afterLastWindowAction {

        case .doNothing: return
        case .hide: NSApp.hide(self)
        case .quit: self.emit(.quit)

        }
      })
      .disposed(by: self.disposeBag)
  }

  // The following should only be used when Cmd-Q'ing
  func hasBlockedWindows() -> Bool {
    for mainWin in self.mainWindows.values {
      if mainWin.neoVimView.isBlocked().syncValue() == true { return true }
    }

    return false
  }

  // The following should only be used when Cmd-Q'ing
  func prepareQuit() {
    self.mainWindows.values.forEach { $0.prepareClosing() }

    try? Completable
      .concat(self.mainWindows.values.map { $0.quitNeoVimWithoutSaving() })
      .wait()

    self.mainWindows.values.forEach { $0.waitTillNvimExits() }
    self.openQuicklyWindow.cleanUp()
  }

  private let source: Observable<AppState>
  private let emitter: ActionEmitter
  private let emit: (Action) -> Void
  private let disposeBag = DisposeBag()

  private let fileMonitor: FileMonitor
  private let openQuicklyWindow: OpenQuicklyWindow
  private let prefWindow: PrefWindow

  private var mainWindows = [UUID: MainWindow]()
  private var subjectForMainWindows
    = [UUID: CompletableSubject<MainWindow.State>]()

  private func newMainWindow(with state: MainWindow.State) -> MainWindow {
    let subject = self
      .source
      .compactMap { $0.mainWindows[state.uuid] }
      .completableSubject()

    self.subjectForMainWindows[state.uuid] = subject
    return MainWindow(source: subject.asObservable(),
                      emitter: self.emitter,
                      state: state)
  }

  private func removeMainWindow(with uuid: UUID) {
    self.subjectForMainWindows[uuid]?.onCompleted()

    self.subjectForMainWindows.removeValue(forKey: uuid)
    self.mainWindows.removeValue(forKey: uuid)
  }
}
