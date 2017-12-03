/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

class HtmlPreviewToolReducer {

  typealias Pair = StateActionPair<UuidState<MainWindow.State>, HtmlPreviewTool.Action>

  static let basePath = "/tools/html-preview"
  static let selectFirstPath = "/tools/html-preview/select-first.html"

  init(baseServerUrl: URL) {
    self.baseServerUrl = baseServerUrl
  }

  func reduce(_ pair: Pair) -> Pair {
    var state = pair.state.payload
    let uuid = pair.state.uuid

    switch pair.action {

    case let .selectHtmlFile(url):
      state.htmlPreview.htmlFile = url
      state.htmlPreview.server = Marked(
        self.baseServerUrl.appendingPathComponent("\(uuid)/\(HtmlPreviewToolReducer.basePath)/index.html")
      )

    }

    return StateActionPair(state: UuidState(uuid: state.uuid, state: state), action: pair.action)
  }

  fileprivate let baseServerUrl: URL
}
