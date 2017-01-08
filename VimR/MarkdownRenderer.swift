/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import RxSwift
import PureLayout
import CocoaMarkdown
import WebKit

fileprivate class WebviewMessageHandler: NSObject, WKScriptMessageHandler {

  enum Action {

    case scroll(lineBegin: Int, columnBegin: Int, lineEnd: Int, columnEnd: Int)
  }

  fileprivate let flow: EmbeddableComponent

  override init() {
    flow = EmbeddableComponent(source: Observable.empty())
    super.init()
  }

  func userContentController(_: WKUserContentController, didReceive message: WKScriptMessage) {
    guard let msgBody = message.body as? [String: Int] else {
      return
    }

    guard let lineBegin = msgBody["lineBegin"],
          let columnBegin = msgBody["columnBegin"],
          let lineEnd = msgBody["lineEnd"],
          let columnEnd = msgBody["columnEnd"]
      else {
      return
    }

    flow.publish(event: Action.scroll(lineBegin: lineBegin, columnBegin: columnBegin,
                                      lineEnd: lineEnd, columnEnd: columnEnd))
  }
}

class MarkdownRenderer: NSObject, Flow, PreviewRenderer {

  static let identifier = "com.qvacua.vimr.tool.preview.markdown"
  static func prefData(from dict: [String: Any]) -> StandardPrefData? {
    return PrefData(dict: dict)
  }

  struct PrefData: StandardPrefData {

    fileprivate static let identifier = "identifier"
    fileprivate static let isForwardSearchAutomatically = "is-forward-search-automatically"
    fileprivate static let isReverseSearchAutomatically = "is-reverse-search-automatically"
    fileprivate static let isRefreshOnWrite = "is-refresh-on-write"

    static let `default` = PrefData(isForwardSearchAutomatically: false,
                                    isReverseSearchAutomatically: false,
                                    isRefreshOnWrite: true)

    var isForwardSearchAutomatically: Bool
    var isReverseSearchAutomatically: Bool
    var isRefreshOnWrite: Bool

    init(isForwardSearchAutomatically: Bool, isReverseSearchAutomatically: Bool, isRefreshOnWrite: Bool) {
      self.isForwardSearchAutomatically = isForwardSearchAutomatically
      self.isReverseSearchAutomatically = isReverseSearchAutomatically
      self.isRefreshOnWrite = isRefreshOnWrite
    }

    init?(dict: [String: Any]) {
      guard PrefUtils.string(from: dict, for: PrefData.identifier) == MarkdownRenderer.identifier else {
        return nil
      }

      guard let isForward = PrefUtils.bool(from: dict, for: PrefData.isForwardSearchAutomatically) else {
        return nil
      }

      guard let isReverse = PrefUtils.bool(from: dict, for: PrefData.isReverseSearchAutomatically) else {
        return nil
      }

      guard let isRefreshOnWrite = PrefUtils.bool(from: dict, for: PrefData.isRefreshOnWrite) else {
        return nil
      }

      self.init(isForwardSearchAutomatically: isForward,
                isReverseSearchAutomatically: isReverse,
                isRefreshOnWrite: isRefreshOnWrite)
    }

    func dict() -> [String: Any] {
      return [
        PrefData.identifier: MarkdownRenderer.identifier,
        PrefData.isForwardSearchAutomatically: self.isForwardSearchAutomatically,
        PrefData.isReverseSearchAutomatically: self.isReverseSearchAutomatically,
        PrefData.isRefreshOnWrite: self.isRefreshOnWrite,
      ]
    }
  }

  fileprivate let flow: EmbeddableComponent
  fileprivate let scrollFlow: EmbeddableComponent

  fileprivate let scheduler = ConcurrentDispatchQueueScheduler(qos: .userInitiated)
  fileprivate let baseUrl = Bundle.main.resourceURL!.appendingPathComponent("markdown")
  fileprivate let extensions = Set(["md", "markdown", ])
  fileprivate let template: String

  fileprivate let userContentController = WKUserContentController()
  fileprivate let webviewMessageHandler = WebviewMessageHandler()

  fileprivate var isForwardSearchAutomatically = false
  fileprivate var isReverseSearchAutomatically = false
  fileprivate var isRefreshOnWrite = true

  fileprivate let automaticForwardMenuItem = NSMenuItem(title: "Automatic Forward Search",
                                                        action: nil,
                                                        keyEquivalent: "")
  fileprivate let automaticReverseMenuItem = NSMenuItem(title: "Automatic Reverse Search",
                                                        action: nil,
                                                        keyEquivalent: "")
  fileprivate let refreshOnWriteMenuItem = NSMenuItem(title: "Refresh on Write", action: nil, keyEquivalent: "")

  fileprivate let webview: WKWebView

  fileprivate var ignoreNextForwardSearch = false;

