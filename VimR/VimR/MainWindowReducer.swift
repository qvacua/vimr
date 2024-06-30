/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

final class MainWindowReducer: ReducerType {
  typealias StateType = MainWindow.State
  typealias ActionType = UuidAction<MainWindow.Action>

  func typedReduce(_ tuple: ReduceTuple) -> ReduceTuple {
    var state = tuple.state

    switch tuple.action.payload {
    case let .frameChanged(to: frame):
      state.frame = frame

    case let .cd(to: cwd):
      if state.cwd != cwd {
        state.cwd = cwd
      }

    case let .setBufferList(buffers):
      state.buffers = buffers

    case let .newCurrentBuffer(buffer):
      state.currentBuffer = buffer

    case let .setDirtyStatus(status):
      // When I gt or w around, we change tab somehow... Dunno why...
      if status == tuple.state.isDirty {
        return tuple
      }

      state.isDirty = status

    case let .focus(view):
      state.viewToBeFocused = view

    case let .setState(for: tool, with: workspaceTool):
      state.tools[tool] = WorkspaceToolState(
        location: workspaceTool.location,
        dimension: workspaceTool.dimension,
        open: workspaceTool.isSelected
      )
      if workspaceTool.isSelected {
        state.tools
          .filter { $0 != tool && $1.location == workspaceTool.location }
          .forEach { state.tools[$0.0]?.open = false }
      }

    case let .setToolsState(tools):
      state.orderedTools = []
      for toolPair in tools {
        let toolId = toolPair.0
        let tool = toolPair.1

        state.tools[toolId] = WorkspaceToolState(
          location: tool.location,
          dimension: tool.dimension,
          open: tool.isSelected
        )

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

    case .makeSessionTemporary:
      state.isTemporarySession = true

    default:
      return tuple
    }

    return (state, tuple.action, true)
  }
}
