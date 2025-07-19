/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

final class PrefWindowReducer: ReducerType {
  typealias StateType = AppState
  typealias ActionType = PrefWindow.Action

  func typedReduce(_ tuple: ReduceTuple<StateType, ActionType>)
    -> ReduceTuple<StateType, ActionType>
  {
    var state = tuple.state

    switch tuple.action {
    case .close:
      state.preferencesOpen = Marked(false)
    }

    return ReduceTuple(state: state, action: tuple.action, modified: true)
  }
}
