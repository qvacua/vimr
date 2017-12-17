/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

class MarkdownReducer {

  typealias PreviewToolPair = StateActionPair<UuidState<MainWindow.State>, PreviewTool.Action>
  typealias BufferListPair = StateActionPair<UuidState<MainWindow.State>, BuffersList.Action>
  typealias MainWindowPair = StateActionPair<UuidState<MainWindow.State>, MainWindow.Action>

  static let basePath = "/tools/markdown"
  static let saveFirstPath = "/tools/markdown/save-first.html"
  static let errorPath = "/tools/markdown/error.html"
  static let nonePath = "/tools/markdown/empty.html"

  func reducePreviewTool(_ pair: PreviewToolPair) -> PreviewToolPair {
    var state = pair.state.payload

    switch pair.action {

    case .refreshNow:
      state.preview = PreviewUtils.state(for: pair.state.uuid,
                                         baseUrl: self.baseServerUrl,
                                         buffer: state.currentBuffer,
                                         editorPosition: state.preview.editorPosition,
                                         previewPosition: state.preview.previewPosition)
      state.preview.lastSearch = .reload

    case let .reverseSearch(to:position):
      state.preview.previewPosition = Marked(position)
      state.preview.lastSearch = .reverse

    case let .scroll(to:position):
      if state.preview.lastSearch == .reload {
        state.preview.lastSearch = .none
        break;
      }

      guard state.previewTool.isReverseSearchAutomatically && state.preview.lastSearch != .forward else {
        state.preview.lastSearch = .none
        state.preview.previewPosition = Marked(mark: state.preview.previewPosition.mark, payload: position)
        break;
      }

      state.preview.previewPosition = Marked(position)
      state.preview.lastSearch = .reverse

    default:
      return pair

    }

    return StateActionPair(state: UuidState(uuid: state.uuid, state: state), action: pair.action)
  }

  func reduceOpenedFileList(_ pair: BufferListPair) -> BufferListPair {
    var state = pair.state.payload

    switch pair.action {

    case let .open(buffer):
      state.preview = PreviewUtils.state(for: pair.state.uuid,
                                         baseUrl: self.baseServerUrl,
                                         buffer: buffer,
                                         editorPosition: Marked(.beginning),
                                         previewPosition: Marked(.beginning))
      state.preview.lastSearch = .none

    }

    return StateActionPair(state: UuidState(uuid: pair.state.uuid, state: state), action: pair.action)
  }

  func reduceMainWindow(_ pair: MainWindowPair) -> MainWindowPair {
    var state = pair.state.payload

    switch pair.action {

    case let .newCurrentBuffer(buffer):
      state.preview = PreviewUtils.state(for: pair.state.uuid, baseUrl: self.baseServerUrl, buffer: buffer,
                                         editorPosition: state.preview.editorPosition,
                                         previewPosition: state.preview.previewPosition)
      state.preview.lastSearch = .none

    case .bufferWritten:
      state.preview = PreviewUtils.state(for: pair.state.uuid,
                                         baseUrl: self.baseServerUrl,
                                         buffer: state.currentBuffer,
                                         editorPosition: state.preview.editorPosition,
                                         previewPosition: state.preview.previewPosition)
      state.preview.lastSearch = .reload

    case let .setCursor(to:position):
      if state.preview.lastSearch == .reload {
        state.preview.lastSearch = .none
        break
      }

      guard state.previewTool.isForwardSearchAutomatically && state.preview.lastSearch != .reverse else {
        state.preview.editorPosition = Marked(mark: state.preview.editorPosition.mark, payload: position.payload)
        state.preview.lastSearch = .none
        break
      }

      state.preview.editorPosition = Marked(position.payload)
      state.preview.lastSearch = .none // .none because the forward search does not invoke .scroll above.

    case .close:
      state.preview = PreviewUtils.state(for: .none, baseUrl: self.baseServerUrl)
      state.preview.lastSearch = .none

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
