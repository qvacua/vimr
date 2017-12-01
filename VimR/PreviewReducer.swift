/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

class MarkdownReducer {

  typealias Pair = StateActionPair<UuidState<MainWindow.State>, BuffersList.Action>
  typealias MainWindowPair = StateActionPair<UuidState<MainWindow.State>, MainWindow.Action>

  static let basePath = "/tools/markdown"
  static let saveFirstPath = "/tools/markdown/save-first.html"
  static let errorPath = "/tools/markdown/error.html"
  static let nonePath = "/tools/markdown/empty.html"

  func reduceOpenedFileList(_ pair: Pair) -> Pair {
    var state = pair.state.payload

    switch pair.action {

    case let .open(buffer):
      state.preview = PreviewUtils.state(for: pair.state.uuid, baseUrl: self.baseServerUrl, buffer: buffer)

    }

    return StateActionPair(state: UuidState(uuid: pair.state.uuid, state: state), action: pair.action)
  }

  func reduceMainWindow(_ pair: MainWindowPair) -> MainWindowPair {
    var state = pair.state.payload

    switch pair.action {

    case let .setCurrentBuffer(buffer):
      guard state.previewTool.isRefreshOnWrite else {
        return pair
      }

      state.preview = PreviewUtils.state(for: pair.state.uuid, baseUrl: self.baseServerUrl, buffer: buffer)
      state.preview.ignoreNextReverse = true

    case .close:
      state.preview = PreviewUtils.state(for: .none, baseUrl: self.baseServerUrl)

    default:
      return pair
    }

    return StateActionPair(state: UuidState(uuid: pair.state.uuid, state: state), action: pair.action)
  }

  init(baseServerUrl: URL) {
    self.baseServerUrl = baseServerUrl
  }

  fileprivate let baseServerUrl: URL
}
