/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import RxSwift
import PureLayout
import CocoaMarkdown

enum PreviewRendererAction {

  case htmlString(html: String)
  case error
}

class MarkdownRenderer: StandardFlow {

  override func subscription(source: Observable<Any>) -> Disposable {
    return source
      .filter { $0 is PreviewAction }
      .map { $0 as! PreviewAction }
      .subscribe(onNext: { action in
        switch action {
        case let .refresh(url):
          self.render(from: url)

        }
      })
  }

  fileprivate func render(from url: URL) {
    let doc = CMDocument(contentsOfFile: url.path)
    let renderer = CMHTMLRenderer(document: doc)

    guard let html = renderer?.render() else {
      self.publish(event: PreviewRendererAction.error)
      return
    }

    self.publish(event: PreviewRendererAction.htmlString(html: html))
  }
}
