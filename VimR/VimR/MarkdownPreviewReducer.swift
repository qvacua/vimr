/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import NvimView
import Commons

class MarkdownPreviewReducer {

  static private func previewState(
    for uuid: UUID,
    baseUrl: URL,
    buffer: NvimView.Buffer?,
    editorPosition: Marked<Position>,
    previewPosition: Marked<Position>
  ) -> PreviewState {
    var state = PreviewState(
      html: self.htmlUrl(with: uuid),
      server: self.serverUrl(for: uuid, baseUrl: baseUrl, lastComponent: indexHtml),
      editorPosition: editorPosition,
      previewPosition: previewPosition
    )

    state.status = .notSaved
    guard let url = buffer?.url else { return state }

    state.status = .error
    guard FileUtils.fileExists(at: url) else { return state }

    state.status = .none
    guard self.extensions.contains(url.pathExtension) else { return state }

    state.status = .markdown
    state.buffer = url
    return state
  }

  private static func serverUrl(for uuid: UUID, baseUrl: URL, lastComponent: String) -> URL {
    baseUrl.appendingPathComponent("\(uuid)/tools/markdown/\(lastComponent)")
  }

  private static func htmlUrl(with uuid: UUID) -> URL {
    FileUtils.tempDir().appendingPathComponent("\(uuid)-markdown-index.html")
  }

  private static let extensions = Set(["md", "markdown", "mdown", "mkdn", "mkd"])

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
    typealias ActionType = UuidAction<MarkdownTool.Action>

    func typedReduce(_ tuple: ReduceTuple) -> ReduceTuple {
      var state = tuple.state

      switch tuple.action.payload {

      case .refreshNow:
        state.preview = MarkdownPreviewReducer.previewState(
          for: tuple.state.uuid,
          baseUrl: self.baseServerUrl,
          buffer: state.currentBuffer,
          editorPosition: state.preview.editorPosition,
          previewPosition: state.preview.previewPosition
        )
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

    init(baseServerUrl: URL) { self.baseServerUrl = baseServerUrl }

    private let baseServerUrl: URL
  }

  class BuffersListReducer: ReducerType {

    typealias StateType = MainWindow.State
    typealias ActionType = UuidAction<BuffersList.Action>

    func typedReduce(_ tuple: ReduceTuple) -> ReduceTuple {
      var state = tuple.state

      switch tuple.action.payload {

      case let .open(buffer):
        state.preview = MarkdownPreviewReducer.previewState(
          for: tuple.state.uuid,
          baseUrl: self.baseServerUrl,
          buffer: buffer,
          editorPosition: Marked(.beginning),
          previewPosition: Marked(.beginning)
        )
        state.preview.lastSearch = .none

      }

      return (state, tuple.action, true)
    }

    init(baseServerUrl: URL) { self.baseServerUrl = baseServerUrl }

    private let baseServerUrl: URL
  }

  class MainWindowReducer: ReducerType {

    typealias StateType = MainWindow.State
    typealias ActionType = UuidAction<MainWindow.Action>

    func typedReduce(_ tuple: ReduceTuple) -> ReduceTuple {
      var state = tuple.state

      switch tuple.action.payload {

      case let .newCurrentBuffer(buffer):
        state.preview = MarkdownPreviewReducer.previewState(
          for: tuple.state.uuid,
          baseUrl: self.baseServerUrl,
          buffer: buffer,
          editorPosition: state.preview.editorPosition,
          previewPosition: state.preview.previewPosition
        )
        state.preview.lastSearch = .none

      case .bufferWritten:
        state.preview = MarkdownPreviewReducer.previewState(
          for: tuple.state.uuid,
          baseUrl: self.baseServerUrl,
          buffer: state.currentBuffer,
          editorPosition: state.preview.editorPosition,
          previewPosition: state.preview.previewPosition
        )
        state.preview.lastSearch = .reload

      case let .setCursor(to:position):
        if state.preview.lastSearch == .reload {
          state.preview.lastSearch = .none
          break
        }

        guard state.previewTool.isForwardSearchAutomatically,
              state.preview.lastSearch != .reverse else {
          state.preview.editorPosition = Marked(
            mark: state.preview.editorPosition.mark,
            payload: position.payload
          )
          state.preview.lastSearch = .none
          break
        }

        state.preview.editorPosition = Marked(position.payload)

        // .none because the forward search does not invoke .scroll above.
        state.preview.lastSearch = .none

      case .close:
        state.preview = self.stateForClose(state)
        state.preview.lastSearch = .none

      default:
        return tuple
      }

      return (state, tuple.action, true)
    }

    init(baseServerUrl: URL) { self.baseServerUrl = baseServerUrl }

    private func stateForClose(_ state: StateType) -> PreviewState {
      PreviewState(
        status: .none,
        html: MarkdownPreviewReducer.htmlUrl(with: state.uuid),
        server: MarkdownPreviewReducer.serverUrl(
          for: state.uuid,
          baseUrl: self.baseServerUrl,
          lastComponent: indexHtml
        ),
        editorPosition: state.preview.editorPosition,
        previewPosition: state.preview.previewPosition
      )
    }

    private let baseServerUrl: URL
  }
}

private let indexHtml = "index.html"
