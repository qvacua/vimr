/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

class AdvancedPrefReducer: ReducerType {
  typealias StateType = AppState
  typealias ActionType = AdvancedPref.Action

  func typedReduce(_ pair: ReduceTuple) -> ReduceTuple {
    var state = pair.state

    switch pair.action {
    case let .setUseLiveResize(value):
      state.mainWindowTemplate.useLiveResize = value
      state.mainWindows.keys.forEach { state.mainWindows[$0]?.useLiveResize = value }

    case let .setDrawsParallel(value):
      state.mainWindowTemplate.drawsParallel = value
      state.mainWindows.keys.forEach { state.mainWindows[$0]?.drawsParallel = value }

    case let .setUseInteractiveZsh(value):
      state.mainWindowTemplate.useInteractiveZsh = value

    case let .setUseSnapshotUpdate(value):
      state.useSnapshotUpdate = value
    }

    return (state, pair.action, true)
  }
}
