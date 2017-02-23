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
        var mainWindow = state.mainWindowTemplate
        mainWindow.root = state.root
        mainWindow.uuid = UUID().uuidString
        let markedUrls = Marked(urls.toDict { url in MainWindow.OpenMode.default })
        mainWindow.urlsToOpen.append(markedUrls)
        mainWindow.cwd = cwd
        mainWindow.preview.server = self.baseServerUrl.appendingPathComponent(PreviewTransformer.nonePath)

        state.mainWindows[mainWindow.uuid] = mainWindow

      case let .openInKeyWindow(urls, cwd):
        // FIXME
        return pair

      case .quitWithoutSaving, .quit:
        state.mainWindows.removeAll()
        state.quitWhenNoMainWindow = true

      }

      return StateActionPair(state: state, action: pair.action)
    }
  }

  fileprivate let baseServerUrl: URL
}
