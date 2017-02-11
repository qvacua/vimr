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
        state.preview.previewPosition = position
        state.preview.ignoreNextForward = true

      case let .setAutomaticReverseSearch(to:value):
        state.previewTool.isReverseSearchAutomatically = value

      case let .setAutomaticForwardSearch(to:value):
        state.previewTool.isForwardSearchAutomatically = value

      case let .setRefreshOnWrite(to:value):
        state.previewTool.isRefreshOnWrite = value

      }

      return StateActionPair(state: UuidState(uuid: state.uuid, state: state), action: pair.action)
    }
  }
}
