/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import Swifter

class HttpServerService {

  typealias HtmlPreviewPair = StateActionPair<UuidState<MainWindow.State>, HtmlPreviewTool.Action>
  typealias MainWindowPair = StateActionPair<UuidState<MainWindow.State>, MainWindow.Action>

  init(port: Int) {
    let resourceUrl = Bundle.main.resourceURL!
    self.githubCssUrl = resourceUrl.appendingPathComponent("markdown/github-markdown.css")

    do {
      try self.server.start(in_port_t(port))
      stdoutLog.info("VimR http server started on http://localhost:\(port)")

      let previewResourceUrl = resourceUrl.appendingPathComponent("preview")

      self.server["\(MarkdownReducer.basePath)/:path"] = shareFilesFromDirectory(previewResourceUrl.path)
      self.server.GET["\(MarkdownReducer.basePath)/github-markdown.css"] = shareFile(githubCssUrl.path)

      self.server["\(HtmlPreviewToolReducer.basePath)/:path"] = shareFilesFromDirectory(previewResourceUrl.path)
      self.server.GET["\(HtmlPreviewToolReducer.basePath)/github-markdown.css"] = shareFile(githubCssUrl.path)
    } catch {
      NSLog("ERROR server could not be started on port \(port)")
    }
  }

  func applyHtmlPreview(_ pair: HtmlPreviewPair) {
    let state = pair.state.payload

    guard let serverUrl = state.htmlPreview.server, let htmlFileUrl = state.htmlPreview.htmlFile else {
      return
    }

    let basePath = serverUrl.payload.deletingLastPathComponent().path

    self.server.GET[serverUrl.payload.path] = shareFile(htmlFileUrl.path)
    self.server["\(basePath)/:path"] = shareFilesFromDirectory(htmlFileUrl.parent.path)
  }

  func applyMainWindow(_ pair: MainWindowPair) {
    guard case .newCurrentBuffer = pair.action else {
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

    fileLog.debug("Serving \(html) on \(server)")

    let htmlBasePath = server.deletingLastPathComponent().path

    self.server["\(htmlBasePath)/:path"] = shareFilesFromDirectory(buffer.deletingLastPathComponent().path)
    self.server.GET[server.path] = shareFile(html.path)
    self.server.GET["\(htmlBasePath)/github-markdown.css"] = shareFile(self.githubCssUrl.path)
  }

  private let server = HttpServer()
  private let githubCssUrl: URL
}
