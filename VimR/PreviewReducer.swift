/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import RxSwift

// Currently supports only markdown
class PreviewReducer {

  static let basePath = "/tools/preview"
  static let saveFirstPath = "/tools/preview/save-first.html"
  static let errorPath = "/tools/preview/error.html"
  static let nonePath = "/tools/preview/empty.html"

  let forMainWindow = MainWindowPreviewReducer()
  let forOpenedFileList = OpenedFileListReducer()

  init(baseServerUrl: URL) {
    self.baseServerUrl = baseServerUrl

    self.forMainWindow.parentTransformer = self
    self.forOpenedFileList.parentTransformer = self
  }

  fileprivate let baseServerUrl: URL
}

extension PreviewReducer {

  class MainWindowPreviewReducer: Reducer {

    typealias Pair = StateActionPair<UuidState<MainWindow.State>, MainWindow.Action>

    func reduce(_ source: Observable<Pair>) -> Observable<Pair> {
      return source.map { pair in
        guard let baseServerUrl = self.parentTransformer?.baseServerUrl else {
          return pair
        }

        var state = pair.state.payload

        switch pair.action {

        case let .setCurrentBuffer(buffer):
          guard state.previewTool.isRefreshOnWrite else {
            return pair
          }

          state.preview = PreviewUtils.state(for: pair.state.uuid, baseUrl: baseServerUrl, buffer: buffer)

        case .close:
          state.preview = PreviewUtils.state(for: .none, baseUrl: baseServerUrl)

        default:
          return pair
        }

        return StateActionPair(state: UuidState(uuid: pair.state.uuid, state: state), action: pair.action)
      }
    }

    fileprivate var parentTransformer: PreviewReducer?
  }

  class OpenedFileListReducer: Reducer {

    typealias Pair = StateActionPair<UuidState<MainWindow.State>, OpenedFileList.Action>

    func reduce(_ source: Observable<Pair>) -> Observable<Pair> {
      return source.map { pair in
        guard let baseServerUrl = self.parentTransformer?.baseServerUrl else {
          return pair
        }

        var state = pair.state.payload

        switch pair.action {

        case let .open(buffer):
          state.preview = PreviewUtils.state(for: pair.state.uuid, baseUrl: baseServerUrl, buffer: buffer)

        }

        return StateActionPair(state: UuidState(uuid: pair.state.uuid, state: state), action: pair.action)
      }
    }

    fileprivate var parentTransformer: PreviewReducer?
  }
}
