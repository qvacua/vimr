/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

final class AdvancedPrefReducer: ReducerType {
  typealias StateType = AppState
  typealias ActionType = AdvancedPref.Action

  func typedReduce(_ pair: ReduceTuple) -> ReduceTuple {
    var state = pair.state

    switch pair.action {
    case let .setUseInteractiveZsh(value):
      state.mainWindowTemplate.useInteractiveZsh = value

    case let .setUseSnapshotUpdate(value):
      state.useSnapshotUpdate = value

    case let .setNvimBinary(value):
      state.mainWindowTemplate.nvimBinary = value
    }

    return (state, pair.action, true)
  }
}
