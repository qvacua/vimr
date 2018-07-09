/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

class MarkdownReducer {

  static let basePath = "/tools/markdown"
  static let saveFirstPath = "/tools/markdown/save-first.html"
  static let errorPath = "/tools/markdown/error.html"
  static let nonePath = "/tools/markdown/empty.html"

  let previewTool: PreviewToolReducer
  let buffersList: BuffersListReducer
  let mainWindow: MainWindowReducer

  init(baseServerUrl: URL) {
    self.previewTool = PreviewToolReducer(baseServerUrl: baseServerUrl)
    self.buffersList = BuffersListReducer(baseServerUrl: baseServerUrl)
    self.mainWindow = MainWindowReducer(baseServerUrl: baseServerUrl)
  }

  class PreviewToolReducer: ReducerType {

    typealias StateType = MainWindow.State
    typealias ActionType = UuidAction<PreviewTool.Action>

    func typedReduce(_ tuple: ReduceTuple) -> ReduceTuple {
      var state = tuple.state

      switch tuple.action.payload {

      case .refreshNow:
        state.preview = PreviewUtils.state(for: tuple.state.uuid,
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
        return tuple

      }

      return (state, tuple.action, true)
    }

    init(baseServerUrl: URL) {
      self.baseServerUrl = baseServerUrl
    }

    private let baseServerUrl: URL
  }

  class BuffersListReducer: ReducerType {

    typealias StateType = MainWindow.State
    typealias ActionType = UuidAction<BuffersList.Action>

    func typedReduce(_ tuple: ReduceTuple) -> ReduceTuple {
      var state = tuple.state

      switch tuple.action.payload {

      case let .open(buffer):
        state.preview = PreviewUtils.state(for: tuple.state.uuid,
                                           baseUrl: self.baseServerUrl,
                                           buffer: buffer,
                                           editorPosition: Marked(.beginning),
                                           previewPosition: Marked(.beginning))
        state.preview.lastSearch = .none

      }

      return (state, tuple.action, true)
    }

    init(baseServerUrl: URL) {
      self.baseServerUrl = baseServerUrl
    }

    private let baseServerUrl: URL
  }

  class MainWindowReducer: ReducerType {

    typealias StateType = MainWindow.State
    typealias ActionType = UuidAction<MainWindow.Action>

    func typedReduce(_ tuple: ReduceTuple) -> ReduceTuple {
      var state = tuple.state

      switch tuple.action.payload {

      case let .newCurrentBuffer(buffer):
        state.preview = PreviewUtils.state(for: tuple.state.uuid, baseUrl: self.baseServerUrl, buffer: buffer,
                                           editorPosition: state.preview.editorPosition,
                                           previewPosition: state.preview.previewPosition)
        state.preview.lastSearch = .none

      case .bufferWritten:
        state.preview = PreviewUtils.state(for: tuple.state.uuid,
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
        state.preview = PreviewUtils.state(for: .none,
                                           baseUrl: self.baseServerUrl,
                                           editorPosition: state.preview.editorPosition,
                                           previewPosition: state.preview.previewPosition)
        state.preview.lastSearch = .none

      default:
        return tuple
      }

      return (state, tuple.action, true)
    }

    init(baseServerUrl: URL) {
      self.baseServerUrl = baseServerUrl
    }

    private let baseServerUrl: URL
  }
}
