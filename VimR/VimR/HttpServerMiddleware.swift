/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import Swifter
import os

class HttpServerMiddleware {

  let htmlPreview: HtmlPreviewMiddleware
  let markdownPreview: MarkdownPreviewMiddleware

  init(port: Int) {
    let localhost = "127.0.0.1"

    // We know that the URL is valid!
    let baseUrl = URL(string: "http://\(localhost):\(port)")!

    let resourceUrl = Bundle.main.resourceURL!
    let cssUrl = resourceUrl.appendingPathComponent("markdown/github-markdown.css")

    let server = HttpServer()
    server.listenAddressIPv4 = localhost

    self.htmlPreview = HtmlPreviewMiddleware(server: server, baseUrl: baseUrl, cssUrl: cssUrl)
    self.markdownPreview = MarkdownPreviewMiddleware(
      server: server,
      baseUrl: baseUrl,
      cssUrl: cssUrl
    )

    do {
      try server.start(in_port_t(port), forceIPv4: true)
      self.log.info("VimR http server started on \(baseUrl)")

      let previewResourceUrl = resourceUrl.appendingPathComponent("preview")

      server["\(MarkdownReducer.basePath)/:path"] = shareFilesFromDirectory(previewResourceUrl.path)
      server.GET["\(MarkdownReducer.basePath)/github-markdown.css"] = shareFile(cssUrl.path)

      server["\(HtmlPreviewToolReducer.basePath)/:path"] = shareFilesFromDirectory(
        previewResourceUrl.path
      )
      server.GET["\(HtmlPreviewToolReducer.basePath)/github-markdown.css"] = shareFile(cssUrl.path)
    } catch {
      self.log.error("Server could not be started on port \(port): \(error)")
    }
  }

  private let log = OSLog(subsystem: Defs.loggerSubsystem,
                          category: Defs.LoggerCategory.middleware)

  class HtmlPreviewMiddleware: MiddlewareType {

    typealias StateType = MainWindow.State
    typealias ActionType = UuidAction<HtmlPreviewTool.Action>

    init(server: HttpServer, baseUrl: URL, cssUrl: URL) {
      self.server = server
      self.baseUrl = baseUrl
      self.cssUrl = cssUrl
    }

    func typedApply(_ reduce: @escaping TypedActionReduceFunction) -> TypedActionReduceFunction {
      { tuple in
        let result = reduce(tuple)

        guard case .selectHtmlFile = tuple.action.payload else { return result }

        let state = result.state
        guard let serverUrl = state.htmlPreview.server,
              let htmlFileUrl = state.htmlPreview.htmlFile else { return result }

        let basePath = serverUrl.payload.deletingLastPathComponent().path

        self.server.GET[serverUrl.payload.path] = shareFile(htmlFileUrl.path)
        self.server["\(basePath)/:path"] = shareFilesFromDirectory(htmlFileUrl.parent.path)

        self.log.info(
          "Serving on \(self.fullUrl(with: serverUrl.payload.path)) the HTML file \(htmlFileUrl)"
        )

        return result
      }
    }

    private let server: HttpServer
    private let baseUrl: URL
    private let cssUrl: URL

    private let log = OSLog(subsystem: Defs.loggerSubsystem,
                            category: Defs.LoggerCategory.middleware)

    private func fullUrl(with path: String) -> URL { self.baseUrl.appendingPathComponent(path) }
  }

  class MarkdownPreviewMiddleware: MiddlewareType {

    typealias StateType = MainWindow.State
    typealias ActionType = UuidAction<MainWindow.Action>

    init(server: HttpServer, baseUrl: URL, cssUrl: URL) {
      self.server = server
      self.baseUrl = baseUrl
      self.cssUrl = cssUrl
    }

    func typedApply(_ reduce: @escaping TypedActionReduceFunction) -> TypedActionReduceFunction {
      { tuple in
        let result = reduce(tuple)

        let uuidAction = tuple.action
        guard case .newCurrentBuffer = uuidAction.payload else { return result }

        let preview = result.state.preview
        guard case .markdown = preview.status,
              let buffer = preview.buffer,
              let html = preview.html,
              let server = preview.server else { return result }

        self.log.debug("Serving \(html) on \(server)")
        let htmlBasePath = server.deletingLastPathComponent().path

        self.server["\(htmlBasePath)/:path"] = shareFilesFromDirectory(
          buffer.deletingLastPathComponent().path
        )
        self.server.GET[server.path] = shareFile(html.path)
        self.server.GET["\(htmlBasePath)/github-markdown.css"] = shareFile(self.cssUrl.path)

        self.log.info("Serving on \(self.fullUrl(with: server.path)) the markdown file \(buffer)")

        return result
      }
    }

    private let server: HttpServer
    private let baseUrl: URL
    private let cssUrl: URL

    private let log = OSLog(subsystem: Defs.loggerSubsystem,
                            category: Defs.LoggerCategory.middleware)

    private func fullUrl(with path: String) -> URL { self.baseUrl.appendingPathComponent(path) }
  }
}
