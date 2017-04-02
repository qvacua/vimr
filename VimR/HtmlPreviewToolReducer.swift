/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import RxSwift

class HtmlPreviewToolReducer: Reducer {

  typealias Pair = StateActionPair<UuidState<MainWindow.State>, HtmlPreviewTool.Action>

  init(baseServerUrl: URL) {
    self.baseServerUrl = baseServerUrl
  }

  func reduce(_ source: Observable<Pair>) -> Observable<Pair> {
    return source.map { pair in
      var state = pair.state.payload

      switch pair.action {

      case let .selectHtmlFile(url):
        state.preview = PreviewUtils.state(for: pair.state.uuid,
                                           baseUrl: self.baseServerUrl,
                                           buffer: state.currentBuffer)

        return StateActionPair(state: UuidState(uuid: state.uuid, state: state), action: pair.action)
      }
    }
  }

  fileprivate let baseServerUrl: URL
}
