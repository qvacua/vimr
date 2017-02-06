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

      case let .cd(to: cwd):
        if state.cwd != cwd {
          state.cwd = cwd
        }

      case let .setBufferList(buffers):
        buffers
          .flatMap { $0.url }
          .forEach { state.urlsToOpen.removeValue(forKey: $0) }
        state.buffers = buffers

      case let .setCurrentBuffer(buffer):
        state.currentBuffer = buffer

      case let .scroll(to: position), let .setCursor(to: position):
        state.cursorPosition = position

      case .close:
        state.isClosed = true

      default:
        return pair

      }

      return StateActionPair(state: UuidState(uuid: state.uuid, state: state), action: pair.action)
    }
  }
}
