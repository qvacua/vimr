/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import RxSwift

class OpenQuicklyReducer: ReducerType {

  typealias StateType = AppState
  typealias ActionType = OpenQuicklyWindow.Action

  let mainWindow = MainWindowReducer()

  func typedReduce(_ pair: ReduceTuple) -> ReduceTuple {
    var appState = pair.state

    switch pair.action {

    case let .setUsesVcsIgnores(usesVcsIgnores):
      guard let uuid = appState.currentMainWindowUuid else { return pair }
      appState.mainWindows[uuid]?.usesVcsIgnores = usesVcsIgnores

    case let .open(url):
      guard let uuid = appState.currentMainWindowUuid else { return pair }
      appState.mainWindows[uuid]?.urlsToOpen[url] = .newTab
      appState.openQuickly.open = false

    case .close:
      appState.openQuickly.open = false
      break

    }

    return (appState, pair.action, true)
  }

  class MainWindowReducer: ReducerType {

    typealias StateType = AppState
    typealias ActionType = UuidAction<MainWindow.Action>

    func typedReduce(_ pair: ReduceTuple) -> ReduceTuple {
      switch pair.action.payload {

      case .openQuickly:
        var appState = pair.state

        guard let uuid = appState.currentMainWindowUuid,
              appState.mainWindows[uuid]?.cwd != nil else { return pair }

        appState.openQuickly.open = true

        return (appState, pair.action, true)

      default:
        return pair

      }
    }
  }
}
