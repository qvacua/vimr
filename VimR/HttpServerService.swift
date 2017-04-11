/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import Swifter
import RxSwift

class HttpServerService {

  let forMainWindow: MainWindowService
  let forHtmlPreviewTool: HtmlPreviewService

  init(port: Int) {
    self.forMainWindow = MainWindowService(server: self.server)
    self.forHtmlPreviewTool = HtmlPreviewService(server: self.server)

    do {
      try self.server.start(in_port_t(port))
      NSLog("server started on http://localhost:\(port)")

      let resourceUrl = Bundle.main.resourceURL!
      let previewResourceUrl = resourceUrl.appendingPathComponent("preview")

      let githubCssUrl = resourceUrl.appendingPathComponent("markdown/github-markdown.css")

      self.server["\(MarkdownReducer.basePath)/:path"] = shareFilesFromDirectory(previewResourceUrl.path)
      self.server.GET["\(MarkdownReducer.basePath)/github-markdown.css"] = shareFile(githubCssUrl.path)

      self.server["\(HtmlPreviewToolReducer.basePath)/:path"] = shareFilesFromDirectory(previewResourceUrl.path)
      self.server.GET["\(HtmlPreviewToolReducer.basePath)/github-markdown.css"] = shareFile(githubCssUrl.path)
    } catch {
      NSLog("ERROR server could not be started on port \(port)")
    }
  }

  fileprivate let server = HttpServer()
}

extension HttpServerService {

  class HtmlPreviewService: Service {

    typealias Pair = StateActionPair<UuidState<MainWindow.State>, HtmlPreviewTool.Action>

    init(server: HttpServer) {
      self.server = server
    }

    func apply(_ pair: Pair) {
      let state = pair.state.payload

      guard let serverUrl = state.htmlPreview.server, let htmlFileUrl = state.htmlPreview.htmlFile else {
        return
      }

      let basePath = serverUrl.payload.deletingLastPathComponent().path

      self.server.GET[serverUrl.payload.path] = shareFile(htmlFileUrl.path)
      self.server["\(basePath)/:path"] = shareFilesFromDirectory(htmlFileUrl.parent.path)
    }

    fileprivate let server: HttpServer
  }

  class MainWindowService: Service {

    typealias Pair = StateActionPair<UuidState<MainWindow.State>, MainWindow.Action>

    init(server: HttpServer) {
      self.server = server
      
      let resourceUrl = Bundle.main.resourceURL!
      self.githubCssUrl = resourceUrl.appendingPathComponent("markdown/github-markdown.css")
    }

    func apply(_ pair: Pair) {
      guard case .setCurrentBuffer = pair.action else {
        return
      }

      let preview = pair.state.payload.preview
      guard case .markdown = preview.status,
            let buffer = preview.buffer,
            let html = preview.html,
            let server = preview.server
        else {
        return
      }

      NSLog("Serving \(html) on \(server)")

      let htmlBasePath = server.deletingLastPathComponent().path

      self.server["\(htmlBasePath)/:path"] = shareFilesFromDirectory(buffer.deletingLastPathComponent().path)
      self.server.GET[server.path] = shareFile(html.path)
      self.server.GET["\(htmlBasePath)/github-markdown.css"] = shareFile(self.githubCssUrl.path)
    }

    fileprivate let server: HttpServer
    fileprivate let githubCssUrl: URL
  }

}

fileprivate func shareFile(_ path: String) -> ((HttpRequest) -> HttpResponse) {
  return { r in
    guard let file = try? path.openForReading() else {
      return .notFound
    }

    return .raw(200, "OK", [:], { writer in
      try? writer.write(file)
      file.close()
    })
  }
}
