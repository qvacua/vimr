/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

class KeysPrefReducer: ReducerType {

  typealias StateType = AppState
  typealias ActionType = KeysPref.Action

  func typedReduce(_ pair: ReduceTuple) -> ReduceTuple {
    var state = pair.state

    switch pair.action {

    case let .isLeftOptionMeta(value):
      state.mainWindowTemplate.isLeftOptionMeta = value
      state.mainWindows.keys.forEach { state.mainWindows[$0]?.isLeftOptionMeta = value  }

    case let .isRightOptionMeta(value):
      state.mainWindowTemplate.isRightOptionMeta = value
      state.mainWindows.keys.forEach { state.mainWindows[$0]?.isRightOptionMeta = value  }

    }

    return (state, pair.action, true)
  }
}