  fileprivate var currentEditorPosition = Position(row: 1, column: 1)
  fileprivate var currentUrl: URL?
  fileprivate var currentPreviewPosition = Position(row: 1, column: 1)

  let identifier: String = MarkdownRenderer.identifier
  var prefData: StandardPrefData? {
    return PrefData(isForwardSearchAutomatically: self.isForwardSearchAutomatically,
                    isReverseSearchAutomatically: self.isReverseSearchAutomatically,
                    isRefreshOnWrite: self.isRefreshOnWrite)
  }

  var sink: Observable<Any> {
    return self.flow.sink
  }

  var scrollSink: Observable<Any> {
    return self.scrollFlow.sink
  }

  let toolbar: NSView? = NSView(forAutoLayout: ())
  let menuItems: [NSMenuItem]?

  init(source: Observable<Any>, scrollSource: Observable<Any>, initialData: PrefData) {
    guard let templateUrl = Bundle.main.url(forResource: "template",
                                            withExtension: "html",
                                            subdirectory: "markdown")
      else {
      preconditionFailure("ERROR Cannot load markdown template")
    }

    guard let template = try? String(contentsOf: templateUrl) else {
      preconditionFailure("ERROR Cannot load markdown template")
    }

    self.template = template

    self.flow = EmbeddableComponent(source: source)
    self.scrollFlow = EmbeddableComponent(source: scrollSource)

    let configuration = WKWebViewConfiguration()
    configuration.userContentController = self.userContentController
    self.webview = WKWebView(frame: .zero, configuration: configuration)
    self.webview.configureForAutoLayout()

    self.isForwardSearchAutomatically = initialData.isForwardSearchAutomatically
    self.isReverseSearchAutomatically = initialData.isReverseSearchAutomatically
    self.isRefreshOnWrite = initialData.isRefreshOnWrite

    let refreshMenuItem = NSMenuItem(title: "Refresh Now", action: nil, keyEquivalent: "")
    let forwardSearchMenuItem = NSMenuItem(title: "Forward Search", action: nil, keyEquivalent: "")
    let reverseSearchMenuItem = NSMenuItem(title: "Reverse Search", action: nil, keyEquivalent: "")

    let automaticForward = self.automaticForwardMenuItem
    let automaticReverse = self.automaticReverseMenuItem
    let refreshOnWrite = self.refreshOnWriteMenuItem

    automaticForward.boolState = self.isForwardSearchAutomatically
    automaticReverse.boolState = self.isReverseSearchAutomatically
    refreshOnWrite.boolState = self.isRefreshOnWrite

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

    super.init()

    self.initCustomUiElements()

    refreshMenuItem.target = self
    refreshMenuItem.action = #selector(MarkdownRenderer.refreshNowAction)
    forwardSearchMenuItem.target = self
    forwardSearchMenuItem.action = #selector(MarkdownRenderer.forwardSearchAction)
    reverseSearchMenuItem.target = self
    reverseSearchMenuItem.action = #selector(MarkdownRenderer.reverseSearchAction)
    automaticForward.target = self
    automaticForward.action = #selector(MarkdownRenderer.automaticForwardSearchAction)
    automaticReverse.target = self
    automaticReverse.action = #selector(MarkdownRenderer.automaticReverseSearchAction)
    refreshOnWrite.target = self
    refreshOnWrite.action = #selector(MarkdownRenderer.refreshOnWriteAction)

    self.flow.set(subscription: self.subscription)
    self.scrollFlow.set(subscription: self.scrollSubscription)

    self.addReactions()
    self.userContentController.add(webviewMessageHandler, name: "com_vimr_preview_markdown")
  }

  func canRender(fileExtension: String) -> Bool {
    return extensions.contains(fileExtension)
  }

  fileprivate func subscription(source: Observable<Any>) -> Disposable {
    return source
      .observeOn(self.scheduler)
      .mapOmittingNil { (action) -> URL? in

        switch action {
        case let PreviewComponent.Action.automaticRefresh(url):
          guard self.isRefreshOnWrite else {
            return nil
          }

          return url

        default:
          return nil

        }
      }
      .subscribe(onNext: { [unowned self] url in
        self.currentUrl = url

        guard self.canRender(fileExtension: url.pathExtension) else {
          return
        }

        self.render(from: url)
      })
  }

