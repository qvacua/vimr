/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

final class AdvancedPrefReducer: ReducerType {
  typealias StateType = AppState
  typealias ActionType = AdvancedPref.Action

  func typedReduce(_ tuple: ReduceTuple<StateType, ActionType>)
    -> ReduceTuple<StateType, ActionType>
  {
    var state = tuple.state

    switch tuple.action {
    case let .setUseInteractiveZsh(value):
      state.mainWindowTemplate.useInteractiveZsh = value

    case let .setUseSnapshotUpdate(value):
      state.useSnapshotUpdate = value

    case let .setNvimBinary(value):
      state.mainWindowTemplate.nvimBinary = value

    case let .setNvimAppName(value):
      state.nvimAppName = value
    }

    return ReduceTuple(state: state, action: tuple.action, modified: true)
  }
}
