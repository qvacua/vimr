/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

class KeysPrefReducer {

  typealias Pair = StateActionPair<AppState, KeysPref.Action>

  func reduce(_ pair: Pair) -> Pair {
    var state = pair.state

    switch pair.action {

    case let .isLeftOptionMeta(value):
      state.mainWindowTemplate.isLeftOptionMeta = value
      state.mainWindows.keys.forEach { state.mainWindows[$0]?.isLeftOptionMeta = value  }

    case let .isRightOptionMeta(value):
      state.mainWindowTemplate.isRightOptionMeta = value
      state.mainWindows.keys.forEach { state.mainWindows[$0]?.isRightOptionMeta = value  }

    }

    return StateActionPair(state: state, action: pair.action)
  }
}
