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

    case let .becomeKey(isFullScreen):
      appState.currentMainWindowUuid = uuid
      appState.mainWindowTemplate = self.mainWindowTemplate(
        from: appState.mainWindowTemplate,
        new: appState.mainWindows[uuid] ?? appState.mainWindowTemplate,
        isFullScreen: isFullScreen
      )

    case let .frameChanged(to: frame):
      if uuid == appState.currentMainWindowUuid {
        appState.mainWindowTemplate.frame = frame
      }

    case let .setToolsState(tools):
      appState.mainWindowTemplate.orderedTools = tools.map { $0.0 }

    case let .toggleAllTools(value):
      appState.mainWindowTemplate.isAllToolsVisible = value

    case let .toggleToolButtons(value):
      appState.mainWindowTemplate.isToolButtonsVisible = value

    case .close:
      if appState.currentMainWindowUuid == uuid, let mainWindowToClose = appState.mainWindows[uuid] {
        appState.mainWindowTemplate = self.mainWindowTemplate(from: appState.mainWindowTemplate,
                                                              new: mainWindowToClose,
                                                              isFullScreen: false)

        appState.currentMainWindowUuid = nil
      }

      appState.mainWindows.removeValue(forKey: uuid)

    case let .setTheme(theme):
      appState.mainWindowTemplate.appearance.theme = Marked(theme)

    default:
      return pair

    }

    return StateActionPair(state: appState, action: pair.action)
  }

  fileprivate func mainWindowTemplate(from old: MainWindow.State,
                                      new: MainWindow.State,
                                      isFullScreen: Bool) -> MainWindow.State {

    var result = old

    if !isFullScreen {
      result.frame = new.frame
    }

    result.isAllToolsVisible = new.isAllToolsVisible
    result.isToolButtonsVisible = new.isToolButtonsVisible
    result.tools = new.tools
    result.orderedTools = new.orderedTools
    result.previewTool = new.previewTool
    result.fileBrowserShowHidden = new.fileBrowserShowHidden
    result.htmlPreview = .default

    return result
  }
}
