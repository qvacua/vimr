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

  case htmlString(renderer: PreviewRenderer, html: String)
  case error(renderer: PreviewRenderer)
}

class MarkdownRenderer: StandardFlow, PreviewRenderer {

  fileprivate let extensions = Set([ "md", "markdown", ])

  fileprivate func canRender(fileExtension: String) -> Bool {
    return extensions.contains(fileExtension)
  }

  override func subscription(source: Observable<Any>) -> Disposable {
    return source
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
    let doc = CMDocument(contentsOfFile: url.path)
    let renderer = CMHTMLRenderer(document: doc)

    guard let html = renderer?.render() else {
      self.publish(event: PreviewRendererAction.error)
      return
    }

    self.publish(event: PreviewRendererAction.htmlString(renderer: self, html: html))
  }
}
