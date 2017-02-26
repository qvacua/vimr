/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import RxSwift

class OpenedFileListTransformer: Transformer {

  typealias Pair = StateActionPair<UuidState<MainWindow.State>, OpenedFileList.Action>

  func transform(_ source: Observable<Pair>) -> Observable<Pair> {
    return source.map { pair in
      var state = pair.state.payload

      switch pair.action {

        case let .open(buffer):
          state.currentBuffer = buffer

      }

      return StateActionPair(state: UuidState(uuid: pair.state.uuid, state: state), action: pair.action)
    }
  }
}
