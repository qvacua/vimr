/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import os
import Swifter

final class HttpServerMiddleware {
  let htmlPreviewTool: HtmlPreviewToolMiddleware
  let htmlPreviewMainWindow: HtmlPreviewMainWindowMiddleware
  let markdownPreview: MarkdownPreviewMiddleware

  init(port: Int) {
    let localhost = "127.0.0.1"

    // We know that the URL is valid!
    let baseUrl = URL(string: "http://\(localhost):\(port)")!

    let cssOverridesTemplate = try! String(contentsOf: Resources.cssOverridesTemplateUrl)
    let selectFirstHtmlTemplate = try! String(contentsOf: Resources.selectFirstHtmlTemplateUrl)

    let server = HttpServer()
    server.listenAddressIPv4 = localhost

    let htmlTemplates = (
      selectFirst: selectFirstHtmlTemplate,
      cssOverrides: cssOverridesTemplate
    )
    self.htmlPreviewTool = HtmlPreviewToolMiddleware(
      server: server,
      baseUrl: baseUrl,
      cssUrl: Resources.cssUrl,
      htmlTemplates: htmlTemplates
    )
    self.htmlPreviewMainWindow = HtmlPreviewMainWindowMiddleware(
      server: server,
      baseUrl: baseUrl,
      cssUrl: Resources.cssUrl,
      htmlTemplates: htmlTemplates
    )
    self.markdownPreview = MarkdownPreviewMiddleware(
      server: server,
      baseUrl: baseUrl,
      cssUrl: Resources.cssUrl,
      baseCssUrl: Resources.baseCssUrl
    )

    do {
      try server.start(in_port_t(port), forceIPv4: true)
      self.log.info("VimR http server started on \(baseUrl)")

//      server["\(HtmlPreviewToolReducer.basePath)/:path"] = shareFilesFromDirectory(
//        Resources.previewUrl.path
//      )
//      server.GET["\(HtmlPreviewToolReducer.basePath)/github-markdown.css"] = shareFile(
//        Resources.cssUrl.path
//      )
    } catch {
      self.log.error("Server could not be started on port \(port): \(error)")
    }
  }

  private let log = OSLog(
    subsystem: Defs.loggerSubsystem,
    category: Defs.LoggerCategory.middleware
  )

  class HtmlPreviewMainWindowMiddleware: MiddlewareType {
    typealias StateType = MainWindow.State
    typealias ActionType = UuidAction<MainWindow.Action>

    fileprivate init(
      server: HttpServer,
      baseUrl: URL,
      cssUrl: URL,
      htmlTemplates _: HtmlTemplates
    ) {
      self.server = server
      self.baseUrl = baseUrl
      self.cssUrl = cssUrl
    }

    func typedApply(_ reduce: @escaping TypedActionReduceFunction) -> TypedActionReduceFunction {
      { tuple in
        let result = reduce(tuple)

        guard case .setTheme = tuple.action.payload else { return result }

        let state = result.state
        guard state.htmlPreview.htmlFile == nil,
              let serverUrl = state.htmlPreview.server else { return result }

        let basePath = serverUrl.payload.deletingLastPathComponent()
        self.server.GET[basePath.appendingPathComponent("github-markdown.css").path] = shareFile(
          Resources.cssUrl.path
        )
        self.server.GET[basePath.appendingPathComponent("base.css").path] = shareFile(
          Resources.baseCssUrl.path
        )
        self.server.GET[serverUrl.payload.path] = shareFile(
          HtmlPreviewMiddleware.selectFirstHtmlUrl(uuid: state.uuid).path
        )

        self.log.info("Serving on \(self.fullUrl(with: serverUrl.payload.path)) the select first")

        return result
      }
    }

    private let server: HttpServer
    private let baseUrl: URL
    private let cssUrl: URL

    private let log = OSLog(
      subsystem: Defs.loggerSubsystem,
      category: Defs.LoggerCategory.middleware
    )

    private func fullUrl(with path: String) -> URL { self.baseUrl.appendingPathComponent(path) }
  }

  class HtmlPreviewToolMiddleware: MiddlewareType {
    typealias StateType = MainWindow.State
    typealias ActionType = UuidAction<HtmlPreviewTool.Action>

    fileprivate init(
      server: HttpServer,
      baseUrl: URL,
      cssUrl: URL,
      htmlTemplates _: HtmlTemplates
    ) {
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

    private let log = OSLog(
      subsystem: Defs.loggerSubsystem,
      category: Defs.LoggerCategory.middleware
    )

    private func fullUrl(with path: String) -> URL { self.baseUrl.appendingPathComponent(path) }
  }

  class MarkdownPreviewMiddleware: MiddlewareType {
    typealias StateType = MainWindow.State
    typealias ActionType = UuidAction<MainWindow.Action>

    fileprivate init(server: HttpServer, baseUrl: URL, cssUrl: URL, baseCssUrl: URL) {
      self.server = server
      self.baseUrl = baseUrl
      self.cssUrl = cssUrl
      self.baseCssUrl = baseCssUrl
    }

    func typedApply(_ reduce: @escaping TypedActionReduceFunction) -> TypedActionReduceFunction {
      { tuple in
        let result = reduce(tuple)

        let uuidAction = tuple.action
        switch uuidAction.payload {
        case .newCurrentBuffer: fallthrough
        case .bufferWritten: fallthrough
        case .setTheme:
          break
        default:
          return result
        }

        let preview = result.state.preview
        guard let htmlUrl = preview.html,
              let serverUrl = preview.server else { return result }

        self.log.debug("Serving \(htmlUrl) on \(serverUrl)")
        let htmlBasePath = serverUrl.deletingLastPathComponent().path

        if let bufferUrl = preview.buffer {
          self.server["\(htmlBasePath)/:path"] = shareFilesFromDirectory(
            bufferUrl.deletingLastPathComponent().path
          )
        }

        self.server.GET[serverUrl.path] = shareFile(htmlUrl.path)
        self.server.GET["\(htmlBasePath)/github-markdown.css"] = shareFile(self.cssUrl.path)
        self.server.GET["\(htmlBasePath)/base.css"] = shareFile(self.baseCssUrl.path)

        self.log.info("Serving on \(self.fullUrl(with: serverUrl.path)) for markdown preview")

        return result
      }
    }

    private let server: HttpServer
    private let baseUrl: URL
    private let cssUrl: URL
    private let baseCssUrl: URL

    private let log = OSLog(
      subsystem: Defs.loggerSubsystem,
      category: Defs.LoggerCategory.middleware
    )

    private func fullUrl(with path: String) -> URL { self.baseUrl.appendingPathComponent(path) }
  }
}

private typealias HtmlTemplates = (
  selectFirst: String,
  cssOverrides: String
)
