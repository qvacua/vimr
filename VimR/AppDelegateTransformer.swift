/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import RxSwift

class AppDelegateTransformer: Transformer {

  typealias Pair = StateActionPair<AppState, AppDelegate.Action>

  init(baseServerUrl: URL) {
    self.baseServerUrl = baseServerUrl
  }

  func transform(_ source: Observable<Pair>) -> Observable<Pair> {
    return source.map { pair in
      var state = pair.state

      switch pair.action {

      case let .newMainWindow(urls, cwd):
        var mainWindow = state.currentMainWindow
        mainWindow.uuid = UUID().uuidString
        mainWindow.urlsToOpen = urls.toDict { url in MainWindow.OpenMode.default }
        mainWindow.cwd = cwd
        mainWindow.preview.server = self.baseServerUrl.appendingPathComponent("/tools/preview/none")

        state.mainWindows[mainWindow.uuid] = mainWindow

        return StateActionPair(state: state, action: pair.action)

      case .closeAllMainWindowsWithoutSaving, .closeAllMainWindows:
        state.mainWindows.removeAll()
        return StateActionPair(state: state, action: pair.action)

      }
    }
  }

  fileprivate let baseServerUrl: URL
}
