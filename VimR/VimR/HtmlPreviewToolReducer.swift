/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

class HtmlPreviewReducer {

  static let basePath = "tools/html-preview"

  static func serverUrl(baseUrl: URL, uuid: UUID) -> URL {
    baseUrl.appendingPathComponent("\(uuid)/\(basePath)/index.html")
  }

  let mainWindow: MainWindowReducer
  let htmlPreview: HtmlPreviewToolReducer

  init(baseServerUrl: URL) {
    self.mainWindow = MainWindowReducer(baseServerUrl: baseServerUrl)
    self.htmlPreview = HtmlPreviewToolReducer(baseServerUrl: baseServerUrl)
  }

  class MainWindowReducer: ReducerType {

    typealias StateType = MainWindow.State
    typealias ActionType = UuidAction<MainWindow.Action>

    init(baseServerUrl: URL) { self.baseServerUrl = baseServerUrl }

    func typedReduce(_ pair: ReduceTuple) -> ReduceTuple {
      var state = pair.state

      switch pair.action.payload {

      case .setTheme:
        guard state.htmlPreview.htmlFile == nil else { return pair }
        state.htmlPreview.server = Marked(
          HtmlPreviewReducer.serverUrl(baseUrl: self.baseServerUrl, uuid: state.uuid)
        )

      default:
        return pair

      }

      return (state, pair.action, true)
    }

    private let baseServerUrl: URL
  }

  class HtmlPreviewToolReducer: ReducerType {

    typealias StateType = MainWindow.State
    typealias ActionType = UuidAction<HtmlPreviewTool.Action>

    init(baseServerUrl: URL) { self.baseServerUrl = baseServerUrl }

    func typedReduce(_ pair: ReduceTuple) -> ReduceTuple {
      var state = pair.state
      switch pair.action.payload {

      case .selectHtmlFile(let url):
        state.htmlPreview.htmlFile = url
        state.htmlPreview.server = Marked(
          HtmlPreviewReducer.serverUrl(baseUrl: self.baseServerUrl, uuid: state.uuid)
        )

      }

      return (state, pair.action, true)
    }

    private let baseServerUrl: URL
  }
}
