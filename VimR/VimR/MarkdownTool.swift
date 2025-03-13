/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import Combine
import NvimView
import os
import PureLayout
import WebKit

final class MarkdownTool: NSView, UiComponent, WKNavigationDelegate {
  typealias StateType = MainWindow.State

  enum Action {
    case refreshNow
    case reverseSearch(to: Position)

    case scroll(to: Position)

    case setAutomaticReverseSearch(to: Bool)
    case setAutomaticForwardSearch(to: Bool)
    case setRefreshOnWrite(to: Bool)
  }

  let uuid = UUID()
  let mainWinUuid: UUID
  let menuItems: [NSMenuItem]

  required init(context: ReduxContext, emitter: ActionEmitter, state: StateType) {
    self.context = context
    self.emit = emitter.typedEmit()
    self.mainWinUuid = state.uuid

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
    refreshMenuItem.action = #selector(MarkdownTool.refreshNowAction)
    forwardSearchMenuItem.target = self
    forwardSearchMenuItem.action = #selector(MarkdownTool.forwardSearchAction)
    reverseSearchMenuItem.target = self
    reverseSearchMenuItem.action = #selector(MarkdownTool.reverseSearchAction)
    automaticForward.target = self
    automaticForward.action = #selector(MarkdownTool.automaticForwardSearchAction)
    automaticReverse.target = self
    automaticReverse.action = #selector(MarkdownTool.automaticReverseSearchAction)
    refreshOnWrite.target = self
    refreshOnWrite.action = #selector(MarkdownTool.refreshOnWriteAction)

    self.addViews()
    self.webview.navigationDelegate = self
    if let url = state.preview.server { self.webview.load(URLRequest(url: url)) }

    context.subscribe(uuid: self.uuid) { appState in
      guard let state = appState.mainWindows[self.mainWinUuid] else { return }

      if state.viewToBeFocused != nil,
         case .markdownPreview = state.viewToBeFocused!
      {
        self.beFirstResponder()
      }

      self.automaticForwardMenuItem.boolState = state.previewTool.isForwardSearchAutomatically
      self.automaticReverseMenuItem.boolState = state.previewTool.isReverseSearchAutomatically
      self.refreshOnWriteMenuItem.boolState = state.previewTool.isRefreshOnWrite

      if state.preview.status == .markdown,
         state.previewTool.isForwardSearchAutomatically,
         state.preview.editorPosition.hasDifferentMark(as: self.editorPosition)
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
    }

    self.webviewMessageHandler.source
      .throttle(for: .milliseconds(750), scheduler: RunLoop.main, latest: true)
      .sink(receiveValue: { [weak self] position, scrollTop in
        guard let mainWinUuid = self?.mainWinUuid,
              let previewPosition = self?.previewPosition else { return }

        self?.previewPosition = position
        self?.scrollTop = scrollTop
        self?.emit(UuidAction(uuid: mainWinUuid, action: .scroll(to: previewPosition)))
      })
      .store(in: &self.cancellables)
  }

  func cleanup() {
    self.context.unsubscribe(uuid: self.uuid)

    self.webviewMessageHandler.subject.send(completion: .finished)
    self.cancellables.removeAll()
    self.webview.navigationDelegate = nil
    self.webview.removeFromSuperview()
  }

  private func addViews() {
    self.webview.navigationDelegate = self
    self.userContentController.add(
      self.webviewMessageHandler,
      name: "com_vimr_tools_preview_markdown"
    )
    self.webview.configureForAutoLayout()

    self.addSubview(self.webview)
    self.webview.autoPinEdgesToSuperviewEdges()
  }

  func webView(
    _: WKWebView,
    didFailProvisionalNavigation _: WKNavigation!,
    withError error: Error
  ) {
    self.log.error("ERROR preview component's webview: \(error)")
  }

  func webView(_: WKWebView, didFinish _: WKNavigation!) {
    self.webview.evaluateJavaScript("document.body.scrollTop = \(self.scrollTop)")
  }

  private let context: ReduxContext
  private let emit: (UuidAction<Action>) -> Void
  private var cancellables = Set<AnyCancellable>()

  private let webview: WKWebView
  private var isOpen = false

  private var url: URL?
  private var lastUpdateDate = Date.distantPast
  private var editorPosition = Marked(Position.beginning)
  private var previewPosition = Position.beginning
  private var scrollTop = 0

  private let userContentController = WKUserContentController()
  private let webviewMessageHandler = WebviewMessageHandler()

  private let automaticForwardMenuItem = NSMenuItem(
    title: "Automatic Forward Search",
    action: nil,
    keyEquivalent: ""
  )
  private let automaticReverseMenuItem = NSMenuItem(
    title: "Automatic Reverse Search",
    action: nil,
    keyEquivalent: ""
  )
  private let refreshOnWriteMenuItem = NSMenuItem(
    title: "Refresh on Write",
    action: nil,
    keyEquivalent: ""
  )

  private let log = OSLog(
    subsystem: Defs.loggerSubsystem,
    category: Defs.LoggerCategory.ui
  )

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func forwardSearch(position: Position) {
    self.webview
      .evaluateJavaScript("scrollToPosition(\(position.row), \(position.column));") { result, _ in
        if let scrollTop = result as? Int {
          self.scrollTop = scrollTop
        }
      }
  }
}

// MARK: - Actions

extension MarkdownTool {
  @objc func refreshNowAction(_: Any?) {
    self.emit(UuidAction(uuid: self.mainWinUuid, action: .refreshNow))
  }

  @objc func forwardSearchAction(_: Any?) {
    self.forwardSearch(position: self.editorPosition.payload)
  }

  @objc func reverseSearchAction(_: Any?) {
    self.emit(UuidAction(uuid: self.mainWinUuid, action: .reverseSearch(to: self.previewPosition)))
  }

  @objc func automaticForwardSearchAction(_ sender: NSMenuItem) {
    self
      .emit(UuidAction(
        uuid: self.mainWinUuid,
        action: .setAutomaticForwardSearch(to: !sender.boolState)
      ))
  }

  @objc func automaticReverseSearchAction(_ sender: NSMenuItem) {
    self
      .emit(UuidAction(
        uuid: self.mainWinUuid,
        action: .setAutomaticReverseSearch(to: !sender.boolState)
      ))
  }

  @objc func refreshOnWriteAction(_ sender: NSMenuItem) {
    self.emit(UuidAction(uuid: self.mainWinUuid, action: .setRefreshOnWrite(to: !sender.boolState)))
  }
}

private class WebviewMessageHandler: NSObject, WKScriptMessageHandler {
  var source: AnyPublisher<(Position, Int), Never> {
    self.subject.eraseToAnyPublisher()
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

    self.subject.send((Position(row: lineBegin, column: columnBegin), scrollTop))
  }

  fileprivate let subject = PassthroughSubject<(Position, Int), Never>()
}
