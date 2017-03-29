/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import RxSwift

class PrefWindowReducer: Reducer {

  typealias Pair = StateActionPair<AppState, PrefWindow.Action>

  func transform(_ source: Observable<Pair>) -> Observable<Pair> {
    return source.map { pair in
      var state = pair.state

      switch pair.action {

        case .close:
          state.preferencesOpen = Marked(false)

      }

      return StateActionPair(state: state, action: pair.action)
    }
  }
}
