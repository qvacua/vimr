/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import RxSwift

class PreviewToolReducer: Reducer {

  typealias Pair = StateActionPair<UuidState<MainWindow.State>, PreviewTool.Action>

  init(baseServerUrl: URL) {
    self.baseServerUrl = baseServerUrl
  }

  func reduce(_ source: Observable<Pair>) -> Observable<Pair> {
    return source.map { pair in
      var state = pair.state.payload

      switch pair.action {

      case .refreshNow:
        state.preview = PreviewUtils.state(for: pair.state.uuid,
                                           baseUrl: self.baseServerUrl,
                                           buffer: state.currentBuffer)

      case let .reverseSearch(to:position):
        state.preview.previewPosition = position
        state.preview.ignoreNextReverse = false
        state.preview.ignoreNextForward = true
        state.preview.forceNextReverse = true

      case let .scroll(to:position):
        state.preview.previewPosition = position
        state.preview.ignoreNextReverse = false
        state.preview.ignoreNextForward = true
        state.preview.forceNextReverse = false

      case let .setAutomaticReverseSearch(to:value):
        state.previewTool.isReverseSearchAutomatically = value

      case let .setAutomaticForwardSearch(to:value):
        state.previewTool.isForwardSearchAutomatically = value

      case let .setRefreshOnWrite(to:value):
        state.previewTool.isRefreshOnWrite = value

      }

      return StateActionPair(state: UuidState(uuid: state.uuid, state: state), action: pair.action)
    }
  }

  fileprivate let baseServerUrl: URL
}
