/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import RxSwift
import PureLayout
import WebKit
import Swifter

class PreviewTool: NSView, UiComponent, WKNavigationDelegate {

  enum Action {

    case refreshNow
    case reverseSearch(to: Marked<Position>)

    case scroll(to: Marked<Position>)

    case setAutomaticReverseSearch(to: Bool)
    case setAutomaticForwardSearch(to: Bool)
    case setRefreshOnWrite(to: Bool)
  }

  typealias StateType = MainWindow.State

  let menuItems: [NSMenuItem]

  required init(source: Observable<StateType>, emitter: ActionEmitter, state: StateType) {
    self.emitter = emitter
    self.uuid = state.uuid

    let configuration = WKWebViewConfiguration()
    configuration.userContentController = self.userContentController
    self.webview = WKWebView(frame: CGRect.zero, configuration: configuration)

    let refreshMenuItem = NSMenuItem(title: "Refresh Now", action: nil, keyEquivalent: "")
    let forwardSearchMenuItem = NSMenuItem(title: "Forward Search", action: nil, keyEquivalent: "")
    let reverseSearchMenuItem = NSMenuItem(title: "Reverse Search", action: nil, keyEquivalent: "")

    let automaticForward = self.automaticForwardMenuItem
    let automaticReverse = self.automaticReverseMenuItem
    let refreshOnWrite = self.refreshOnWriteMenuItem

    automaticForward.boolState = state.previewTool.isForwardSearchAutomatically
    automaticReverse.boolState = state.previewTool.isReverseSearchAutomatically
    refreshOnWrite.boolState = state.previewTool.isRefreshOnWrite

    self.menuItems = [
      refreshMenuItem,
      forwardSearchMenuItem,
      reverseSearchMenuItem,
      NSMenuItem.separator(),
      automaticForward,
      automaticReverse,
      NSMenuItem.separator(),
      refreshOnWrite,
    ]

    super.init(frame: .zero)
    self.configureForAutoLayout()

    refreshMenuItem.target = self
    refreshMenuItem.action = #selector(PreviewTool.refreshNowAction)
    forwardSearchMenuItem.target = self
    forwardSearchMenuItem.action = #selector(PreviewTool.forwardSearchAction)
    reverseSearchMenuItem.target = self
    reverseSearchMenuItem.action = #selector(PreviewTool.reverseSearchAction)
    automaticForward.target = self
    automaticForward.action = #selector(PreviewTool.automaticForwardSearchAction)
    automaticReverse.target = self
    automaticReverse.action = #selector(PreviewTool.automaticReverseSearchAction)
    refreshOnWrite.target = self
    refreshOnWrite.action = #selector(PreviewTool.refreshOnWriteAction)

    self.addViews()
    self.webview.load(URLRequest(url: state.preview.server!))

    source
      .observeOn(MainScheduler.instance)
      .subscribe(onNext: { [unowned self] state in
        if case .preview = state.focusedView {
          self.beFirstResponder()
        }

        self.automaticForwardMenuItem.boolState = state.previewTool.isForwardSearchAutomatically
        self.automaticReverseMenuItem.boolState = state.previewTool.isReverseSearchAutomatically
        self.refreshOnWriteMenuItem.boolState = state.previewTool.isRefreshOnWrite

        if state.previewTool.isForwardSearchAutomatically
           && state.preview.editorPosition.hasDifferentMark(as: self.editorPosition)
        {
          self.forwardSearch(position: state.preview.editorPosition.payload)
        }

        self.editorPosition = state.preview.editorPosition

        guard state.preview.updateDate > self.lastUpdateDate else { return }
        guard let serverUrl = state.preview.server else { return }

        self.lastUpdateDate = state.preview.updateDate
        self.webview.load(URLRequest(url: serverUrl))
      }, onCompleted: { [unowned self] in
        // We have to do the following to avoid a crash... Dunno why... -_-
        self.webviewMessageHandler.subject.onCompleted()
        self.webview.navigationDelegate = nil
        self.webview.removeFromSuperview()
      })
      .addDisposableTo(self.disposeBag)

    self.webviewMessageHandler.source
      .throttle(0.75, latest: true, scheduler: self.scheduler)
      .subscribe(onNext: { [unowned self] position in
        self.previewPosition = Marked(position)
        self.emitter.emit(UuidAction(uuid: self.uuid, action: Action.scroll(to: self.previewPosition)))
      })
      .addDisposableTo(self.disposeBag)
  }

