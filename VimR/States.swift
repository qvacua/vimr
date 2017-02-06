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

protocol Service {

  associatedtype Element

  func apply(_: Element)
}

struct AppState {

  static let `default` = AppState(baseServerUrl: URL(string: "http://localhost:\(NetUtils.openPort())")!,
                                  mainWindow: MainWindow.State.default)

  var currentMainWindow: MainWindow.State
  var mainWindows: [String: MainWindow.State] = [:]

  let baseServerUrl: URL

  init(baseServerUrl: URL, mainWindow: MainWindow.State) {
    self.baseServerUrl = baseServerUrl
    self.currentMainWindow = mainWindow
  }
}

struct PreviewState {

  static let `default` = PreviewState()

  enum Status {

    case none
    case notSaved
    case error
    case markdown
  }

  var status = Status.none

  var buffer: URL?
  var html: URL?
  var server: URL?

  var updateDate = Date.distantPast

  var scrollPosition = Position(row: 1, column: 1)

  init(status: Status = .none,
       buffer: URL? = nil,
       html: URL? = nil,
       server: URL? = nil,
       updateDate: Date = Date.distantPast,
       scrollPosition: Position = Position(row: 1, column: 1))
  {
    self.status = status
    self.buffer = buffer
    self.html = html
    self.server = server
    self.updateDate = updateDate
    self.scrollPosition = scrollPosition
  }
}

extension MainWindow {

  struct State {

    static let `default` = State(isAllToolsVisible: true, isToolButtonsVisible: true)

    var isAllToolsVisible = true
    var isToolButtonsVisible = true

    ////// transient

    var preview = PreviewState.default
    var previewTool = PreviewTool.State.default

    var isClosed = false

    // neovim
    var uuid = UUID().uuidString
    var currentBuffer: NeoVimBuffer?
    var buffers = [NeoVimBuffer]()
    var cwd = FileUtils.userHomeUrl
    var cursorPosition = Position(row: 1, column: 1)

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

extension PreviewTool {

  struct State {

    static let `default` = State()

    var isForwardSearchAutomatically = false
    var isReverseSearchAutomatically = false
    var isRefreshOnWrite = true
  }
}
