/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import RxSwift

class AppDelegateTransformer: Transformer {

  typealias Pair = StateActionPair<AppState, AppDelegate.Action>

  func transform(_ source: Observable<Pair>) -> Observable<Pair> {
    return source.map { pair in
      switch pair.action {

      case let .newMainWindow(urls, cwd):
        var state = pair.state

        var mainWindow = state.currentMainWindow
        mainWindow.uuid = UUID().uuidString
        mainWindow.serverBaseUrl = state.baseServerUrl.appendingPathComponent("\(mainWindow.uuid)")
        mainWindow.urlsToOpen = urls.toDict { url in MainWindow.OpenMode.default }
        mainWindow.cwd = cwd

        state.mainWindows[mainWindow.uuid] = mainWindow

        return StateActionPair(state: state, action: pair.action)

      }
    }
  }
}
