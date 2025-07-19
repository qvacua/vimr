/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

final class KeysPrefReducer: ReducerType {
  typealias StateType = AppState
  typealias ActionType = KeysPref.Action

  func typedReduce(_ tuple: ReduceTuple<StateType, ActionType>)
    -> ReduceTuple<StateType, ActionType>
  {
    var state = tuple.state

    switch tuple.action {
    case let .isLeftOptionMeta(value):
      state.mainWindowTemplate.isLeftOptionMeta = value
      state.mainWindows.keys.forEach { state.mainWindows[$0]?.isLeftOptionMeta = value }

    case let .isRightOptionMeta(value):
      state.mainWindowTemplate.isRightOptionMeta = value
      state.mainWindows.keys.forEach { state.mainWindows[$0]?.isRightOptionMeta = value }
    }

    return ReduceTuple(state: state, action: tuple.action, modified: true)
  }
}
