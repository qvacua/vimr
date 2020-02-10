/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import Swifter
import os

class HttpServerMiddleware {

  let htmlPreview: HtmlPreviewMiddleware
  let mainWindow: MainWindowMiddleware

  init(port: Int) {
    let server = HttpServer()
    server.listenAddressIPv4 = "127.0.0.1"

    let resourceUrl = Bundle.main.resourceURL!
    let githubCssUrl = resourceUrl.appendingPathComponent("markdown/github-markdown.css")

    self.htmlPreview = HtmlPreviewMiddleware(server: server, githubCssUrl: githubCssUrl)
    self.mainWindow = MainWindowMiddleware(server: server, githubCssUrl: githubCssUrl)

    do {
      try server.start(in_port_t(port), forceIPv4: true)
      self.log.info("VimR http server started on http://localhost:\(port)")

      let previewResourceUrl = resourceUrl.appendingPathComponent("preview")

      server["\(MarkdownReducer.basePath)/:path"] = shareFilesFromDirectory(previewResourceUrl.path)
      server.GET["\(MarkdownReducer.basePath)/github-markdown.css"] = shareFile(githubCssUrl.path)

      server["\(HtmlPreviewToolReducer.basePath)/:path"] = shareFilesFromDirectory(previewResourceUrl.path)
      server.GET["\(HtmlPreviewToolReducer.basePath)/github-markdown.css"] = shareFile(githubCssUrl.path)
    } catch {
      self.log.error("Server could not be started on port \(port): \(error)")
    }
  }

  private let log = OSLog(subsystem: Defs.loggerSubsystem,
                          category: Defs.LoggerCategory.middleware)

  class HtmlPreviewMiddleware: MiddlewareType {

    typealias StateType = MainWindow.State
    typealias ActionType = UuidAction<HtmlPreviewTool.Action>

    init(server: HttpServer, githubCssUrl: URL) {
      self.server = server
      self.githubCssUrl = githubCssUrl
    }

    func typedApply(_ reduce: @escaping TypedActionReduceFunction) -> TypedActionReduceFunction {
      return { tuple in
        let result = reduce(tuple)

        guard case .selectHtmlFile = tuple.action.payload else {
          return result
        }

        let state = result.state
        guard let serverUrl = state.htmlPreview.server, let htmlFileUrl = state.htmlPreview.htmlFile else {
          return result
        }

        self.log.debug("Serving \(htmlFileUrl) on \(serverUrl)")
        let basePath = serverUrl.payload.deletingLastPathComponent().path

        self.server.GET[serverUrl.payload.path] = shareFile(htmlFileUrl.path)
        self.server["\(basePath)/:path"] = shareFilesFromDirectory(htmlFileUrl.parent.path)

        return result
      }
    }

    private let server: HttpServer
    private let githubCssUrl: URL

    private let log = OSLog(subsystem: Defs.loggerSubsystem,
                            category: Defs.LoggerCategory.middleware)
  }

  class MainWindowMiddleware: MiddlewareType {

    typealias StateType = MainWindow.State
    typealias ActionType = UuidAction<MainWindow.Action>

    init(server: HttpServer, githubCssUrl: URL) {
      self.server = server
      self.githubCssUrl = githubCssUrl
    }

    func typedApply(_ reduce: @escaping TypedActionReduceFunction) -> TypedActionReduceFunction {
      return { tuple in
        let result = reduce(tuple)

        let uuidAction = tuple.action
        guard case .newCurrentBuffer = uuidAction.payload else {
          return result
        }

        let preview = result.state.preview
        guard case .markdown = preview.status,
              let buffer = preview.buffer,
              let html = preview.html,
              let server = preview.server else {

          return result
        }

        self.log.debug("Serving \(html) on \(server)")
        let htmlBasePath = server.deletingLastPathComponent().path

        self.server["\(htmlBasePath)/:path"] = shareFilesFromDirectory(buffer.deletingLastPathComponent().path)
        self.server.GET[server.path] = shareFile(html.path)
        self.server.GET["\(htmlBasePath)/github-markdown.css"] = shareFile(self.githubCssUrl.path)

        return result
      }
    }

    private let server: HttpServer
    private let githubCssUrl: URL

    private let log = OSLog(subsystem: Defs.loggerSubsystem,
                            category: Defs.LoggerCategory.middleware)
  }
}
