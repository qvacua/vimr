/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

class BuffersListReducer: ReducerType {
  typealias StateType = MainWindow.State
  typealias ActionType = UuidAction<BuffersList.Action>

  func typedReduce(_ tuple: ReduceTuple) -> ReduceTuple {
    var state = tuple.state

    switch tuple.action.payload {
    case let .open(buffer):
      state.currentBufferToSet = buffer
    }

    return (state, tuple.action, true)
  }
}
