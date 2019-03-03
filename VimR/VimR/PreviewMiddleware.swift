/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import CocoaMarkdown

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
      guard let templateUrl = Bundle.main.url(forResource: "template",
                                              withExtension: "html",
                                              subdirectory: "markdown")
        else {
        preconditionFailure("ERROR Cannot load markdown template")
      }

      guard let template = try? String(contentsOf: templateUrl) else {
        preconditionFailure("ERROR Cannot load markdown template")
      }

      self.template = template
    }

    func apply(_ state: MainWindow.State, uuid: UUID) {
      let preview = state.preview
      guard let buffer = preview.buffer, let html = preview.html else {
        guard let previewUrl = self.previewFiles[uuid] else {
          return
        }

        try? FileManager.default.removeItem(at: previewUrl)
        self.previewFiles.removeValue(forKey: uuid)

        return
      }

      stdoutLog.debug("\(buffer) -> \(html)")
      do {
        try self.render(buffer, to: html)
        self.previewFiles[uuid] = html
      } catch let error as NSError {
        // FIXME: error handling!
        NSLog("ERROR rendering \(buffer) to \(html): \(error)")
        return
      }
    }

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
      return self.template
        .replacingOccurrences(of: "{{ title }}", with: title)
        .replacingOccurrences(of: "{{ body }}", with: body)
    }

    private let template: String
    private var previewFiles = [UUID: URL]()
  }

  class PreviewToolMiddleware: MiddlewareType {

    typealias StateType = MainWindow.State
    typealias ActionType = UuidAction<PreviewTool.Action>

    init(generator: PreviewGenerator) {
      self.generator = generator
    }

    func typedApply(_ reduce: @escaping TypedActionReduceFunction) -> TypedActionReduceFunction {
      return { tuple in
        let result = reduce(tuple)

        let uuidAction = tuple.action
        guard case .refreshNow = uuidAction.payload else {
          return result
        }

        self.generator.apply(result.state, uuid: uuidAction.uuid)
        return result
      }
    }

    private let generator: PreviewGenerator
  }

  class MainWindowMiddleware: MiddlewareType {

    typealias StateType = MainWindow.State
    typealias ActionType = UuidAction<MainWindow.Action>

    init(generator: PreviewGenerator) {
      self.generator = generator
    }

    func typedApply(_ reduce: @escaping TypedActionReduceFunction) -> TypedActionReduceFunction {
      return { tuple in
        let result = reduce(tuple)

        let uuidAction = tuple.action
        switch uuidAction.payload {

        case .newCurrentBuffer:
          self.generator.apply(result.state, uuid: uuidAction.uuid)

        case .bufferWritten:
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
