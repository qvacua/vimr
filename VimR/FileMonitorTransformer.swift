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
      switch pair.action {

      case let .change(in: url):
        NSLog("change in \(url)")
        return pair

      }
    }
  }
}
