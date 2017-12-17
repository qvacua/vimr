/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

fileprivate let markdownPath = "tools/preview/markdown"

class PreviewUtils {

  static func state(for status: PreviewState.Status, baseUrl: URL) -> PreviewState {
    switch status {

    case .none:
      return PreviewState(status: .none,
                          server: self.simpleServerUrl(with: MarkdownReducer.nonePath, baseUrl: baseUrl))

    case .error:
      return PreviewState(status: .error,
                          server: self.simpleServerUrl(with: MarkdownReducer.errorPath, baseUrl: baseUrl))

    case .notSaved:
      return PreviewState(status: .notSaved,
                          server: self.simpleServerUrl(with: MarkdownReducer.saveFirstPath, baseUrl: baseUrl))

    case .markdown:
      preconditionFailure("ERROR Use the other previewState()!")

    }
  }

  static func state(for uuid: String,
                    baseUrl: URL,
                    buffer: NvimView.Buffer?,
                    editorPosition: Marked<Position>,
                    previewPosition: Marked<Position>) -> PreviewState {

    guard let url = buffer?.url else {
      return self.state(for: .notSaved, baseUrl: baseUrl)
    }

    guard FileUtils.fileExists(at: url) else {
      return self.state(for: .error, baseUrl: baseUrl)
    }

    guard self.extensions.contains(url.pathExtension) else {
      return self.state(for: .none, baseUrl: baseUrl)
    }

    return PreviewState(status: .markdown,
                        buffer: url,
                        html: self.htmlUrl(with: uuid),
                        server: self.serverUrl(for: uuid, baseUrl: baseUrl, lastComponent: "index.html"),
                        editorPosition: editorPosition,
                        previewPosition: previewPosition)
  }

  fileprivate static func serverUrl(for uuid: String, baseUrl: URL, lastComponent: String) -> URL {
    return baseUrl.appendingPathComponent("\(uuid)/\(markdownPath)/\(lastComponent)")
  }

  fileprivate static func htmlUrl(with uuid: String) -> URL {
    return self.tempDir.appendingPathComponent("\(uuid)-markdown-index.html")
  }

  fileprivate static func simpleServerUrl(with path: String, baseUrl: URL) -> URL {
    return baseUrl.appendingPathComponent(path)
  }

  fileprivate static let extensions = Set(["md", "markdown"])
  fileprivate static let tempDir = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
}
