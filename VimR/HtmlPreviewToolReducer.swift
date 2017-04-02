/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import RxSwift

class HtmlPreviewToolReducer: Reducer {

  static let basePath = "tools/html-preview"

  typealias Pair = StateActionPair<UuidState<MainWindow.State>, HtmlPreviewTool.Action>

  init(baseServerUrl: URL) {
    self.baseServerUrl = baseServerUrl
  }

  func reduce(_ source: Observable<Pair>) -> Observable<Pair> {
    return source.map { pair in
      var state = pair.state.payload
      let uuid = pair.state.uuid

      switch pair.action {

      case let .selectHtmlFile(url):
        state.htmlPreview.htmlFile = url
        state.htmlPreview.server = self.baseServerUrl
          .appendingPathComponent("\(uuid)/\(HtmlPreviewToolReducer.basePath)/index.html")

      }

      return StateActionPair(state: UuidState(uuid: state.uuid, state: state), action: pair.action)
    }
  }

  fileprivate let baseServerUrl: URL
}
