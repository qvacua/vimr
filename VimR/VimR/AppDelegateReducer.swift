/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

class AppDelegateReducer {

  typealias Pair = StateActionPair<AppState, AppDelegate.Action>

  init(baseServerUrl: URL) {
    self.baseServerUrl = baseServerUrl
  }

  func reduce(_ pair: Pair) -> Pair {
    var state = pair.state

    switch pair.action {

    case let .newMainWindow(urls, cwd, nvimArgs, cliPipePath):
      let mainWindow: MainWindow.State
      if let args = nvimArgs {
        mainWindow = self.newMainWindow(with: state, urls: [], cwd: cwd, nvimArgs: args, cliPipePath: cliPipePath)
      } else {
        mainWindow = self.newMainWindow(with: state, urls: urls, cwd: cwd, cliPipePath: cliPipePath)
      }

      state.mainWindows[mainWindow.uuid] = mainWindow

    case let .openInKeyWindow(urls, cwd):
      guard let uuid = state.currentMainWindowUuid, state.mainWindows[uuid] != nil else {
        let mainWindow = self.newMainWindow(with: state, urls: urls, cwd: cwd)
        state.mainWindows[mainWindow.uuid] = mainWindow
        break
      }

      state.mainWindows[uuid]?.urlsToOpen = urls.toDict { url in MainWindow.OpenMode.default }
      state.mainWindows[uuid]?.cwd = cwd

    case .preferences:
      state.preferencesOpen = Marked(true)

    }

    return StateActionPair(state: state, action: pair.action)
  }

  private let baseServerUrl: URL

  private func newMainWindow(with state: AppState,
                                 urls: [URL],
                                 cwd: URL,
                                 nvimArgs: [String]? = nil,
                                 cliPipePath: String? = nil) -> MainWindow.State {

    var mainWindow = state.mainWindowTemplate

    mainWindow.uuid = UUID().uuidString
    mainWindow.cwd = cwd
    mainWindow.isDirty = false

    mainWindow.htmlPreview = HtmlPreviewState(
      htmlFile: nil,
      server: Marked(self.baseServerUrl.appendingPathComponent(HtmlPreviewToolReducer.selectFirstPath))
    )
    mainWindow.preview.server = self.baseServerUrl.appendingPathComponent(MarkdownReducer.nonePath)

    mainWindow.nvimArgs = nvimArgs
    mainWindow.cliPipePath = cliPipePath
    mainWindow.urlsToOpen = urls.toDict { _ in MainWindow.OpenMode.default }
    mainWindow.frame = state.mainWindows.isEmpty ? state.mainWindowTemplate.frame
                                                 : self.frame(relativeTo: state.mainWindowTemplate.frame)

    return mainWindow
  }

  private func frame(relativeTo refFrame: CGRect) -> CGRect {
    return refFrame.offsetBy(dx: cascadeX, dy: -cascadeY)
  }
}

private let cascadeX: CGFloat = 24.0
private let cascadeY: CGFloat = 24.0
