/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import RxSwift

protocol Flow {

  var sink: Observable<Any> { get }
}

protocol Store: Flow {}

protocol Component: Flow {}

class StandardFlow: Flow {

  var sink: Observable<Any> {
    return self.subject.asObservable()
  }

  let subject = PublishSubject<Any>()
  let source: Observable<Any>
  let disposeBag = DisposeBag()

  init(source: Observable<Any>) {
    self.source = source
    self.subscription(source: source).addDisposableTo(self.disposeBag)
  }

  deinit {
    self.subject.onCompleted()
  }

  func subscription(source source: Observable<Any>) -> Disposable {
    preconditionFailure("Please override")
  }

  func publish(event event: Any) {
    self.subject.onNext(event)
  }
}

class StandardComponent: NSObject, Component {

  var sink: Observable<Any> {
    return self.subject.asObservable()
  }

  let subject = PublishSubject<Any>()
  let source: Observable<Any>
  let disposeBag = DisposeBag()

  init(source: Observable<Any>) {
    self.source = source
    super.init()

    self.addViews()
    self.subscription(source: source).addDisposableTo(self.disposeBag)
  }

  deinit {
    self.subject.onCompleted()
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

class WindowComponent: StandardComponent {

  let windowController: NSWindowController
  var window: NSWindow {
    return self.windowController.window!
  }

  init(source: Observable<Any>, nibName: String) {
    self.windowController = NSWindowController(windowNibName: nibName)
    super.init(source: source)
  }

  func show() {
    self.windowController.showWindow(self)
  }
}
