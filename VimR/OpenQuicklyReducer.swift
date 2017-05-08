/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import RxSwift

class OpenQuicklyReducer {

  typealias OpenQuicklyWindowPair = StateActionPair<AppState, OpenQuicklyWindow.Action>
  typealias MainWindowPair = StateActionPair<AppState, UuidAction<MainWindow.Action>>

  func reduceOpenQuicklyWindow(_ pair: OpenQuicklyWindowPair) -> OpenQuicklyWindowPair {
    var appState = pair.state

    appState.openQuickly.open = false
    appState.openQuickly.flatFileItems = Observable.empty()
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

    return StateActionPair(state: appState, action: pair.action)
  }

  func reduceMainWindow(_ pair: MainWindowPair) -> MainWindowPair {
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
      appState.openQuickly.flatFileItems = FileItemUtils.flatFileItems(
        of: cwd,
        ignorePatterns: appState.openQuickly.ignorePatterns,
        ignoreToken: appState.openQuickly.ignoreToken,
        root: appState.root
      )

      return StateActionPair(state: appState, action: pair.action)

    default:
      return pair

    }
  }
}
