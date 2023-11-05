/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

final class GeneralPrefReducer: ReducerType {
  typealias StateType = AppState
  typealias ActionType = GeneralPref.Action

  func typedReduce(_ pair: ReduceTuple) -> ReduceTuple {
    var state = pair.state

    switch pair.action {
    case let .setOpenOnLaunch(value):
      state.openNewMainWindowOnLaunch = value

    case let .setOpenFilesFromApplications(action):
      state.openFilesFromApplicationsAction = action

    case let .setAfterLastWindowAction(action):
      state.afterLastWindowAction = action

    case let .setActivateAsciiImInNormalModeAction(value):
      state.activateAsciiImInNormalMode = value

    case let .setOpenOnReactivation(value):
      state.openNewMainWindowOnReactivation = value

    case let .setDefaultUsesVcsIgnores(value):
      state.openQuickly.defaultUsesVcsIgnores = value

    case let .setCustomMarkdownProcessor(command):
      state.mainWindowTemplate.customMarkdownProcessor = command
      state.mainWindows.keys.forEach { state.mainWindows[$0]?.customMarkdownProcessor = command }
    }

    return (state, pair.action, true)
  }
}