  fileprivate func addViews() {
    self.webview.navigationDelegate = self
    self.userContentController.add(webviewMessageHandler, name: "com_vimr_tools_preview_markdown")
    self.webview.configureForAutoLayout()

    self.addSubview(self.webview)
    self.webview.autoPinEdgesToSuperviewEdges()
  }

  func webView(_: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
    NSLog("ERROR preview component's webview: \(error)")
  }

  fileprivate let emitter: ActionEmitter
  fileprivate let uuid: String

  fileprivate let webview: WKWebView
  fileprivate let disposeBag = DisposeBag()
  fileprivate let scheduler = ConcurrentDispatchQueueScheduler(qos: .userInitiated)
  fileprivate var isOpen = false

  fileprivate var lastUpdateDate = Date.distantPast
  fileprivate var editorPosition = Marked(Position.beginning)
  fileprivate var previewPosition = Marked(Position.beginning)

  fileprivate let userContentController = WKUserContentController()
  fileprivate let webviewMessageHandler = WebviewMessageHandler()

  fileprivate let automaticForwardMenuItem = NSMenuItem(title: "Automatic Forward Search",
                                                        action: nil,
                                                        keyEquivalent: "")
  fileprivate let automaticReverseMenuItem = NSMenuItem(title: "Automatic Reverse Search",
                                                        action: nil,
                                                        keyEquivalent: "")
  fileprivate let refreshOnWriteMenuItem = NSMenuItem(title: "Refresh on Write", action: nil, keyEquivalent: "")

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  fileprivate func forwardSearch(position: Position) {
    self.webview.evaluateJavaScript("scrollToPosition(\(position.row), \(position.column));")
  }
}

// MARK: - Actions
extension PreviewTool {

  func refreshNowAction(_: Any?) {
    self.emitter.emit(UuidAction(uuid: self.uuid, action: Action.refreshNow))
  }

  func forwardSearchAction(_: Any?) {
    self.forwardSearch(position: self.editorPosition.payload)
  }

  func reverseSearchAction(_: Any?) {
    self.previewPosition = Marked(self.previewPosition.payload) // set a new mark
    self.emitter.emit(UuidAction(uuid: self.uuid, action: Action.reverseSearch(to: self.previewPosition)))
  }

  func automaticForwardSearchAction(_ sender: NSMenuItem) {
    self.emitter.emit(UuidAction(uuid: self.uuid, action: Action.setAutomaticForwardSearch(to: !sender.boolState)))
  }

  func automaticReverseSearchAction(_ sender: NSMenuItem) {
    self.emitter.emit(UuidAction(uuid: self.uuid, action: Action.setAutomaticReverseSearch(to: !sender.boolState)))
  }

  func refreshOnWriteAction(_ sender: NSMenuItem) {
    self.emitter.emit(UuidAction(uuid: self.uuid, action: Action.setRefreshOnWrite(to: !sender.boolState)))
  }
}

fileprivate class WebviewMessageHandler: NSObject, WKScriptMessageHandler {

  var source: Observable<Position> {
    return self.subject.asObservable()
  }

  deinit {
    self.subject.onCompleted()
  }

  func userContentController(_: WKUserContentController, didReceive message: WKScriptMessage) {
    guard let msgBody = message.body as? [String: Int] else {
      return
    }

    guard let lineBegin = msgBody["lineBegin"], let columnBegin = msgBody["columnBegin"] else {
      return
    }

    self.subject.onNext(Position(row: lineBegin, column: columnBegin))
  }

  fileprivate let subject = PublishSubject<Position>()
}
