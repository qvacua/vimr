/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

class OpenedFileListReducer {

  typealias Pair = StateActionPair<UuidState<MainWindow.State>, OpenedFileList.Action>

  func reduce(_ pair: Pair) -> Pair {
    var state = pair.state.payload

    switch pair.action {

    case let .open(buffer):
      state.currentBuffer = buffer

    }

    return StateActionPair(state: UuidState(uuid: pair.state.uuid, state: state), action: pair.action)
  }
}
