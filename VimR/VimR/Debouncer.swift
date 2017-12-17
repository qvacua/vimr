/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import RxSwift

class Debouncer<T> {

  let observable: Observable<T>

  init(interval: RxTimeInterval) {
    self.observable = self.subject.throttle(interval, latest: true, scheduler: self.scheduler)
  }

  deinit {
    self.subject.onCompleted()
  }

  func call(_ element: T) {
    self.subject.onNext(element)
  }

  private let subject = PublishSubject<T>()
  private let scheduler = SerialDispatchQueueScheduler(qos: .userInteractive)
  private let disposeBag = DisposeBag()
}
