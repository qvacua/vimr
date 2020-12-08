/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

class AppearancePrefReducer: ReducerType {
  typealias StateType = AppState
  typealias ActionType = AppearancePref.Action

  func typedReduce(_ pair: ReduceTuple) -> ReduceTuple {
    var state = pair.state
    var appearance = state.mainWindowTemplate.appearance

    switch pair.action {
    case let .setUsesCustomTab(value):
      appearance.usesCustomTab = value

    case let .setUsesColorscheme(value):
      appearance.usesTheme = value

    case let .setShowsFileIcon(value):
      appearance.showsFileIcon = value

    case let .setUsesLigatures(value):
      appearance.usesLigatures = value

    case let .setFont(font):
      appearance.font = font

    case let .setLinespacing(linespacing):
      appearance.linespacing = linespacing

    case let .setCharacterspacing(characterspacing):
      appearance.characterspacing = characterspacing
    }

    self.modify(state: &state, with: appearance)

    return (state, pair.action, true)
  }

  private func modify(state: inout AppState, with appearance: AppearanceState) {
    state.mainWindowTemplate.appearance = appearance
    state.mainWindows.keys.forEach { state.mainWindows[$0]?.appearance = appearance }
  }
}