  fileprivate func initCustomUiElements() {
    let refresh = NSButton(forAutoLayout: ())
    InnerToolBar.configureToStandardIconButton(button: refresh, iconName: .refresh)
    refresh.toolTip = "Refresh Now"
    refresh.target = self
    refresh.action = #selector(MarkdownRenderer.refreshNowAction)

    let forward = NSButton(forAutoLayout: ())
    InnerToolBar.configureToStandardIconButton(button: forward, iconName: .chevronCircleRight)
    forward.toolTip = "Forward Search"
    forward.target = self
    forward.action = #selector(MarkdownRenderer.forwardSearchAction)

    let reverse = NSButton(forAutoLayout: ())
    InnerToolBar.configureToStandardIconButton(button: reverse, iconName: .chevronCircleLeft)
    reverse.toolTip = "Reverse Search"
    reverse.target = self
    reverse.action = #selector(MarkdownRenderer.reverseSearchAction)

    self.toolbar?.addSubview(forward)
    self.toolbar?.addSubview(reverse)
    self.toolbar?.addSubview(refresh)

    forward.autoPinEdge(toSuperviewEdge: .top)
    forward.autoPinEdge(toSuperviewEdge: .right)

    reverse.autoPinEdge(toSuperviewEdge: .top)
    reverse.autoPinEdge(.right, to: .left, of: forward)

    refresh.autoPinEdge(toSuperviewEdge: .top)
    refresh.autoPinEdge(.right, to: .left, of: reverse)
  }

  fileprivate func scrollSubscription(source: Observable<Any>) -> Disposable {
    return source
      .throttle(0.75, latest: true, scheduler: MainScheduler.instance)
      .filter { $0 is MainWindowComponent.ScrollAction }
      .map { $0 as! MainWindowComponent.ScrollAction }
      .subscribe(onNext: { [unowned self] action in
        switch action {
        case let .scroll(to: position), let .cursor(to: position):
          self.currentEditorPosition = position
        }

        guard self.isForwardSearchAutomatically && self.ignoreNextForwardSearch == false else {
          self.ignoreNextForwardSearch = false
          return
        }

        self.forwardSearch(position: self.currentEditorPosition)
      })
  }

  fileprivate func addReactions() {
    self.webviewMessageHandler.flow.sink
      .throttle(0.75, latest: true, scheduler: MainScheduler.instance)
      .filter { $0 is WebviewMessageHandler.Action }
      .map { $0 as! WebviewMessageHandler.Action }
      .subscribe(onNext: { [weak self] action in
        switch action {
        case let .scroll(lineBegin, columnBegin, _, _):
          self?.currentPreviewPosition = Position(row: lineBegin, column: columnBegin)

          guard self?.isReverseSearchAutomatically == true else {
            return
          }

          if self?.isForwardSearchAutomatically == true {
            self?.ignoreNextForwardSearch = true
          }

          self?.flow.publish(
            event: PreviewRendererAction.reverseSearch(to: Position(row: lineBegin, column: columnBegin))
          )
        }
      })
      .addDisposableTo(self.flow.disposeBag)
  }

  fileprivate func filledTemplate(body: String, title: String) -> String {
    return self.template
      .replacingOccurrences(of: "{{ title }}", with: title)
      .replacingOccurrences(of: "{{ body }}", with: body)
  }

  fileprivate func render(from url: URL) {
    let doc = CMDocument(contentsOfFile: url.path, options: .sourcepos)
    let renderer = CMHTMLRenderer(document: doc)

    guard let body = renderer?.render() else {
      self.flow.publish(event: PreviewRendererAction.error)
      return
    }

    let html = filledTemplate(body: body, title: url.lastPathComponent)
    self.webview.loadHTMLString(html, baseURL: self.baseUrl)

    try? html.write(toFile: "/tmp/markdown-preview.html", atomically: false, encoding: .utf8)
    self.flow.publish(event: PreviewRendererAction.view(renderer: self, view: self.webview))
  }
}

// MARK: - Actions
extension MarkdownRenderer {

  fileprivate func forwardSearch(position: Position) {
    self.webview.evaluateJavaScript("scrollToPosition(\(position.row), \(position.column));")
  }

  func refreshNowAction(_: Any?) {
    guard let url = self.currentUrl else {
      return
    }

    guard self.canRender(fileExtension: url.pathExtension) else {
      return
    }

    self.render(from: url)
  }

  func forwardSearchAction(_: Any?) {
    self.forwardSearch(position: self.currentEditorPosition)
  }

  func reverseSearchAction(_: Any?) {
    self.flow.publish(event: PreviewRendererAction.reverseSearch(to: self.currentPreviewPosition))
  }

  func automaticForwardSearchAction(_: Any?) {
    self.isForwardSearchAutomatically = !self.isForwardSearchAutomatically
    self.automaticForwardMenuItem.boolState = self.isForwardSearchAutomatically
  }

  func automaticReverseSearchAction(_: Any?) {
    self.isReverseSearchAutomatically = !self.isReverseSearchAutomatically
    self.automaticReverseMenuItem.boolState = self.isReverseSearchAutomatically
  }

  func refreshOnWriteAction(_: Any?) {
    self.isRefreshOnWrite = !self.isRefreshOnWrite
    self.refreshOnWriteMenuItem.boolState = self.isRefreshOnWrite
  }
}
