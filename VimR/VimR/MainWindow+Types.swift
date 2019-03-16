/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa

extension MainWindow {

  enum Action {

    case cd(to: URL)
    case setBufferList([NvimView.Buffer])

    case newCurrentBuffer(NvimView.Buffer)
    case bufferWritten(NvimView.Buffer)
    case setDirtyStatus(Bool)

    case becomeKey(isFullScreen: Bool)
    case frameChanged(to: CGRect)

    case scroll(to: Marked<Position>)
    case setCursor(to: Marked<Position>)

    case focus(FocusableView)

    case openQuickly

    case toggleAllTools(Bool)
    case toggleToolButtons(Bool)
    case setState(for: Tools, with: WorkspaceTool)
    case setToolsState([(Tools, WorkspaceTool)])

    case makeSessionTemporary

    case setTheme(Theme)

    case close

    // RPC actions
    case setFont(NSFont)
    case setLinespacing(CGFloat)
  }

  enum FocusableView {

    case neoVimView
    case fileBrowser
    case bufferList
    case markdownPreview
    case htmlPreview
  }

  enum Tools: String, Codable {

    static let all = Set(
      [
        Tools.fileBrowser,
        Tools.buffersList,
        Tools.preview,
        Tools.htmlPreview
      ]
    )

    case fileBrowser = "com.qvacua.vimr.tools.file-browser"
    case buffersList = "com.qvacua.vimr.tools.opened-files-list"
    case preview = "com.qvacua.vimr.tools.preview"
    case htmlPreview = "com.qvacua.vimr.tools.html-preview"
  }

  enum OpenMode {

    case `default`
    case currentTab
    case newTab
    case horizontalSplit
    case verticalSplit
  }
}
