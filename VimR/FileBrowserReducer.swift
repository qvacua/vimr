/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import RxSwift

class FileBrowserReducer: Reducer {

  typealias Pair = StateActionPair<UuidState<MainWindow.State>, FileBrowser.Action>

  func reduce(_ source: Observable<Pair>) -> Observable<Pair> {
    return source.map { pair in
      var state = pair.state.payload

      switch pair.action {

      case let .open(url, mode):
        state.urlsToOpen[url] = mode
        state.focusedView = .neoVimView

      case let .setAsWorkingDirectory(url):
        state.cwd = url

      case let .setShowHidden(show):
        state.fileBrowserShowHidden = show

      }

      return StateActionPair(state: UuidState(uuid: state.uuid, state: state), action: pair.action)
    }
  }
}
