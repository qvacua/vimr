/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

class PreviewToolReducer {

  typealias Pair = StateActionPair<UuidState<MainWindow.State>, PreviewTool.Action>

  init(baseServerUrl: URL) {
    self.baseServerUrl = baseServerUrl
  }

  func reduce(_ pair: Pair) -> Pair {
    var state = pair.state.payload

    switch pair.action {

    case let .setAutomaticReverseSearch(to:value):
      state.previewTool.isReverseSearchAutomatically = value

    case let .setAutomaticForwardSearch(to:value):
      state.previewTool.isForwardSearchAutomatically = value

    case let .setRefreshOnWrite(to:value):
      state.previewTool.isRefreshOnWrite = value

    default:
      return pair

    }

    return StateActionPair(state: UuidState(uuid: state.uuid, state: state), action: pair.action)
  }

  private let baseServerUrl: URL
}
