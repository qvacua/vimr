/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import CocoaMarkdown
import RxSwift
import CocoaMarkdown

class PreviewToolTransformer: Transformer {

  typealias Pair = StateActionPair<UuidState<MainWindow.State>, PreviewTool.Action>

  func transform(_ source: Observable<Pair>) -> Observable<Pair> {
    return source.map { pair in
      var state = pair.state.payload

      switch pair.action {

      case .refreshNow:
        return pair

      case let .reverseSearch(to:position):
        return pair

      case .forwardSearch:
        return pair

      case let .scroll(to:position):
        state.preview.previewPosition = Marked(position)

      case let .setAutomaticReverseSearch(to:value):
        return pair

      case let .setAutomaticForwardSearch(to:value):
        return pair

      case let .setRefreshOnWrite(to:value):
        return pair

      }

      return StateActionPair(state: UuidState(uuid: state.uuid, state: state), action: pair.action)
    }
  }
}
