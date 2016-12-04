/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import RxSwift
import PureLayout

protocol Flow: class {

  var sink: Observable<Any> { get }
}

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

class EmbeddableComponent: Flow {

  var sink: Observable<Any> {
    return self.subject.asObservable()
  }

  fileprivate let subject = PublishSubject<Any>()
  fileprivate let source: Observable<Any>
  fileprivate let disposeBag = DisposeBag()

  init(source: Observable<Any>) {
    self.source = source
  }

  deinit {
    self.subject.onCompleted()
  }

  func set(subscription: ((Observable<Any>) -> Disposable)) {
    subscription(source).addDisposableTo(self.disposeBag)
  }

  func publish(event: Any) {
    self.subject.onNext(event)
  }
}

class StandardComponent: NSObject, Flow {

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

class ViewComponent: NSView, Flow {

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
    self.configureForAutoLayout()

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

class WorkspaceToolComponent: WorkspaceTool, Flow {

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  let toolIdentifier: ToolIdentifier
  let viewComponent: ViewComponent
  var sink: Observable<Any> {
    return self.viewComponent.sink
  }

  var toolDataDict: [String: Any] {
    guard let toolDataHolder = self.viewComponent as? ToolDataHolder else {
      return [:]
    }

    return toolDataHolder.toolDataDict
  }

  init(toolIdentifier: ToolIdentifier, config: WorkspaceTool.Config) {
    guard let viewComponent = config.view as? ViewComponent else {
      preconditionFailure("ERROR view must be a ViewComponent!")
    }

    self.toolIdentifier = toolIdentifier
    self.viewComponent = viewComponent

    super.init(config)
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
