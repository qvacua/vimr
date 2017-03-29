/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import CocoaMarkdown

class PreviewService {

  let forMainWindow = MainWindowPreviewService()
  let forOpenedFileList = OpenedFileListPreviewService()

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

    self.forMainWindow.parentService = self
    self.forOpenedFileList.parentService = self
  }

  fileprivate func filledTemplate(body: String, title: String) -> String {
    return self.template
      .replacingOccurrences(of: "{{ title }}", with: title)
      .replacingOccurrences(of: "{{ body }}", with: body)
  }

  fileprivate func render(_ bufferUrl: URL, to htmlUrl: URL) throws {
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

  fileprivate func apply(_ state: UuidState<MainWindow.State>) {
    let uuid = state.uuid

    let preview = state.payload.preview
    guard let buffer = preview.buffer, let html = preview.html else {
      guard let previewUrl = self.previewFiles[uuid] else {
        return
      }

      try? FileManager.default.removeItem(at: previewUrl)
      self.previewFiles.removeValue(forKey: uuid)

      return
    }

    NSLog("\(buffer) -> \(html)")
    do {
      try self.render(buffer, to: html)
      self.previewFiles[uuid] = html
    } catch let error as NSError {
      // FIXME: error handling!
      NSLog("ERROR rendering \(buffer) to \(html): \(error)")
      return
    }
  }

  fileprivate let template: String
  fileprivate let tempDir = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
  fileprivate var previewFiles = [String: URL]()
}

extension PreviewService {

  class OpenedFileListPreviewService: Service {

    typealias Pair = StateActionPair<UuidState<MainWindow.State>, OpenedFileList.Action>

    func apply(_ pair: Pair) {

      guard case .open = pair.action else {
        return
      }

      self.parentService?.apply(pair.state)
    }

    fileprivate var parentService: PreviewService?
  }

  class MainWindowPreviewService: Service {

    typealias Pair = StateActionPair<UuidState<MainWindow.State>, MainWindow.Action>

    func apply(_ pair: Pair) {

      guard case .setCurrentBuffer = pair.action else {
        return
      }

      self.parentService?.apply(pair.state)
    }

    fileprivate var parentService: PreviewService?
  }
}
