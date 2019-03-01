/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

class UiRootReducer: ReducerType {

  typealias StateType = AppState
  typealias ActionType = UiRoot.Action

  let mainWindow = MainWindowReducer()

  func typedReduce(_ tuple: ReduceTuple) -> ReduceTuple {
    var appState = tuple.state

    switch tuple.action {

    case .quit:
      appState.quit = true

    }

    return (appState, tuple.action, true)
  }

  class MainWindowReducer: ReducerType {

    typealias StateType = AppState
    typealias ActionType = UuidAction<MainWindow.Action>

    func typedReduce(_ tuple: ReduceTuple) -> ReduceTuple {
      var appState = tuple.state
      let uuid = tuple.action.uuid

      switch tuple.action.payload {

      case let .becomeKey(isFullScreen):
        appState.currentMainWindowUuid = uuid

        if appState.mainWindows[uuid]?.isTemporarySession == true {
          break
        }

        appState.mainWindowTemplate = self.mainWindowTemplate(
          from: appState.mainWindowTemplate,
          new: appState.mainWindows[uuid] ?? appState.mainWindowTemplate,
          isFullScreen: isFullScreen
        )

      case let .frameChanged(to:frame):
        if appState.mainWindows[uuid]?.isTemporarySession == true {
          break
        }

        if uuid == appState.currentMainWindowUuid {
          appState.mainWindowTemplate.frame = frame
        }

      case let .setToolsState(tools):
        if appState.mainWindows[uuid]?.isTemporarySession == true {
          break
        }

        appState.mainWindowTemplate.orderedTools = tools.map { $0.0 }

      case let .toggleAllTools(value):
        if appState.mainWindows[uuid]?.isTemporarySession == true {
          break
        }

        appState.mainWindowTemplate.isAllToolsVisible = value

      case let .toggleToolButtons(value):
        if appState.mainWindows[uuid]?.isTemporarySession == true {
          break
        }

        appState.mainWindowTemplate.isToolButtonsVisible = value

      case .close:
        if appState.mainWindows[uuid]?.isTemporarySession == true {
          break
        }

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
        return tuple

      }

      return (appState, tuple.action, true)
    }

    private func mainWindowTemplate(from old: MainWindow.State,
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
}
