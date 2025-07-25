/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

final class AppDelegateReducer: ReducerType {
  typealias StateType = AppState
  typealias ActionType = AppDelegate.Action

  init(baseServerUrl: URL) {
    self.baseServerUrl = baseServerUrl
  }

  func typedReduce(_ tuple: ReduceTuple<StateType, ActionType>)
    -> ReduceTuple<StateType, ActionType>
  {
    var state = tuple.state

    switch tuple.action {
    case let .newMainWindow(config):
      let mainWindow = self.newMainWindow(with: state, config: config)
      state.mainWindows[mainWindow.uuid] = mainWindow

    case let .openInKeyWindow(config):
      guard let uuid = state.currentMainWindowUuid, state.mainWindows[uuid] != nil else {
        let mainWindow = self.newMainWindow(with: state, config: config)
        state.mainWindows[mainWindow.uuid] = mainWindow
        break
      }

      state.mainWindows[uuid]?.urlsToOpen = config.urls.toDict { _ in MainWindow.OpenMode.default }
      state.mainWindows[uuid]?.cwd = config.cwd
      if let line = config.line {
        state.mainWindows[uuid]?.goToLineFromCli = Marked(line)
      }

    case .preferences:
      state.preferencesOpen = Marked(true)
    }

    return ReduceTuple(state: state, action: tuple.action, modified: true)
  }

  private let baseServerUrl: URL

  private func newMainWindow(with state: AppState, config: AppDelegate.OpenConfig) -> MainWindow
    .State
  {
    var mainWindow = state.mainWindowTemplate

    mainWindow.uuid = UUID()
    mainWindow.cwd = config.cwd
    mainWindow.isDirty = false

    mainWindow.htmlPreview = HtmlPreviewState(
      htmlFile: nil,
      server: Marked(
        HtmlPreviewReducer.serverUrl(baseUrl: self.baseServerUrl, uuid: mainWindow.uuid)
      )
    )
    mainWindow.preview.server = nil

    mainWindow.usesVcsIgnores = state.openQuickly.defaultUsesVcsIgnores
    mainWindow.nvimArgs = config.nvimArgs
    mainWindow.cliPipePath = config.cliPipePath
    mainWindow.envDict = config.envDict
    mainWindow.urlsToOpen = config.urls.toDict { _ in MainWindow.OpenMode.default }
    mainWindow.frame = state.mainWindows.isEmpty ? state.mainWindowTemplate.frame
      : self.frame(relativeTo: state.mainWindowTemplate.frame)
    if let line = config.line {
      mainWindow.goToLineFromCli = Marked(line)
    }

    return mainWindow
  }

  private func frame(relativeTo refFrame: CGRect) -> CGRect {
    refFrame.offsetBy(dx: cascadeX, dy: -cascadeY)
  }
}

private let cascadeX: CGFloat = 24.0
private let cascadeY: CGFloat = 24.0
