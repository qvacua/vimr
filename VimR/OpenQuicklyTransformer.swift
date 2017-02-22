/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import RxSwift

class MainWindowToOpenQuicklyTransformer: Transformer {

  typealias Pair = StateActionPair<AppState, UuidAction<MainWindow.Action>>

  func transform(_ source: Observable<Pair>) -> Observable<Pair> {
    return source.map { pair in

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
        NSLog("!!!!!!!!!!!!!!!!!!!!!!!! \(cwd)")
        appState.openQuickly.flatFileItems = FileItemUtils.flatFileItems(
          ofUrl: cwd,
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
}

class OpenQuicklyTransformer: Transformer {

  typealias Pair = StateActionPair<AppState, OpenQuicklyWindow.Action>

  func transform(_ source: Observable<Pair>) -> Observable<Pair> {
    return source.map { pair in
      var appState = pair.state

      appState.openQuickly.open = false
      appState.openQuickly.flatFileItems = Observable.empty()
      appState.openQuickly.cwd = FileUtils.userHomeUrl

      switch pair.action {

        case let .open(url):
          guard let uuid = appState.currentMainWindowUuid else {
            return pair
          }

          NSLog("\(url) -> \(uuid)")

          appState.mainWindows[uuid]?.urlsToOpen.append(Marked([url: .newTab]))

        case .close:
          break

      }

      return StateActionPair(state: appState, action: pair.action)
    }
  }
}
