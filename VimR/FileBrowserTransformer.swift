/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import RxSwift

class FileBrowserTransformer: Transformer {

  typealias Pair = StateActionPair<UuidState<MainWindow.State>, FileBrowser.Action>

  func transform(_ source: Observable<Pair>) -> Observable<Pair> {
    return source.map { pair in
      var state = pair.state.payload

      switch pair.action {

      case let .open(url, mode):
        state.urlsToOpen.append(Marked([url: mode]))
        state.focusedView = .neoVimView

      case let .setAsWorkingDirectory(url):
        state.cwd = url

      }

      return StateActionPair(state: UuidState(uuid: state.uuid, state: state), action: pair.action)
    }
  }
}
