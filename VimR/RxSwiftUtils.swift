/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import RxSwift

extension Array {

  /// This method only makes sense for `Array<Observable<Any>>`.
  /// - Returns: Merged observables
  func toMergedObservables() -> Observable<Any> {
    return self
      .flatMap { $0 as? Observable<Any> }
      .toObservable()
      .flatMap { $0 }
  }
}
