/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

final class OpenQuicklyReducer: ReducerType {
  typealias StateType = AppState
  typealias ActionType = OpenQuicklyWindow.Action

  let mainWindow = MainWindowReducer()

  func typedReduce(_ tuple: ReduceTuple<StateType, ActionType>)
    -> ReduceTuple<StateType, ActionType>
  {
    var appState = tuple.state

    switch tuple.action {
    case let .setUsesVcsIgnores(usesVcsIgnores):
      guard let uuid = appState.currentMainWindowUuid else { return tuple }
      appState.mainWindows[uuid]?.usesVcsIgnores = usesVcsIgnores

    case let .open(url):
      guard let uuid = appState.currentMainWindowUuid else { return tuple }
      appState.mainWindows[uuid]?.urlsToOpen[url] = .default
      appState.openQuickly.open = false

    case .close:
      appState.openQuickly.open = false
    }

    return ReduceTuple(state: appState, action: tuple.action, modified: true)
  }

  class MainWindowReducer: ReducerType {
    typealias StateType = AppState
    typealias ActionType = UuidAction<MainWindow.Action>

    func typedReduce(_ tuple: ReduceTuple<StateType, ActionType>)
      -> ReduceTuple<StateType, ActionType>
    {
      switch tuple.action.payload {
      case .openQuickly:
        var appState = tuple.state

        guard let uuid = appState.currentMainWindowUuid,
              appState.mainWindows[uuid]?.cwd != nil else { return tuple }

        appState.openQuickly.open = true

        return ReduceTuple(state: appState, action: tuple.action, modified: true)

      default:
        return tuple
      }
    }
  }
}
