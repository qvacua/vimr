/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import RxSwift

extension Observable {
  func completableSubject() -> CompletableSubject<Element> { CompletableSubject(source: self) }
}

class CompletableSubject<T> {
  func asObservable() -> Observable<T> { self.subject.asObservable() }

  init(source: Observable<T>) {
    let subject = PublishSubject<T>()
    self.subscription = source.subscribe(onNext: { element in subject.onNext(element) })
    self.subject = subject
  }

  func onCompleted() {
    self.subject.onCompleted()
    self.subscription.dispose()
  }

  private let subject: PublishSubject<T>
  private let subscription: Disposable
}
