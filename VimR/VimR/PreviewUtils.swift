/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

private let markdownPath = "tools/preview/markdown"

class PreviewUtils {

  static func state(for status: PreviewState.Status,
                    baseUrl: URL,
                    editorPosition: Marked<Position>,
                    previewPosition: Marked<Position>) -> PreviewState {

    switch status {

    case .none:
      return PreviewState(status: .none,
                          server: self.simpleServerUrl(with: MarkdownReducer.nonePath, baseUrl: baseUrl),
                          editorPosition: editorPosition,
                          previewPosition: previewPosition)

    case .error:
      return PreviewState(status: .error,
                          server: self.simpleServerUrl(with: MarkdownReducer.errorPath, baseUrl: baseUrl),
                          editorPosition: editorPosition,
                          previewPosition: previewPosition)

    case .notSaved:
      return PreviewState(status: .notSaved,
                          server: self.simpleServerUrl(with: MarkdownReducer.saveFirstPath, baseUrl: baseUrl),
                          editorPosition: editorPosition,
                          previewPosition: previewPosition)

    case .markdown:
      preconditionFailure("ERROR Use the other previewState()!")

    }
  }

  static func state(for uuid: UUID,
                    baseUrl: URL,
                    buffer: NvimView.Buffer?,
                    editorPosition: Marked<Position>,
                    previewPosition: Marked<Position>) -> PreviewState {

    guard let url = buffer?.url else {
      return self.state(
        for: .notSaved, baseUrl: baseUrl, editorPosition: editorPosition, previewPosition: previewPosition
      )
    }

    guard FileUtils.fileExists(at: url) else {
      return self.state(
        for: .error, baseUrl: baseUrl, editorPosition: editorPosition, previewPosition: previewPosition
      )
    }

    guard self.extensions.contains(url.pathExtension) else {
      return self.state(
        for: .none, baseUrl: baseUrl, editorPosition: editorPosition, previewPosition: previewPosition
      )
    }

    return PreviewState(status: .markdown,
                        buffer: url,
                        html: self.htmlUrl(with: uuid),
                        server: self.serverUrl(for: uuid, baseUrl: baseUrl, lastComponent: "index.html"),
                        editorPosition: editorPosition,
                        previewPosition: previewPosition)
  }

  private static func serverUrl(for uuid: UUID, baseUrl: URL, lastComponent: String) -> URL {
    return baseUrl.appendingPathComponent("\(uuid)/\(markdownPath)/\(lastComponent)")
  }

  private static func htmlUrl(with uuid: UUID) -> URL {
    return self.tempDir.appendingPathComponent("\(uuid)-markdown-index.html")
  }

  private static func simpleServerUrl(with path: String, baseUrl: URL) -> URL {
    return baseUrl.appendingPathComponent(path)
  }

  private static let extensions = Set(["md", "markdown"])
  private static let tempDir = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
}
