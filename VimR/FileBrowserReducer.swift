/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

class FileBrowserReducer {

  typealias Pair = StateActionPair<UuidState<MainWindow.State>, FileBrowser.Action>

  func reduce(_ pair: Pair) -> Pair {
    var state = pair.state.payload

    switch pair.action {

    case let .open(url, mode):
      state.urlsToOpen[url] = mode
      state.viewToBeFocused = .neoVimView

    case let .setAsWorkingDirectory(url):
      state.cwd = url

    case let .setShowHidden(show):
      state.fileBrowserShowHidden = show

    case .refresh:
      guard let fileItem = FileItemUtils.item(for: state.cwd, root: state.root, create: false) else {
        return pair
      }

      state.lastFileSystemUpdate = Marked(fileItem)

    }

    return StateActionPair(state: UuidState(uuid: state.uuid, state: state), action: pair.action)
  }
}
