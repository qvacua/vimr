/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import RxSwift

extension ObservableType {

  func mapOmittingNil<R>(_ transform: @escaping (Self.E) throws -> R?) -> RxSwift.Observable<R> {
    return self
      .map(transform)
      .filter { $0 != nil }
      .map { $0! }
  }
}
