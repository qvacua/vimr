/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

class FileBrowserReducer: ReducerType {

  typealias StateType = MainWindow.State
  typealias ActionType = UuidAction<FileBrowser.Action>

  func typedReduce(_ tuple: ReduceTuple) -> ReduceTuple {
    var state = tuple.state

    switch tuple.action.payload {

    case let .open(url, mode):
      state.urlsToOpen[url] = mode
      state.viewToBeFocused = .neoVimView

    case let .setAsWorkingDirectory(url):
      state.cwdToSet = url

    case let .setShowHidden(show):
      state.fileBrowserShowHidden = show

    case .refresh:
      state.lastFileSystemUpdate = Marked(state.cwd)

    }

    return (state, tuple.action, true)
  }
}
