/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

class HtmlPreviewToolReducer: ReducerType {

  typealias StateType = MainWindow.State
  typealias ActionType = UuidAction<HtmlPreviewTool.Action>

  static let basePath = "/tools/html-preview"
  static let selectFirstPath = "/tools/html-preview/select-first.html"

  init(baseServerUrl: URL) {
    self.baseServerUrl = baseServerUrl
  }

  func typedReduce(_ pair: ReduceTuple) -> ReduceTuple {
    var state = pair.state
    let uuid = pair.action.uuid

    switch pair.action.payload {

    case let .selectHtmlFile(url):
      state.htmlPreview.htmlFile = url
      state.htmlPreview.server = Marked(
        self.baseServerUrl.appendingPathComponent("\(uuid)/\(HtmlPreviewToolReducer.basePath)/index.html")
      )

    }

    return (state, pair.action, true)
  }

  private let baseServerUrl: URL
}
