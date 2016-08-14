/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import RxSwift

class PrefPane: NSView, ViewComponent {

  private let source: Observable<Any>
  private let disposeBag = DisposeBag()

  private let subject = PublishSubject<Any>()
  var sink: Observable<Any> {
    return self.subject.asObservable()
  }

  var view: NSView {
    return self
  }

  // Return true to place this to the upper left corner when the scroll view is bigger than this view.
  override var flipped: Bool {
    return true
  }

  init(source: Observable<Any>) {
    self.source = source

    super.init(frame: CGRect.zero)
    self.translatesAutoresizingMaskIntoConstraints = false
    self.wantsLayer = true
    self.layer?.backgroundColor = NSColor.magentaColor().CGColor

    self.addViews()
    self.subscription(source: self.source).addDisposableTo(self.disposeBag)
  }

  deinit {
    self.subject.onCompleted()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func addViews() {
    preconditionFailure("Please override")
  }

  func subscription(source source: Observable<Any>) -> Disposable {
    preconditionFailure("Please override")
  }
  
  func publish(event event: Any) {
    self.subject.onNext(event)
  }
}
