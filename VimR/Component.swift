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

class PublishingFlow: Flow {

  var sink: Observable<Any> {
    return self.subject.asObservable()
  }

  let subject = PublishSubject<Any>()

  init() {
    
  }

  deinit {
    self.subject.onCompleted()
  }

  func publish(event: Any) {
    self.subject.onNext(event)
  }
}

class StandardFlow: PublishingFlow {

  let source: Observable<Any>
  let disposeBag = DisposeBag()

  init(source: Observable<Any>) {
    self.source = source
    super.init()
    
    self.subscription(source: source).addDisposableTo(self.disposeBag)
  }

  deinit {
    self.subject.onCompleted()
  }

  func subscription(source: Observable<Any>) -> Disposable {
    preconditionFailure("Please override")
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

  func subscription(source: Observable<Any>) -> Disposable {
    preconditionFailure("Please override")
  }

  func publish(event: Any) {
    self.subject.onNext(event)
  }
}

class ViewComponent: NSView, Component {

  var view: NSView {
    preconditionFailure("Please override")
  }

  var sink: Observable<Any> {
    return self.subject.asObservable()
  }

  let subject = PublishSubject<Any>()
  let source: Observable<Any>
  let disposeBag = DisposeBag()

  init(source: Observable<Any>) {
    self.source = source

    super.init(frame: CGRect.zero)
    self.translatesAutoresizingMaskIntoConstraints = false

    self.addViews()
    self.subscription(source: source).addDisposableTo(self.disposeBag)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  deinit {
    self.subject.onCompleted()
  }

  func addViews() {
    preconditionFailure("Please override")
  }

  func subscription(source: Observable<Any>) -> Disposable {
    preconditionFailure("Please override")
  }

  func publish(event: Any) {
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
