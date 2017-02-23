/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import RxSwift

struct AppState {

  static let `default` = AppState(mainWindow: MainWindow.State.default)

  var mainWindowTemplate: MainWindow.State
  var currentMainWindowUuid: String?

  var mainWindows: [String: MainWindow.State] = [:]
  var quitWhenNoMainWindow = false

  let root = FileItem(URL(fileURLWithPath: "/", isDirectory: true))

  var openQuickly = OpenQuicklyWindow.State.default

  init(mainWindow: MainWindow.State) {
    self.mainWindowTemplate = mainWindow
    self.mainWindowTemplate.root = self.root
  }
}

extension OpenQuicklyWindow {

  struct State {

    static let `default` = State()

    var flatFileItems = Observable<[FileItem]>.empty()
    var cwd = FileUtils.userHomeUrl
    var ignorePatterns = [FileItemIgnorePattern]()
    var ignoreToken = Token()

    var open = false
  }
}

struct PreviewState {

  static let `default` = PreviewState()

  enum Status {

    case none
    case notSaved
    case error
    case markdown
  }

  var status = Status.none

  var buffer: URL?
  var html: URL?
  var server: URL?

  var updateDate: Date

  var editorPosition = Marked(Position.beginning)
  var previewPosition = Marked(Position.beginning)
  var ignoreNextForward = false
  var forceNextReverse = false

  init(status: Status = .none,
       buffer: URL? = nil,
       html: URL? = nil,
       server: URL? = nil,
       updateDate: Date = Date())
  {
    self.status = status
    self.buffer = buffer
    self.html = html
    self.server = server
    self.updateDate = updateDate
  }
}

extension MainWindow {

  struct State {

    static let `default` = State(isAllToolsVisible: true, isToolButtonsVisible: true)

    var isAllToolsVisible = true
    var isToolButtonsVisible = true

    ////// transient

    // must be replaced
    var root = FileItem(URL(fileURLWithPath: "/", isDirectory: true))

    var preview = PreviewState.default
    var previewTool = PreviewTool.State.default

    var fileBrowserShowHidden = false

    var isClosed = false

    // neovim
    var uuid = UUID().uuidString
    var currentBuffer: NeoVimBuffer?
    var buffers = [NeoVimBuffer]()
    var cwd = FileUtils.userHomeUrl

    var isDirty = false

    var font = NSFont.userFixedPitchFont(ofSize: 13)!
    var linespacing: CGFloat = 1
    var isUseLigatures = false
    var isUseInteractiveZsh = false

    // transient^2
    var urlsToOpen = [Marked<[URL: OpenMode]>]()

    init(isAllToolsVisible: Bool, isToolButtonsVisible: Bool) {
      self.isAllToolsVisible = isAllToolsVisible
      self.isToolButtonsVisible = isToolButtonsVisible
    }
  }
}

extension PreviewTool {

  struct State {

    static let `default` = State()

    var isForwardSearchAutomatically = false
    var isReverseSearchAutomatically = false
    var isRefreshOnWrite = true
  }
}
