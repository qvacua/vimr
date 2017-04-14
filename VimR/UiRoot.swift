/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import RxSwift

class UiRoot: UiComponent {

  typealias StateType = AppState

  enum Action {

    case cancelQuit
    case quitWithoutSaving
  }

  required init(source: Observable<StateType>, emitter: ActionEmitter, state: StateType) {
    self.source = source
    self.emitter = emitter

    self.fileMonitor = FileMonitor(source: source, emitter: emitter, state: state)
    self.prefWindow = PrefWindow(source: source, emitter: emitter, state: state)
    self.openQuicklyWindow = OpenQuicklyWindow(source: source, emitter: emitter, state: state)

    source
      .observeOn(MainScheduler.instance)
      .subscribe(onNext: { [unowned self] state in
        let uuidsInState = Set(state.mainWindows.keys.filter { !(state.mainWindows[$0]?.close ?? false) })

        uuidsInState
          .subtracting(self.mainWindows.keys)
          .flatMap { state.mainWindows[$0] }
          .forEach(self.createNewMainWindow)

        state.mainWindows.keys
          .filter { !uuidsInState.contains($0) }
          .forEach(self.removeMainWindow)

        guard state.quit else {
          return
        }

        if self.mainWindows.isEmpty {
          NSApp.stop(self)
          return
        }

        let isDirty = state.mainWindows.values.reduce(false) { $1.isDirty ? true : $0 }
        if isDirty {
          let alert = NSAlert()
          alert.addButton(withTitle: "Cancel")
          alert.addButton(withTitle: "Discard and Quit")
          alert.messageText = "There are windows with unsaved buffers!"
          alert.alertStyle = .warning

          if alert.runModal() == NSAlertSecondButtonReturn {
            self.emitter.emit(Action.quitWithoutSaving)
          } else {
            self.emitter.emit(Action.cancelQuit)
          }
        } else {
          self.emitter.emit(Action.quitWithoutSaving)
        }
      })
      .addDisposableTo(self.disposeBag)
  }

  fileprivate let source: Observable<AppState>
  fileprivate let emitter: ActionEmitter
  fileprivate let disposeBag = DisposeBag()

  fileprivate let fileMonitor: FileMonitor
  fileprivate let prefWindow: PrefWindow
  fileprivate let openQuicklyWindow: OpenQuicklyWindow

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
