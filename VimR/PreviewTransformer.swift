/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import CocoaMarkdown
import RxSwift
import Swifter
import CocoaMarkdown

// Currently supports only markdown
class PreviewTransformer: Transformer {

  typealias Pair = StateActionPair<UuidState<MainWindow.State>, MainWindow.Action>

  func transform(_ source: Observable<Pair>) -> Observable<Pair> {
    return source.map { pair in
      let uuid = pair.state.uuid
      var state = pair.state.payload

      switch pair.action {

      case let .setCurrentBuffer(buffer):
        guard let url = buffer.url else {
          return pair
        }

        guard FileUtils.fileExists(at: url) else {
          return pair
        }

      case .close:
        break

      default:
        return pair
      }

      return StateActionPair(state: UuidState(uuid: pair.state.uuid, state: state), action: pair.action)
    }
  }

  fileprivate func render(from url: URL) {
//    let doc = CMDocument(contentsOfFile: url.path, options: .sourcepos)
//    let renderer = CMHTMLRenderer(document: doc)
//
//    guard let body = renderer?.render() else {
//      self.flow.publish(event: PreviewRendererAction.error)
//      return
//    }
//
//    let html = filledTemplate(body: body, title: url.lastPathComponent)
//    let htmlFilePath = self.htmlFileUrl().path
//    do {
//      try html.write(toFile: htmlFilePath, atomically: true, encoding: .utf8)
//    } catch {
//      NSLog("ERROR \(#function): could not write preview file to \(htmlFilePath)")
//      self.flow.publish(event: PreviewRendererAction.error(renderer: self))
//      return
//    }
//
//    self.httpServer["/\(MarkdownRenderer.serverPath)/\(self.uuid)/:path"] =
//    shareFilesFromDirectory(url.deletingLastPathComponent().path)
//
//    self.httpServer.GET["/\(MarkdownRenderer.serverPath)/\(self.uuid)/index.html"] = shareFile(htmlFilePath)
//
//    let urlRequest = URLRequest(
//      url: URL(string: "http://localhost:\(self.port)/\(MarkdownRenderer.serverPath)/\(self.uuid)/index.html")!
//    )
//    self.webview.load(urlRequest)
//
//    self.flow.publish(event: PreviewRendererAction.view(renderer: self, view: self.webview))
  }

  fileprivate let extensions = Set(["md", "markdown"])
}
