/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import RxSwift

class UiRootTransformer: Transformer {

  typealias Pair = StateActionPair<AppState, UuidAction<MainWindow.Action>>

  func transform(_ source: Observable<Pair>) -> Observable<Pair> {
    return source.map { pair in
      var appState = pair.state
      let uuid = pair.action.uuid

      switch pair.action.payload {

      case .becomeKey:
        appState.currentMainWindowUuid = uuid
        appState.mainWindowTemplate = appState.mainWindows[uuid] ?? appState.mainWindowTemplate

      case .closed:
        if appState.currentMainWindowUuid == uuid {
          appState.currentMainWindowUuid = nil
        }

        appState.mainWindows.removeValue(forKey: uuid)

      default:
        return pair

      }

      return StateActionPair(state: appState, action: pair.action)
    }
  }
}
