/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import RxSwift

typealias ActionEmitter = Emitter<Any>

class Emitter<T> {

  let observable: Observable<T>

  init() {
    self.observable = self.subject.asObservable().observeOn(scheduler)
  }

  func emit(_ action: T) {
    self.subject.onNext(action)
  }

  deinit {
    self.subject.onCompleted()
  }

  fileprivate let scheduler = SerialDispatchQueueScheduler(qos: .userInitiated)
  fileprivate let subject = PublishSubject<T>()
}

class StateActionPair<S, A> {

  let modified: Bool
  let state: S
  let action: A

  init(state: S, action: A, modified: Bool = true) {
    self.modified = modified
    self.state = state
    self.action = action
  }
}

class UuidAction<A>: CustomStringConvertible {

  let uuid: String
  let payload: A

  var description: String {
    return "UuidAction(uuid: \(uuid), payload: \(String(reflecting: payload)))"
  }

  init(uuid: String, action: A) {
    self.uuid = uuid
    self.payload = action
  }
}

class UuidState<S>: CustomStringConvertible {

  let uuid: String
  let payload: S

  var description: String {
    return "UuidState(uuid: \(uuid), payload: \(String(reflecting: payload)))"
  }

  init(uuid: String, state: S) {
    self.uuid = uuid
    self.payload = state
  }
}

class Marked<T>: CustomStringConvertible {

  let mark: Token
  let payload: T

  var description: String {
    return "Marked<\(mark) -> \(self.payload)>"
  }

  convenience init(_ payload: T) {
    self.init(mark: Token(), payload: payload)
  }

  init(mark: Token, payload: T) {
    self.mark = mark
    self.payload = payload
  }

  func hasDifferentMark(as other: Marked<T>) -> Bool {
    return self.mark != other.mark
  }
}

protocol Reducer {

  associatedtype Pair

  func reduce(_ source: Observable<Pair>) -> Observable<Pair>
}

protocol Service {

  associatedtype Pair

  func apply(_: Pair)
}

protocol StateService {

  associatedtype StateType

  func apply(_: StateType)
}

protocol UiComponent {

  associatedtype StateType

  init(source: Observable<StateType>, emitter: ActionEmitter, state: StateType)
}
