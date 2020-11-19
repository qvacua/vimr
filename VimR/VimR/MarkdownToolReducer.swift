/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

class MarkdownToolReducer: ReducerType {
  typealias StateType = MainWindow.State
  typealias ActionType = UuidAction<MarkdownTool.Action>

  init(baseServerUrl: URL) {
    self.baseServerUrl = baseServerUrl
  }

  func typedReduce(_ tuple: ReduceTuple) -> ReduceTuple {
    var state = tuple.state

    switch tuple.action.payload {
    case let .setAutomaticReverseSearch(to: value):
      state.previewTool.isReverseSearchAutomatically = value

    case let .setAutomaticForwardSearch(to: value):
      state.previewTool.isForwardSearchAutomatically = value

    case let .setRefreshOnWrite(to: value):
      state.previewTool.isRefreshOnWrite = value

    default:
      return tuple
    }

    return (state, tuple.action, true)
  }

  private let baseServerUrl: URL
}
