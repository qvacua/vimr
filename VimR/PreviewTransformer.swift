/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import CocoaMarkdown
import RxSwift
import CocoaMarkdown

fileprivate let markdownPath = "tools/preview/markdown"

// Currently supports only markdown
class PreviewTransformer: Transformer {

  typealias Pair = StateActionPair<UuidState<MainWindow.State>, MainWindow.Action>

  static let basePath = "/tools/preview"
  static let saveFirstPath = "/tools/preview/save-first.html"
  static let errorPath = "/tools/preview/error.html"
  static let nonePath = "/tools/preview/empty.html"

  init(baseServerUrl: URL) {
    self.baseServerUrl = baseServerUrl
  }

  func transform(_ source: Observable<Pair>) -> Observable<Pair> {
    return source.map { pair in
      let uuid = pair.state.uuid
      var state = pair.state.payload

      switch pair.action {

      case let .setCurrentBuffer(buffer):
        guard state.previewTool.isRefreshOnWrite else {
          return pair
        }

        guard let url = buffer.url else {
          state.preview = PreviewState(status: .notSaved,
                                       server: self.simpleServerUrl(with: PreviewTransformer.saveFirstPath),
                                       updateDate: Date())
          break
        }

        guard FileUtils.fileExists(at: url) else {
          state.preview = PreviewState(status: .error,
                                       server: self.simpleServerUrl(with: PreviewTransformer.errorPath),
                                       updateDate: Date())
          break
        }

        guard self.extensions.contains(url.pathExtension) else {
          state.preview = PreviewState(status: .none,
                                       server: self.simpleServerUrl(with: PreviewTransformer.nonePath),
                                       updateDate: Date())
          break
        }

        state.preview = PreviewState(status: .markdown,
                                     buffer: url,
                                     html: self.htmlUrl(with: uuid),
                                     server: self.serverUrl(for: uuid, lastComponent: "index.html"),
                                     updateDate: Date())

      case .close:
        state.preview = PreviewState(status: .none,
                                     server: self.simpleServerUrl(with: PreviewTransformer.nonePath),
                                     updateDate: Date())

      default:
        return pair
      }

      return StateActionPair(state: UuidState(uuid: pair.state.uuid, state: state), action: pair.action)
    }
  }

  fileprivate func serverUrl(for uuid: String, lastComponent: String) -> URL {
    return self.baseServerUrl.appendingPathComponent("\(uuid)/\(markdownPath)/\(lastComponent)")
  }

  fileprivate func htmlUrl(with uuid: String) -> URL {
    return self.tempDir.appendingPathComponent("\(uuid)-markdown-index.html")
  }

  fileprivate func simpleServerUrl(with path: String) -> URL {
    return self.baseServerUrl.appendingPathComponent(path)
  }

  fileprivate let extensions = Set(["md", "markdown"])
  fileprivate let tempDir = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
  fileprivate let baseServerUrl: URL
}
