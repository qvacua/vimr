/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

final class AppearancePrefReducer: ReducerType {
  typealias StateType = AppState
  typealias ActionType = AppearancePref.Action

  func typedReduce(_ tuple: ReduceTuple<StateType, ActionType>)
    -> ReduceTuple<StateType, ActionType>
  {
    var state = tuple.state
    var appearance = state.mainWindowTemplate.appearance

    switch tuple.action {
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

    case let .setFontSmoothing(fontSmoothing):
      appearance.fontSmoothing = fontSmoothing
    }

    self.modify(state: &state, with: appearance)

    return ReduceTuple(state: state, action: tuple.action, modified: true)
  }

  private func modify(state: inout AppState, with appearance: AppearanceState) {
    state.mainWindowTemplate.appearance = appearance
    state.mainWindows.keys.forEach { state.mainWindows[$0]?.appearance = appearance }
  }
}
