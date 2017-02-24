/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import RxSwift

class MainWindowTransformer: Transformer {

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

      case .close:
        state.isClosed = true

      default:
        return pair

      }

      return StateActionPair(state: UuidState(uuid: state.uuid, state: state), action: pair.action)
    }
  }
}
