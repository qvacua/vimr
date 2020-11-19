/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

class ToolsPrefReducer: ReducerType {
  typealias StateType = AppState
  typealias ActionType = ToolsPref.Action

  func typedReduce(_ pair: ReduceTuple) -> ReduceTuple {
    var state = pair.state

    switch pair.action {
    case let .setActiveTools(tools):
      state.mainWindowTemplate.activeTools = tools
    }

    return (state, pair.action, true)
  }
}
