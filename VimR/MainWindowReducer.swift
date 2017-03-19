/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import RxSwift

class MainWindowTransformer: Reducer {

  typealias Pair = StateActionPair<UuidState<MainWindow.State>, MainWindow.Action>

  func transform(_ source: Observable<Pair>) -> Observable<Pair> {
    return source.map { pair in
      var state = pair.state.payload

      switch pair.action {

      case let .open(marks):
        state.urlsToOpen = state.urlsToOpen.filter { !marks.contains($0.mark) }

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
        state.focusedView = view

      case let .setState(for: tool, with: workspaceTool):
        state.tools[tool] = WorkspaceToolState(location: workspaceTool.location,
                                               dimension: workspaceTool.dimension,
                                               open: workspaceTool.isSelected)
        if workspaceTool.isSelected {
          state.tools
            .filter { $0 != tool && $1.location == workspaceTool.location }
            .forEach { state.tools[$0.0]?.open = false }
        }

      case let .toggleAllTools(value):
        state.isAllToolsVisible = value

      case let .toggleToolButtons(value):
        state.isToolButtonsVisible = value

      default:
        return pair

      }

      NSLog("\(state.tools[.preview])")
      return StateActionPair(state: UuidState(uuid: state.uuid, state: state), action: pair.action)
    }
  }
}
