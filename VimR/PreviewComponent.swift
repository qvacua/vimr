/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import RxSwift
import PureLayout
import WebKit

enum PreviewAction {

  case automaticRefresh(url: URL)
}

struct PreviewPrefData: StandardPrefData {

  static let `default` = PreviewPrefData()

  init() {
  }

  init?(dict: [String: Any]) {
    self.init()
  }

  func dict() -> [String: Any] {
    return [:]
  }
}

class PreviewComponent: NSView, ViewComponent {

  fileprivate let flow: EmbeddableComponent

  fileprivate let previewService = PreviewService()
  fileprivate let markdownRenderer: MarkdownRenderer

  fileprivate let webview = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())

  fileprivate let baseUrl: URL

  fileprivate var currentRenderer: PreviewRenderer?

  fileprivate let renderers: [PreviewRenderer]

  fileprivate var isOpen = false

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  var sink: Observable<Any> {
    return self.flow.sink
  }

  var view: NSView {
    return self
  }

  init(source: Observable<Any>) {
    self.flow = EmbeddableComponent(source: source)

    self.baseUrl = self.previewService.baseUrl()
    self.markdownRenderer = MarkdownRenderer(source: self.flow.sink)

    self.renderers = [
      self.markdownRenderer,
    ]

    super.init(frame: .zero)
    self.configureForAutoLayout()

    self.flow.set(subscription: self.subscription)

    self.webview.loadHTMLString(self.previewService.emptyHtml(), baseURL: self.baseUrl)

    self.addViews()
    self.addReactions()
  }

  fileprivate func addViews() {
    let webview = self.webview
    webview.configureForAutoLayout()

    self.addSubview(webview)

    webview.autoPinEdgesToSuperviewEdges()
  }

  fileprivate func subscription(source: Observable<Any>) -> Disposable {
    return source
      .filter { $0 is MainWindowAction }
      .map { $0 as! MainWindowAction }
      .subscribe(onNext: { action in
        switch action {

        case let .currentBufferChanged(_, currentBuffer):
          guard let url = currentBuffer.url else {
            return
          }

          guard self.isOpen else {
            return
          }

          self.flow.publish(event: PreviewAction.automaticRefresh(url: url))

        case let .toggleTool(tool):
          guard tool.view == self else {
            return
          }
          self.isOpen = tool.isSelected

        default:
          return

        }
      })
  }

  fileprivate func addReactions() {
    self.markdownRenderer.sink
      .filter { $0 is PreviewRendererAction }
      .map { $0 as! PreviewRendererAction }
      .observeOn(MainScheduler.instance)
      .subscribe(onNext: { [unowned self] action in
        guard self.isOpen else {
          return
        }

        switch action {

        case let .htmlString(_, html, baseUrl):
          self.webview.loadHTMLString(html, baseURL: baseUrl)

        case .error:
          self.webview.loadHTMLString(self.previewService.errorHtml(), baseURL: self.baseUrl)

        }
      })
      .addDisposableTo(self.flow.disposeBag)
  }
}
