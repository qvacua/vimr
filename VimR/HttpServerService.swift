/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import Swifter
import RxSwift

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

class HttpService {

  let forMainWindow: MainWindowHttpServerService
  let forHtmlPreviewTool: HtmlPreviewToolHttpServerService

  init(port: Int) {
    self.forMainWindow = MainWindowHttpServerService(server: self.server)
    self.forHtmlPreviewTool = HtmlPreviewToolHttpServerService(server: self.server)

    do {
      try self.server.start(in_port_t(port))
      NSLog("server started on http://localhost:\(port)")
    } catch {
      NSLog("ERROR server could not be started on port \(port)")
    }
  }

  fileprivate let server = HttpServer()
}

class HtmlPreviewToolHttpServerService: Service {

  typealias Pair = StateActionPair<UuidState<MainWindow.State>, HtmlPreviewTool.Action>

  init(server: HttpServer) {
    self.server = server
    let resourceUrl = Bundle.main.resourceURL!
    let previewResourceUrl = resourceUrl.appendingPathComponent("preview")

    self.githubCssUrl = resourceUrl.appendingPathComponent("markdown/github-markdown.css")

    self.server["\(PreviewReducer.basePath)/:path"] = shareFilesFromDirectory(previewResourceUrl.path)
    self.server.GET["\(PreviewReducer.basePath)/github-markdown.css"] = shareFile(self.githubCssUrl.path)
  }

  func apply(_ pair: Pair) {
  }

  fileprivate let server: HttpServer
  fileprivate let githubCssUrl: URL
}

class MainWindowHttpServerService: Service {

  typealias Pair = StateActionPair<UuidState<MainWindow.State>, MainWindow.Action>

  init(server: HttpServer) {
    self.server = server
    let resourceUrl = Bundle.main.resourceURL!
    let previewResourceUrl = resourceUrl.appendingPathComponent("preview")

    self.githubCssUrl = resourceUrl.appendingPathComponent("markdown/github-markdown.css")

    self.server["\(PreviewReducer.basePath)/:path"] = shareFilesFromDirectory(previewResourceUrl.path)
    self.server.GET["\(PreviewReducer.basePath)/github-markdown.css"] = shareFile(self.githubCssUrl.path)
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
