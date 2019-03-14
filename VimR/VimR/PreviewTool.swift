/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import RxSwift
import PureLayout
import WebKit
import os

class PreviewTool: NSView, UiComponent, WKNavigationDelegate {

  enum Action {

    case refreshNow
    case reverseSearch(to: Position)

    case scroll(to: Position)

    case setAutomaticReverseSearch(to: Bool)
    case setAutomaticForwardSearch(to: Bool)
    case setRefreshOnWrite(to: Bool)
  }

  typealias StateType = MainWindow.State

  let menuItems: [NSMenuItem]

  required init(source: Observable<StateType>, emitter: ActionEmitter, state: StateType) {
    self.emit = emitter.typedEmit()
    self.uuid = state.uuid

    let configuration = WKWebViewConfiguration()
    configuration.userContentController = self.userContentController
    configuration.processPool = Defs.webViewProcessPool
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
    self.webview.navigationDelegate = self
    self.webview.load(URLRequest(url: state.preview.server!))

    source
      .observeOn(MainScheduler.instance)
      .subscribe(onNext: { state in
        if state.viewToBeFocused != nil,
           case .markdownPreview = state.viewToBeFocused! {
          self.beFirstResponder()
        }

        self.automaticForwardMenuItem.boolState = state.previewTool.isForwardSearchAutomatically
        self.automaticReverseMenuItem.boolState = state.previewTool.isReverseSearchAutomatically
        self.refreshOnWriteMenuItem.boolState = state.previewTool.isRefreshOnWrite

        if state.preview.status == .markdown
           && state.previewTool.isForwardSearchAutomatically
           && state.preview.editorPosition.hasDifferentMark(as: self.editorPosition)
        {
          self.forwardSearch(position: state.preview.editorPosition.payload)
        }

        self.editorPosition = state.preview.editorPosition

        guard state.preview.updateDate > self.lastUpdateDate else { return }
        guard let serverUrl = state.preview.server else { return }
        if serverUrl != self.url {
          self.url = serverUrl
          self.scrollTop = 0
          self.previewPosition = Position.beginning
        }

        self.lastUpdateDate = state.preview.updateDate
        self.webview.load(URLRequest(url: serverUrl))
      }, onCompleted: {
        // We have to do the following to avoid a crash... Dunno why... -_-
        self.webviewMessageHandler.subject.onCompleted()
        self.webview.navigationDelegate = nil
        self.webview.removeFromSuperview()
      })
      .disposed(by: self.disposeBag)

    self.webviewMessageHandler.source
      .throttle(0.75, latest: true, scheduler: self.scheduler)
      .subscribe(onNext: { [unowned self] (position, scrollTop) in
        self.previewPosition = position
        self.scrollTop = scrollTop
        self.emit(UuidAction(uuid: self.uuid, action: .scroll(to: self.previewPosition)))
      })
      .disposed(by: self.disposeBag)
  }

  private func addViews() {
    self.webview.navigationDelegate = self
    self.userContentController.add(webviewMessageHandler, name: "com_vimr_tools_preview_markdown")
    self.webview.configureForAutoLayout()

    self.addSubview(self.webview)
    self.webview.autoPinEdgesToSuperviewEdges()
  }

  func webView(_: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
    self.log.error("ERROR preview component's webview: \(error)")
  }

  func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    self.webview.evaluateJavaScript("document.body.scrollTop = \(self.scrollTop)")
  }

  private let emit: (UuidAction<Action>) -> Void
  private let uuid: UUID

  private let webview: WKWebView
  private let disposeBag = DisposeBag()
  private let scheduler = ConcurrentDispatchQueueScheduler(qos: .userInitiated)
  private var isOpen = false

  private var url: URL?
  private var lastUpdateDate = Date.distantPast
  private var editorPosition = Marked(Position.beginning)
  private var previewPosition = Position.beginning
  private var scrollTop = 0

  private let userContentController = WKUserContentController()
  private let webviewMessageHandler = WebviewMessageHandler()

  private let automaticForwardMenuItem = NSMenuItem(title: "Automatic Forward Search",
                                                        action: nil,
                                                        keyEquivalent: "")
  private let automaticReverseMenuItem = NSMenuItem(title: "Automatic Reverse Search",
                                                        action: nil,
                                                        keyEquivalent: "")
  private let refreshOnWriteMenuItem = NSMenuItem(title: "Refresh on Write", action: nil, keyEquivalent: "")

  private let log = OSLog(subsystem: Defs.loggerSubsystem,
                          category: Defs.LoggerCategory.uiComponents)

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func forwardSearch(position: Position) {
    self.webview.evaluateJavaScript("scrollToPosition(\(position.row), \(position.column));") { result, error in
      if let scrollTop = result as? Int {
        self.scrollTop = scrollTop
      }
    }
  }
}

// MARK: - Actions
extension PreviewTool {

  @objc func refreshNowAction(_: Any?) {
    self.emit(UuidAction(uuid: self.uuid, action: .refreshNow))
  }

  @objc func forwardSearchAction(_: Any?) {
    self.forwardSearch(position: self.editorPosition.payload)
  }

  @objc func reverseSearchAction(_: Any?) {
    self.emit(UuidAction(uuid: self.uuid, action: .reverseSearch(to: self.previewPosition)))
  }

  @objc func automaticForwardSearchAction(_ sender: NSMenuItem) {
    self.emit(UuidAction(uuid: self.uuid, action: .setAutomaticForwardSearch(to: !sender.boolState)))
  }

  @objc func automaticReverseSearchAction(_ sender: NSMenuItem) {
    self.emit(UuidAction(uuid: self.uuid, action: .setAutomaticReverseSearch(to: !sender.boolState)))
  }

  @objc func refreshOnWriteAction(_ sender: NSMenuItem) {
    self.emit(UuidAction(uuid: self.uuid, action: .setRefreshOnWrite(to: !sender.boolState)))
  }
}

private class WebviewMessageHandler: NSObject, WKScriptMessageHandler {

  var source: Observable<(Position, Int)> {
    return self.subject.asObservable()
  }

  deinit {
    self.subject.onCompleted()
  }

  func userContentController(_: WKUserContentController, didReceive message: WKScriptMessage) {
    guard let msgBody = message.body as? [String: Int] else {
      return
    }

    guard let lineBegin = msgBody["lineBegin"],
          let columnBegin = msgBody["columnBegin"],
          let scrollTop = msgBody["scrollTop"]
      else {
      return
    }

    self.subject.onNext((Position(row: lineBegin, column: columnBegin), scrollTop))
  }

  fileprivate let subject = PublishSubject<(Position, Int)>()
}
