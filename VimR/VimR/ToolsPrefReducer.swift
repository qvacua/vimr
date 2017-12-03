/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

class ToolsPrefReducer {

  typealias Pair = StateActionPair<AppState, ToolsPref.Action>

  func reduce(_ pair: Pair) -> Pair {
    var state = pair.state

    switch pair.action {

    case let .setActiveTools(tools):
      state.mainWindowTemplate.activeTools = tools

    }

    return StateActionPair(state: state, action: pair.action)
  }
}
