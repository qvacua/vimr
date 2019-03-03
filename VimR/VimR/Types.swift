/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import RxSwift

struct StateActionPair<S, A> {

  var state: S
  var action: A
  var modified: Bool
}

protocol UuidTagged {

  var uuid: UUID { get }
}

class UuidAction<A>: UuidTagged, CustomStringConvertible {

  let uuid: UUID
  let payload: A

  var description: String {
    return "UuidAction(uuid: \(uuid), payload: \(String(reflecting: payload)))"
  }

  init(uuid: UUID, action: A) {
    self.uuid = uuid
    self.payload = action
  }
}

class UuidState<S>: UuidTagged, CustomStringConvertible {

  let uuid: UUID
  let payload: S

  var description: String {
    return "UuidState(uuid: \(uuid), payload: \(String(reflecting: payload)))"
  }

  init(uuid: UUID, state: S) {
    self.uuid = uuid
    self.payload = state
  }
}

class Token: Hashable, CustomStringConvertible {

  var hashValue: Int {
    return ObjectIdentifier(self).hashValue
  }

  var description: String {
    return ObjectIdentifier(self).debugDescription
  }

  static func == (left: Token, right: Token) -> Bool {
    return left === right
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

class UiComponentTemplate: UiComponent {

  typealias StateType = State

  struct State {

    var someField: String
  }

  enum Action {

    case doSth
  }

  required init(source: Observable<StateType>, emitter: ActionEmitter, state: StateType) {
    // set the typed action emit function
    self.emit = emitter.typedEmit()

    // init the component with the initial state "state"
    self.someField = state.someField

    // react to the new state
    source
      .observeOn(MainScheduler.instance)
      .subscribe(
        onNext: { [unowned self] state in
          print("Hello, \(self.someField)")
        }
      )
      .disposed(by: self.disposeBag)
  }

  func someAction() {
    // when the user does something, emit an action
    self.emit(.doSth)
  }

  private let emit: (Action) -> Void
  private let disposeBag = DisposeBag()

  private let someField: String
}
