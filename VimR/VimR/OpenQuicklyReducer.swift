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

    appState.openQuickly.open = false
    appState.openQuickly.cwd = FileUtils.userHomeUrl

    switch pair.action {

    case let .open(url):
      guard let uuid = appState.currentMainWindowUuid else {
        return pair
      }

      appState.mainWindows[uuid]?.urlsToOpen[url] = .newTab

    case .close:
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

        guard let uuid = appState.currentMainWindowUuid else {
          return pair
        }

        guard let cwd = appState.mainWindows[uuid]?.cwd else {
          return pair
        }

        appState.openQuickly.open = true
        appState.openQuickly.cwd = cwd

        return (appState, pair.action, true)

      default:
        return pair

      }
    }
  }
}
