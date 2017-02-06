/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import CocoaMarkdown
import RxSwift
import CocoaMarkdown

class PreviewToolTransformer: Transformer {

  typealias Pair = StateActionPair<UuidState<MainWindow.State>, PreviewTool.Action>

  func transform(_ source: Observable<Pair>) -> Observable<Pair> {
    return source
  }
}
