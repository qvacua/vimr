/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import RxSwift

class OpenQuicklyTransformer: Transformer {

  typealias Pair = StateActionPair<AppState, MainWindow.Action>

  func transform(_ source: Observable<Pair>) -> Observable<Pair> {
    return source.map { pair in

      switch pair.action {

      case .openQuickly:
        return pair

      default:
        return pair

      }
    }
  }
}
