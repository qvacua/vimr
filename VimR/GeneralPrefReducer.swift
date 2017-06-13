/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

class GeneralPrefReducer {

  typealias Pair = StateActionPair<AppState, GeneralPref.Action>

  func reduce(_ pair: Pair) -> Pair {
    var state = pair.state

    switch pair.action {

    case let .setOpenOnLaunch(value):
      state.openNewMainWindowOnLaunch = value

    case let .setAfterLastWindowAction(action):
      state.afterLastWindowAction = action

    case let .setOpenOnReactivation(value):
      state.openNewMainWindowOnReactivation = value

    case let .setIgnorePatterns(patterns):
      state.openQuickly.ignorePatterns = patterns
      state.openQuickly.ignoreToken = Token()

    }

    return StateActionPair(state: state, action: pair.action)
  }
}
