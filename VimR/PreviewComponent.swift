/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import RxSwift
import PureLayout
import WebKit

enum PreviewAction {

  case refresh(url: URL)
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
    self.markdownRenderer = MarkdownRenderer(source: self.flow.sink)

    super.init(frame: .zero)
    self.configureForAutoLayout()

    self.flow.set(subscription: self.subscription)


    self.webview.loadHTMLString(self.previewService.emptyPreview(), baseURL: nil)

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

        case let .currentBufferChanged(mainWindow, currentBuffer):
          guard let url = currentBuffer.url else {
            return
          }

          self.flow.publish(event: PreviewAction.refresh(url: url))

        default:
          return

        }
      })
  }

  fileprivate func addReactions() {
    self.markdownRenderer.sink
      .filter { $0 is PreviewRendererAction }
      .map { $0 as! PreviewRendererAction }
      .subscribe(onNext: { action in
        switch action {

        case let .htmlString(html):
          self.webview.loadHTMLString(html, baseURL: nil)

        case .error:
          self.webview.loadHTMLString(self.previewService.emptyPreview(), baseURL: nil)

        }
      })
      .addDisposableTo(self.flow.disposeBag)
  }
}
