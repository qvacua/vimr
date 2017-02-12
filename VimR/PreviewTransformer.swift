/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import RxSwift

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
      var state = pair.state.payload

      switch pair.action {

      case let .setCurrentBuffer(buffer):
        guard state.previewTool.isRefreshOnWrite else {
          return pair
        }

        state.preview = PreviewUtils.state(for: pair.state.uuid, baseUrl: self.baseServerUrl, buffer: buffer)

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
