/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

protocol SerializableState {

  init?(dict: [String: Any])

  func dict() -> [String: Any]
}

class Keys {

  static let openNewOnLaunch = "open-new-window-when-launching"
  static let openNewOnReactivation = "open-new-window-on-reactivation"
  static let useSnapshotUpdateChannel = "use-snapshot-update-channel"

  class OpenQuickly {

    static let key = "open-quickly"

    static let ignorePatterns = "ignore-patterns"
  }

  class Appearance {

    static let key = "appearance"

    static let editorFontName = "editor-font-name"
    static let editorFontSize = "editor-font-size"
    static let editorLinespacing = "editor-linespacing"
    static let editorUsesLigatures = "editor-uses-ligatures"
  }

  class MainWindow {

    static let key = "main-window"

    static let allToolsVisible = "is-all-tools-visible"
    static let toolButtonsVisible = "is-tool-buttons-visible"
    static let orderedTools = "ordered-tools"
    static let activeTools = "active-tools"

    static let isShowHidden = "is-show-hidden"
  }

  class PreviewTool {

    static let key = "preview-tool"

    static let forwardSearchAutomatically = "is-forward-search-automatically"
    static let reverseSearchAutomatically = "is-reverse-search-automatically"
    static let refreshOnWrite = "is-refresh-on-write"
  }

  class WorkspaceTool {

    static let key = "workspace-tool"

    static let location = "location"
    static let open = "is-visible"
    static let dimension = "dimension"
  }
}
