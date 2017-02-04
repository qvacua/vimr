/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import RxSwift

typealias ActionEmitter = Emitter<Any>

class Emitter<T> {

  let observable: Observable<T>

  init() {
    self.observable = self.subject.asObservable().observeOn(scheduler)
  }

  func emit(_ action: T) {
    self.subject.onNext(action)
  }

  deinit {
    self.subject.onCompleted()
  }

  fileprivate let scheduler = SerialDispatchQueueScheduler(qos: .userInitiated)
  fileprivate let subject = PublishSubject<T>()
}

class StateActionPair<S, A> {

  let modified: Bool
  let state: S
  let action: A

  init(state: S, action: A, modified: Bool = true) {
    self.modified = modified
    self.state = state
    self.action = action
  }
}

class UuidAction<A>: CustomStringConvertible {

  let uuid: String
  let payload: A

  var description: String {
    return "UuidAction(uuid: \(uuid), payload: \(String(reflecting: payload)))"
  }

  init(uuid: String, action: A) {
    self.uuid = uuid
    self.payload = action
  }
}

class UuidState<S>: CustomStringConvertible {

  let uuid: String
  let payload: S

  var description: String {
    return "UuidState(uuid: \(uuid), payload: \(String(reflecting: payload)))"
  }

  init(uuid: String, state: S) {
    self.uuid = uuid
    self.payload = state
  }
}

protocol Morpher {

  associatedtype In
  associatedtype Out

  func transform(_ source: Observable<In>) -> Observable<Out>
}

protocol Transformer: Morpher {

  associatedtype Element

  typealias In = Element
  typealias Out = Element

  func transform(_ source: Observable<Element>) -> Observable<Element>
}

struct AppState {

  static let `default` = AppState(mainWindow: MainWindow.State.default)

  var currentMainWindow: MainWindow.State
  var mainWindows: [String: MainWindow.State] = [:]

  let baseServerUrl: URL

  init(mainWindow: MainWindow.State) {
    self.baseServerUrl = URL(string: "http://localhost:\(NetUtils.openPort())")!
    self.currentMainWindow = mainWindow
  }
}

enum PreviewState {

  case none(server: URL)
  case error(server: URL)
  case notSaved(server: URL)
  case markdown(file: URL, html: URL, server: URL)
}

extension MainWindow {

  struct State {

    static let `default` = State(isAllToolsVisible: true, isToolButtonsVisible: true)

    var isAllToolsVisible = true
    var isToolButtonsVisible = true

    ////// transient

    var preview = PreviewState.none(server: URL(string: "http://localhost/dummy")!)
    var isClosed = false

    // neovim
    var uuid = UUID().uuidString
    var currentBuffer: NeoVimBuffer?
    var buffers = [NeoVimBuffer]()
    var cwd = FileUtils.userHomeUrl

    var isDirty = false

    var font = NSFont.userFixedPitchFont(ofSize: 13)!
    var linespacing: CGFloat = 1
    var isUseLigatures = false
    var isUseInteractiveZsh = false

    // transient^2
    var urlsToOpen = [URL: OpenMode]()

    init(isAllToolsVisible: Bool, isToolButtonsVisible: Bool) {
      self.isAllToolsVisible = isAllToolsVisible
      self.isToolButtonsVisible = isToolButtonsVisible
    }
  }
}

