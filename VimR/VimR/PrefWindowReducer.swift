/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

class PrefWindowReducer {

  typealias Pair = StateActionPair<AppState, PrefWindow.Action>

  func reduce(_ pair: Pair) -> Pair {
    var state = pair.state

    switch pair.action {

    case .close:
      state.preferencesOpen = Marked(false)

    }

    return StateActionPair(state: state, action: pair.action)
  }
}
