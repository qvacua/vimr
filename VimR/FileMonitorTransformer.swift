/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import RxSwift

class FileMonitorTransformer: Transformer {

  typealias Pair = StateActionPair<AppState, FileMonitor.Action>

  func transform(_ source: Observable<Pair>) -> Observable<Pair> {
    return source.map { pair in
      let state = pair.state

      switch pair.action {

      case let .change(in: url):
        NSLog("change in \(url)")
        FileItemUtils.item(for: url, root: state.root, create: false)?.needsScanChildren = true

      }

      return StateActionPair(state: state, action: pair.action)
    }
  }
}
