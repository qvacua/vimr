/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

class UiRootReducer {

  typealias Pair = StateActionPair<AppState, UuidAction<MainWindow.Action>>

  func reduce(_ pair: Pair) -> Pair {
    var appState = pair.state
    let uuid = pair.action.uuid

    switch pair.action.payload {

    case .becomeKey:
      appState.currentMainWindowUuid = uuid
      appState.mainWindowTemplate = appState.mainWindows[uuid] ?? appState.mainWindowTemplate

    case .close:
      if appState.currentMainWindowUuid == uuid, let mainWindowToClose = appState.mainWindows[uuid] {
        appState.mainWindowTemplate.isAllToolsVisible = mainWindowToClose.isAllToolsVisible
        appState.mainWindowTemplate.isToolButtonsVisible = mainWindowToClose.isToolButtonsVisible
        appState.mainWindowTemplate.tools = mainWindowToClose.tools
        appState.mainWindowTemplate.previewTool = mainWindowToClose.previewTool
        appState.mainWindowTemplate.fileBrowserShowHidden = mainWindowToClose.fileBrowserShowHidden
        appState.mainWindowTemplate.htmlPreview = .default

        appState.currentMainWindowUuid = nil
      }

      appState.mainWindows.removeValue(forKey: uuid)

    default:
      return pair

    }

    return StateActionPair(state: appState, action: pair.action)
  }
}
