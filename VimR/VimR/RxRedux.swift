/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import RxSwift

protocol ReduxContextType {

  /**
   Type that holds the global app state

   - Important:
   This type must be typealias'ed in `ReduxTypes` or in an extension thereof.
   */
  associatedtype StateType

  /**
   "The greatest common divisor" for all actions used in the app: Assuming it is set to `ReduxTypes.ActionType` type,
   the following must be true for any action
   ```
   assert(someAction is ReduxTypes.ActionType) // which means
   let actionWithMinimumType: ReduxTypes.ActionType = anyAction
   ```
   Most probably this type will be set to `Any`.

   - Important:
   This type must be typealias'ed in `ReduxTypes` or in an extension thereof.
   */
  associatedtype ActionType

  typealias ReduceTuple = (state: StateType, action: ActionType, modified: Bool)
  typealias ReduceFunction = (ReduceTuple) -> ReduceTuple
}

/**
 `typealias` `StateType` and `ActionType` either within the class definition or in an extension.
 */
class ReduxTypes: ReduxContextType {
}

protocol ReducerType {

  associatedtype StateType
  associatedtype ActionType

  typealias ReduceTuple = (state: StateType, action: ActionType, modified: Bool)
  typealias ActionTypeErasedReduceTuple = (state: StateType, action: ReduxTypes.ActionType, modified: Bool)

  func typedReduce(_ tuple: ReduceTuple) -> ReduceTuple
}

extension ReducerType {

  func reduce(_ tuple: ActionTypeErasedReduceTuple) -> ActionTypeErasedReduceTuple {
    guard let typedTuple = tuple as? ReduceTuple else {
      return tuple
    }

    let typedResult = self.typedReduce(typedTuple)
    return (state: typedResult.state, action: typedResult.action, modified: typedResult.modified)
  }
}

protocol MiddlewareType {

  associatedtype StateType
  associatedtype ActionType

  typealias ReduceTuple = (state: StateType, action: ActionType, modified: Bool)
  typealias ActionTypeErasedReduceTuple = (state: StateType, action: ReduxTypes.ActionType, modified: Bool)

  typealias TypedActionReduceFunction = (ReduceTuple) -> ActionTypeErasedReduceTuple
  typealias ActionTypeErasedReduceFunction = (ActionTypeErasedReduceTuple) -> ActionTypeErasedReduceTuple

  func typedApply(_ reduce: @escaping TypedActionReduceFunction) -> TypedActionReduceFunction
}

extension MiddlewareType {

  func apply(_ reduce: @escaping ActionTypeErasedReduceFunction) -> ActionTypeErasedReduceFunction {
    return { tuple in
      guard let typedTuple = tuple as? ReduceTuple else {
        return reduce(tuple)
      }

      let typedReduce: (ReduceTuple) -> ActionTypeErasedReduceTuple = { typedTuple in
        // We know that we can cast the typed action to ReduxTypes.ActionType
        return reduce((state: typedTuple.state, action: typedTuple.action, modified: typedTuple.modified))
      }

      return self.typedApply(typedReduce)(typedTuple)
    }
  }
}

protocol UiComponent {

  associatedtype StateType

  init(source: Observable<StateType>, emitter: ActionEmitter, state: StateType)
}

class ActionEmitter {

  let observable: Observable<ReduxTypes.ActionType>

  init() {
    self.observable = self.subject.asObservable().observeOn(scheduler)
  }

  func typedEmit<T>() -> ((T) -> Void) {
    return { (action: T) in
      self.subject.onNext(action)
    }
  }

  func terminate() {
    self.subject.onCompleted()
  }

  deinit {
    self.subject.onCompleted()
  }

  private let scheduler = SerialDispatchQueueScheduler(qos: .userInteractive)
  private let subject = PublishSubject<ReduxTypes.ActionType>()
}

class ReduxContext {

  let actionEmitter = ActionEmitter()
  let stateSource: Observable<ReduxTypes.StateType>

  convenience init(initialState: ReduxTypes.StateType,
                   reducers: [ReduxTypes.ReduceFunction],
                   middlewares: [(@escaping ReduxTypes.ReduceFunction) -> ReduxTypes.ReduceFunction] = []) {

    self.init(initialState: initialState)

    self.actionEmitter.observable
      .map { (state: self.state, action: $0, modified: false) }
      .reduce(by: reducers, middlewares: middlewares)
      .filter { $0.modified }
      .subscribe(onNext: { tuple in
        self.state = tuple.state
        self.stateSubject.onNext(tuple.state)
      })
      .disposed(by: self.disposeBag)
  }

  init(initialState: ReduxTypes.StateType) {
    self.state = initialState
    self.stateSource = self.stateSubject.asObservable().observeOn(self.stateScheduler)
  }

  func terminate() {
    self.actionEmitter.terminate()
    self.stateSubject.onCompleted()
  }

  var state: ReduxTypes.StateType

  let stateSubject = PublishSubject<ReduxTypes.StateType>()
  let stateScheduler = SerialDispatchQueueScheduler(qos: .userInteractive)

  let disposeBag = DisposeBag()
}

extension Observable {

  func completableSubject() -> CompletableSubject<Element> {
    return CompletableSubject(source: self)
  }
}

class CompletableSubject<T> {

  func asObservable() -> Observable<T> {
    return self.subject.asObservable()
  }

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

extension Observable {

  func reduce(
    by reducers: [(Element) -> Element],
    middlewares: [(@escaping (Element) -> Element) -> (Element) -> Element]
  ) -> Observable<Element> {

    let dispatch = { pair in
      return reducers.reduce(pair) { result, reduceBody in
        return reduceBody(result)
      }
    }

    let next = middlewares.reversed().reduce(dispatch) { result, middleware in middleware(result) }
    return self.map(next)
  }
}
