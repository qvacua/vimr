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
    return Observable
      .from(self.flatMap { $0 as? Observable<Any> })
      .flatMap { $0 }
  }
}

extension ObservableType {

  func mapOmittingNil<R>(_ transform: @escaping (Self.E) throws -> R?) -> RxSwift.Observable<R> {
    return self
      .map(transform)
      .filter { $0 != nil }
      .map { $0! }
  }
}
