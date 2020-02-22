/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import CocoaMarkdown
import os

class PreviewMiddleware {

  let previewTool: PreviewToolMiddleware
  let mainWindow: MainWindowMiddleware

  init() {
    let generator = PreviewGenerator()
    self.previewTool = PreviewToolMiddleware(generator: generator)
    self.mainWindow = MainWindowMiddleware(generator: generator)
  }

  class PreviewGenerator {

    init() {
      guard let templateUrl = Bundle.main.url(
        forResource: "template",
        withExtension: "html",
        subdirectory: "markdown"
      ), let cssOverridesTemplateUrl = Bundle.main.url(
        forResource: "color-overrides",
        withExtension: "css",
        subdirectory: "markdown"
      ) else { preconditionFailure("ERROR Cannot load markdown template") }

      // We know that the file is there!
      self.cssOverridesTemplate = try! String(contentsOf: cssOverridesTemplateUrl)

      guard let template = try? String(contentsOf: templateUrl) else {
        preconditionFailure("ERROR Cannot load markdown template")
      }

      self.template = template
    }

    func apply(_ state: MainWindow.State, uuid: UUID) {
      let preview = state.preview

      if state.appearance.theme.mark != self.themeToken {
        self.updateCssOverrides(with: state.appearance.theme.payload)
        self.themeToken = state.appearance.theme.mark
      }

      guard let buffer = preview.buffer, let html = preview.html else {
        guard let previewUrl = self.previewFiles[uuid] else { return }

        try? FileManager.default.removeItem(at: previewUrl)
        self.previewFiles.removeValue(forKey: uuid)

        return
      }

      do {
        try self.render(buffer, to: html)
        self.previewFiles[uuid] = html
      } catch let error as NSError {
        // FIXME: error handling!
        self.log.error("error whilte rendering \(buffer) to \(html): \(error)")
        return
      }
    }

    private func htmlColor(_ color: NSColor) -> String { "#\(color.hex)" }

    private func updateCssOverrides(with theme: Theme) {
      self.cssOverrides = self.cssOverridesTemplate
        .replacingOccurrences(of: "{{ nvim-color }}", with: self.htmlColor(theme.cssColor))
        .replacingOccurrences(of: "{{ nvim-background-color }}",
                              with: self.htmlColor(theme.cssBackgroundColor))
        .replacingOccurrences(of: "{{ nvim-a }}", with: self.htmlColor(theme.cssA))
        .replacingOccurrences(of: "{{ nvim-hr-background-color }}",
                              with: self.htmlColor(theme.cssHrBorderBackgroundColor))
        .replacingOccurrences(of: "{{ nvim-hr-border-bottom-color }}",
                              with: self.htmlColor(theme.cssHrBorderBottomColor))
        .replacingOccurrences(of: "{{ nvim-blockquote-border-left-color }}",
                              with: self.htmlColor(theme.cssBlockquoteBorderLeftColor))
        .replacingOccurrences(of: "{{ nvim-blockquote-color }}",
                              with: self.htmlColor(theme.cssBlockquoteColor))
        .replacingOccurrences(of: "{{ nvim-h2-border-bottom-color }}",
                              with: self.htmlColor(theme.cssH2BorderBottomColor))
        .replacingOccurrences(of: "{{ nvim-h6-color }}", with: self.htmlColor(theme.cssH6Color))
        .replacingOccurrences(of: "{{ nvim-code-background-color }}",
                              with: self.htmlColor(theme.cssCodeBackgroundColor))
        .replacingOccurrences(of: "{{ nvim-code-color }}", with: self.htmlColor(theme.cssCodeColor))
    }

    private var themeToken = Token()
    private var cssOverrides = ""
    private let cssOverridesTemplate: String

    private let template: String
    private var previewFiles = [UUID: URL]()

    private let log = OSLog(subsystem: Defs.loggerSubsystem,
                            category: Defs.LoggerCategory.middleware)

    private func render(_ bufferUrl: URL, to htmlUrl: URL) throws {
      let doc = CMDocument(contentsOfFile: bufferUrl.path, options: .sourcepos)
      let renderer = CMHTMLRenderer(document: doc)

      guard let body = renderer?.render() else {
        // FIXME: error handling!
        return
      }

      let html = filledTemplate(body: body, title: bufferUrl.lastPathComponent)
      let htmlFilePath = htmlUrl.path

      try html.write(toFile: htmlFilePath, atomically: true, encoding: .utf8)
    }

    private func filledTemplate(body: String, title: String) -> String {
      self.template
        .replacingOccurrences(of: "{{ title }}", with: title)
        .replacingOccurrences(of: "{{ body }}", with: body)
        .replacingOccurrences(of: "{{ css-overrides }}", with: self.cssOverrides)
    }
  }

  class PreviewToolMiddleware: MiddlewareType {

    typealias StateType = MainWindow.State
    typealias ActionType = UuidAction<PreviewTool.Action>

    init(generator: PreviewGenerator) { self.generator = generator }

    func typedApply(_ reduce: @escaping TypedActionReduceFunction) -> TypedActionReduceFunction {
      { tuple in
        let result = reduce(tuple)

        let uuidAction = tuple.action
        guard case .refreshNow = uuidAction.payload else { return result }

        self.generator.apply(result.state, uuid: uuidAction.uuid)
        return result
      }
    }

    private let generator: PreviewGenerator
  }

  class MainWindowMiddleware: MiddlewareType {

    typealias StateType = MainWindow.State
    typealias ActionType = UuidAction<MainWindow.Action>

    init(generator: PreviewGenerator) { self.generator = generator }

    func typedApply(_ reduce: @escaping TypedActionReduceFunction) -> TypedActionReduceFunction {
      { tuple in
        let result = reduce(tuple)

        let uuidAction = tuple.action
        switch uuidAction.payload {

        case .newCurrentBuffer:
          self.generator.apply(result.state, uuid: uuidAction.uuid)

        case .bufferWritten:
          self.generator.apply(result.state, uuid: uuidAction.uuid)

        case .setTheme:
          self.generator.apply(result.state, uuid: uuidAction.uuid)

        default:
          return result

        }

        return result
      }
    }

    private let generator: PreviewGenerator
  }
}
