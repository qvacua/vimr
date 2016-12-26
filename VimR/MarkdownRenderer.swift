/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import RxSwift
import PureLayout
import CocoaMarkdown

protocol PreviewRenderer: class {

}

enum PreviewRendererAction {

  case htmlString(renderer: PreviewRenderer, html: String, baseUrl: URL)
  case error(renderer: PreviewRenderer)
}

class MarkdownRenderer: StandardFlow, PreviewRenderer {

  fileprivate let scheduler = ConcurrentDispatchQueueScheduler(qos: .userInitiated)
  fileprivate let baseUrl = Bundle.main.resourceURL!.appendingPathComponent("markdown")
  fileprivate let extensions = Set(["md", "markdown", ])
  fileprivate let template: String

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

    super.init(source: source)
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
      .filter { $0 is PreviewAction }
      .map { $0 as! PreviewAction }
      .map { action in
        switch action {
        case let .automaticRefresh(url):
          return url
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

    try? html.write(toFile: "/tmp/markdown-preview.html", atomically: false, encoding: .utf8)
    self.publish(event: PreviewRendererAction.htmlString(renderer: self, html: html, baseUrl: self.baseUrl))
  }
}
