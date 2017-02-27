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
        let mainWindow = self.newMainWindow(with: state, urls: urls, cwd: cwd)
        state.mainWindows[mainWindow.uuid] = mainWindow

      case let .openInKeyWindow(urls, cwd):
        guard let uuid = state.currentMainWindowUuid, state.mainWindows[uuid] != nil else {
          let mainWindow = self.newMainWindow(with: state, urls: urls, cwd: cwd)
          state.mainWindows[mainWindow.uuid] = mainWindow
          break
        }

        state.mainWindows[uuid]?.urlsToOpen.append(Marked(urls.toDict { url in MainWindow.OpenMode.default }))
        state.mainWindows[uuid]?.cwd = cwd

      case .quitWithoutSaving, .quit:
        state.mainWindows.removeAll()
        state.quitWhenNoMainWindow = true

      }

      return StateActionPair(state: state, action: pair.action)
    }
  }

  fileprivate let baseServerUrl: URL

  fileprivate func newMainWindow(with state: AppState, urls: [URL], cwd: URL) -> MainWindow.State {
    var mainWindow = state.mainWindowTemplate
    mainWindow.uuid = UUID().uuidString
    mainWindow.root = state.root

    let markedUrls = Marked(urls.toDict { url in MainWindow.OpenMode.default })
    mainWindow.urlsToOpen.append(markedUrls)

    mainWindow.cwd = cwd

    mainWindow.preview.server = self.baseServerUrl.appendingPathComponent(PreviewTransformer.nonePath)

    return mainWindow
  }
}
