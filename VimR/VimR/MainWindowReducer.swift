/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

class MainWindowReducer {

  typealias Pair = StateActionPair<UuidState<MainWindow.State>, MainWindow.Action>

  func reduce(_ pair: Pair) -> Pair {
    var state = pair.state.payload

    switch pair.action {

    case let .frameChanged(to:frame):
      state.frame = frame

    case let .cd(to:cwd):
      if state.cwd != cwd {
        state.cwd = cwd
      }

    case let .setBufferList(buffers):
      state.buffers = buffers

    case let .setCurrentBuffer(buffer):
      state.currentBuffer = buffer

    case let .setDirtyStatus(status):
      // When I gt or w around, we change tab somehow... Dunno why...
      if status == pair.state.payload.isDirty {
        return pair
      }

      state.isDirty = status

      // if we scroll for reverse search we get scroll and set cursor event
    case let .setCursor(to:position):
      state.preview.forceNextReverse = false

      if state.preview.ignoreNextForward {
        state.preview.editorPosition = Marked(mark: state.preview.editorPosition.mark, payload: position.payload)
        state.preview.ignoreNextForward = false
      } else {
        state.preview.editorPosition = position
      }

    case let .focus(view):
      state.viewToBeFocused = view

    case let .setState(for: tool, with: workspaceTool):
      state.tools[tool] = WorkspaceToolState(location: workspaceTool.location,
                                             dimension: workspaceTool.dimension,
                                             open: workspaceTool.isSelected)
      if workspaceTool.isSelected {
        state.tools
          .filter { $0 != tool && $1.location == workspaceTool.location }
          .forEach { state.tools[$0.0]?.open = false }
      }

    case let .setToolsState(tools):
      state.orderedTools = []
      tools.forEach { toolPair in
        let toolId = toolPair.0
        let tool = toolPair.1

        state.tools[toolId] = WorkspaceToolState(location: tool.location,
                                                 dimension: tool.dimension,
                                                 open: tool.isSelected)

        if tool.isSelected {
          state.tools
            .filter { $0 != toolId && $1.location == tool.location }
            .forEach { state.tools[$0.0]?.open = false }
        }

        state.orderedTools.append(toolId)
      }

    case let .toggleAllTools(value):
      state.isAllToolsVisible = value

    case let .toggleToolButtons(value):
      state.isToolButtonsVisible = value

    case let .setTheme(theme):
      state.appearance.theme = Marked(theme)

    default:
      return pair

    }

    return StateActionPair(state: UuidState(uuid: state.uuid, state: state), action: pair.action)
  }
}
