/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

class BuffersListReducer {

  typealias Pair = StateActionPair<UuidState<MainWindow.State>, BuffersList.Action>

  func reduce(_ pair: Pair) -> Pair {
    var state = pair.state.payload

    switch pair.action {

    case let .open(buffer):
      state.currentBufferToSet = buffer

    }

    return StateActionPair(state: UuidState(uuid: pair.state.uuid, state: state), action: pair.action)
  }
}
