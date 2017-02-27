/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import RxSwift

class GeneralPrefTransformer: Transformer {

  typealias Pair = StateActionPair<AppState, GeneralPref.Action>

  func transform(_ source: Observable<Pair>) -> Observable<Pair> {
    return source.map { pair in
      var state = pair.state

      switch pair.action {

      case let .setOpenOnLaunch(value):
        state.openNewMainWindowOnLaunch = value

      case let .setOpenOnReactivation(value):
        state.openNewMainWindowOnReactivation = value

      case let .setIgnorePatterns(patterns):
        state.openQuickly.ignorePatterns = patterns
        state.openQuickly.ignoreToken = Token()

      }

      return StateActionPair(state: state, action: pair.action)
    }
  }
}
