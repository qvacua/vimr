/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import RxSwift

class MarkdownReducer {

  static let basePath = "/tools/markdown"
  static let saveFirstPath = "/tools/markdown/save-first.html"
  static let errorPath = "/tools/markdown/error.html"
  static let nonePath = "/tools/markdown/empty.html"

  let forMainWindow: MainWindowPreviewReducer
  let forOpenedFileList: OpenedFileListReducer

  init(baseServerUrl: URL) {
    self.forMainWindow = MainWindowPreviewReducer(baseServerUrl)
    self.forOpenedFileList = OpenedFileListReducer(baseServerUrl)
  }
}

extension MarkdownReducer {

  class MainWindowPreviewReducer: Reducer {

    typealias Pair = StateActionPair<UuidState<MainWindow.State>, MainWindow.Action>

    init(_ baseServerUrl: URL) {
      self.baseServerUrl = baseServerUrl
    }

    func reduce(_ source: Observable<Pair>) -> Observable<Pair> {
      return source.map { pair in
        var state = pair.state.payload

        switch pair.action {

        case let .setCurrentBuffer(buffer):
          guard state.previewTool.isRefreshOnWrite else {
            return pair
          }

          state.preview = PreviewUtils.state(for: pair.state.uuid, baseUrl: self.baseServerUrl, buffer: buffer)
          state.preview.ignoreNextReverse = true

        case .close:
          state.preview = PreviewUtils.state(for: .none, baseUrl: self.baseServerUrl)

        default:
          return pair
        }

        return StateActionPair(state: UuidState(uuid: pair.state.uuid, state: state), action: pair.action)
      }
    }

    fileprivate let baseServerUrl: URL
  }

  class OpenedFileListReducer: Reducer {

    typealias Pair = StateActionPair<UuidState<MainWindow.State>, OpenedFileList.Action>

    init(_ baseServerUrl: URL) {
      self.baseServerUrl = baseServerUrl
    }

    func reduce(_ source: Observable<Pair>) -> Observable<Pair> {
      return source.map { pair in
        var state = pair.state.payload

        switch pair.action {

        case let .open(buffer):
          state.preview = PreviewUtils.state(for: pair.state.uuid, baseUrl: self.baseServerUrl, buffer: buffer)

        }

        return StateActionPair(state: UuidState(uuid: pair.state.uuid, state: state), action: pair.action)
      }
    }

    fileprivate let baseServerUrl: URL
  }
}
