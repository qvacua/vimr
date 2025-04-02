/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

final class ToolsPrefReducer: ReducerType {
  typealias StateType = AppState
  typealias ActionType = ToolsPref.Action

  func typedReduce(_ tuple: ReduceTuple<StateType, ActionType>)
    -> ReduceTuple<StateType, ActionType>
  {
    var state = tuple.state

    switch tuple.action {
    case let .setActiveTools(tools):
      state.mainWindowTemplate.activeTools = tools
    }

    return ReduceTuple(state: state, action: tuple.action, modified: true)
  }
}
