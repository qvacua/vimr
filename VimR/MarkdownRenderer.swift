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

class MarkdownRenderer: StandardFlow, PreviewRenderer {

  fileprivate let scheduler = ConcurrentDispatchQueueScheduler(qos: .userInitiated)
  fileprivate let baseUrl = Bundle.main.resourceURL!.appendingPathComponent("markdown")
  fileprivate let extensions = Set(["md", "markdown", ])
  fileprivate let template: String

  fileprivate let userContentController = WKUserContentController()
  fileprivate let webviewMessageHandler = WebviewMessageHandler()

  fileprivate let webview: WKWebView

  override init(source: Observable<Any>) {
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

    let configuration = WKWebViewConfiguration()
    configuration.userContentController = self.userContentController
    self.webview = WKWebView(frame: .zero, configuration: configuration)
    self.webview.configureForAutoLayout()

    super.init(source: source)

    self.addReactions()
    self.userContentController.add(webviewMessageHandler, name: "com_vimr_preview_markdown")
  }

  fileprivate func addReactions() {
    self.webviewMessageHandler.flow.sink
      .filter { $0 is WebviewMessageHandler.Action }
      .map { $0 as! WebviewMessageHandler.Action }
      .subscribe(onNext: { [weak self] action in
        switch action {
        case let .scroll(lineBegin, columnBegin, _, _):
          self?.publish(event: PreviewRendererAction.scroll(to: Position(row: lineBegin, column: columnBegin)))
        }
      })
      .addDisposableTo(self.disposeBag)
  }

  fileprivate func filledTemplate(body: String, title: String) -> String {
    return self.template
      .replacingOccurrences(of: "{{ title }}", with: title)
      .replacingOccurrences(of: "{{ body }}", with: body)
  }

  fileprivate func canRender(fileExtension: String) -> Bool {
    return extensions.contains(fileExtension)
  }

  override func subscription(source: Observable<Any>) -> Disposable {
    return source
      .observeOn(self.scheduler)
      .mapOmittingNil { action in

        switch action {
        case let PreviewComponent.Action.automaticRefresh(url):
          return url

        default:
          return nil

        }
      }
      .filter { self.canRender(fileExtension: $0.pathExtension) }
      .subscribe(onNext: { [unowned self] url in self.render(from: url) })
  }

  fileprivate func render(from url: URL) {

    NSLog("\(#function): \(url)")

    let doc = CMDocument(contentsOfFile: url.path, options: .sourcepos)
    let renderer = CMHTMLRenderer(document: doc)

    guard let body = renderer?.render() else {
      self.publish(event: PreviewRendererAction.error)
      return
    }

    let html = filledTemplate(body: body, title: url.lastPathComponent)
    self.webview.loadHTMLString(html, baseURL: self.baseUrl)

    try? html.write(toFile: "/tmp/markdown-preview.html", atomically: false, encoding: .utf8)
    self.publish(event: PreviewRendererAction.view(renderer: self, view: self.webview))
  }
}
