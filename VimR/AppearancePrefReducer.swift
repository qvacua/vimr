/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

class AppearancePrefReducer {

  typealias Pair = StateActionPair<AppState, AppearancePref.Action>

  func reduce(_ pair: Pair) -> Pair {
    var state = pair.state
    var appearance = state.mainWindowTemplate.appearance

    switch pair.action {

    case let .setUsesLigatures(value):
      appearance.usesLigatures = value

    case let .setFont(font):
      appearance.font = font

    case let .setLinespacing(linespacing):
      appearance.linespacing = linespacing

    }

    self.modify(state: &state, with: appearance)

    return StateActionPair(state: state, action: pair.action)
  }

  fileprivate func modify(state: inout AppState, with appearance: AppearanceState) {
    state.mainWindowTemplate.appearance = appearance
    state.mainWindows.keys.forEach { state.mainWindows[$0]?.appearance = appearance }
  }
}
