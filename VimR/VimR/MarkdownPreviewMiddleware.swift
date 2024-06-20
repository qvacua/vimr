/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Down
import Foundation
import os

final class MarkdownPreviewMiddleware {
  let markdownTool: MarkdownToolMiddleware
  let mainWindow: MainWindowMiddleware

  init() {
    let generator = PreviewGenerator()
    self.markdownTool = MarkdownToolMiddleware(generator: generator)
    self.mainWindow = MainWindowMiddleware(generator: generator)
  }

  class PreviewGenerator {
    init() {
      // We know that the files are there!
      self.template = try! String(contentsOf: Resources.markdownTemplateUrl)
      self.emptyHtmlTemplate = try! String(contentsOf: Resources.emptyHtmlTemplateUrl)
      self.errorHtmlTemplate = try! String(contentsOf: Resources.errorHtmlTemplateUrl)
      self.saveFirstHtmlTemplate = try! String(contentsOf: Resources.saveFirstHtmlTemplateUrl)

      self.updateCssOverrides(with: Theme.default)
    }

    func apply(_ state: MainWindow.State, uuid: UUID) {
      let preview = state.preview

      if state.appearance.theme.mark != self.themeToken {
        self.updateCssOverrides(with: state.appearance.theme.payload)
        self.themeToken = state.appearance.theme.mark
      }

      self.removePreviewHtmlFile(uuid: uuid)
      guard let htmlUrl = preview.html else { return }

      switch preview.status {
      case .none:
        self.writePage(html: self.emptyHtml, uuid: uuid, url: htmlUrl)

      case .notSaved:
        self.writePage(html: self.saveFirstHtml, uuid: uuid, url: htmlUrl)

      case .error:
        self.writePage(html: self.errorHtml, uuid: uuid, url: htmlUrl)

      case .markdown:
        guard let buffer = preview.buffer else { return }

        do {
          try self.render(
            buffer,
            to: htmlUrl,
            customMarkdownProcessor: state.customMarkdownProcessor
          )
          self.previewFiles[uuid] = htmlUrl
        } catch let error as NSError {
          // FIXME: error handling!
          self.log.error("error while rendering \(buffer) to \(htmlUrl): \(error)")
          return
        }
      }
    }

    private func writePage(html: String, uuid: UUID, url: URL) {
      try? html.write(to: url, atomically: true, encoding: .utf8)
      self.previewFiles[uuid] = url
    }

    private func removePreviewHtmlFile(uuid: UUID) {
      guard let previewUrl = self.previewFiles[uuid] else { return }

      try? FileManager.default.removeItem(at: previewUrl)
      self.previewFiles.removeValue(forKey: uuid)
    }

    private func updateCssOverrides(with theme: Theme) {
      self.cssOverrides = CssUtils.cssOverrides(with: theme)

      self.emptyHtml = self.fillCssOverrides(template: self.emptyHtmlTemplate)
      self.errorHtml = self.fillCssOverrides(template: self.errorHtmlTemplate)
      self.saveFirstHtml = self.fillCssOverrides(template: self.saveFirstHtmlTemplate)
    }

    private var themeToken = Token()

    private var cssOverrides = ""
    private var emptyHtml = ""
    private var errorHtml = ""
    private var saveFirstHtml = ""

    private let emptyHtmlTemplate: String
    private let errorHtmlTemplate: String
    private let saveFirstHtmlTemplate: String

    private let template: String
    private var previewFiles = [UUID: URL]()

    private let log = OSLog(
      subsystem: Defs.loggerSubsystem,
      category: Defs.LoggerCategory.middleware
    )

    private func render(
      _ bufferUrl: URL,
      to htmlUrl: URL,
      customMarkdownProcessor cmp: String?
    ) throws {
      let body: String
      if let cmp, cmp != "" {
        let content = try Data(contentsOf: bufferUrl)

        let sh = Process()

        let output = Pipe()
        let input = Pipe()
        let err = Pipe()

        sh.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        sh.arguments = ["bash", "-l", "-c", cmp]
        sh.standardInput = input
        sh.standardOutput = output
        sh.standardError = err

        input.fileHandleForWriting.write(content)
        input.fileHandleForWriting.closeFile()

        try sh.run()

        body = String(decoding: output.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
      } else {
        let md = try String(contentsOf: bufferUrl)
        let down = Down(markdownString: md)
        body = try down.toHTML(DownOptions.sourcePos)
      }

      let html = self.filledTemplate(body: body, title: bufferUrl.lastPathComponent)
      let htmlFilePath = htmlUrl.path

      try html.write(toFile: htmlFilePath, atomically: true, encoding: .utf8)
    }

    private func fillCssOverrides(template: String) -> String {
      template.replacingOccurrences(of: "{{ css-overrides }}", with: self.cssOverrides)
    }

    private func filledTemplate(body: String, title: String) -> String {
      self.template
        .replacingOccurrences(of: "{{ title }}", with: title)
        .replacingOccurrences(of: "{{ body }}", with: body)
        .replacingOccurrences(of: "{{ css-overrides }}", with: self.cssOverrides)
    }
  }

  class MarkdownToolMiddleware: MiddlewareType {
    typealias StateType = MainWindow.State
    typealias ActionType = UuidAction<MarkdownTool.Action>

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
        case .newCurrentBuffer: fallthrough
        case .bufferWritten: fallthrough
        case .setTheme:
          self.generator.apply(result.state, uuid: uuidAction.uuid)
        default: return result
        }

        return result
      }
    }

    private let generator: PreviewGenerator
  }
}
