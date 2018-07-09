/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

class PrefWindowReducer: ReducerType {

  typealias StateType = AppState
  typealias ActionType = PrefWindow.Action

  func typedReduce(_ pair: ReduceTuple) -> ReduceTuple {
    var state = pair.state

    switch pair.action {

    case .close:
      state.preferencesOpen = Marked(false)

    }

    return (state, pair.action, true)
  }
}
