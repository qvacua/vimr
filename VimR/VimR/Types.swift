/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import UserNotifications

extension NSColor: @retroactive @unchecked Sendable {}
extension NSFont: @retroactive @unchecked Sendable {}
extension NSImage: @retroactive @unchecked Sendable {}
extension UNNotification: @retroactive @unchecked Sendable {}

// UNUserNotificationCenter is thread-safe
// https://developer.apple.com/documentation/usernotifications/unusernotificationcenter#overview
extension UNUserNotificationCenter: @retroactive @unchecked Sendable {}

struct StateActionPair<S, A> {
  var state: S
  var action: A
  var modified: Bool
}

protocol UuidTagged {
  var uuid: UUID { get }
}

final class UuidAction<A: Sendable>: UuidTagged, CustomStringConvertible, Sendable {
  let uuid: UUID
  let payload: A

  var description: String {
    "UuidAction(uuid: \(self.uuid), payload: \(String(reflecting: self.payload)))"
  }

  init(uuid: UUID, action: A) {
    self.uuid = uuid
    self.payload = action
  }
}

final class UuidState<S>: UuidTagged, CustomStringConvertible {
  let uuid: UUID
  let payload: S

  var description: String {
    "UuidState(uuid: \(self.uuid), payload: \(String(reflecting: self.payload)))"
  }

  init(uuid: UUID, state: S) {
    self.uuid = uuid
    self.payload = state
  }
}

final class Token: Hashable, CustomStringConvertible, Sendable {
  func hash(into hasher: inout Hasher) {
    hasher.combine(ObjectIdentifier(self))
  }

  var description: String {
    ObjectIdentifier(self).debugDescription
  }

  static func == (left: Token, right: Token) -> Bool {
    left === right
  }
}

final class Marked<T: Sendable>: CustomStringConvertible, Sendable {
  let mark: Token
  let payload: T

  var description: String {
    "Marked<\(self.mark) -> \(self.payload)>"
  }

  init(_ payload: T) {
    self.mark = Token()
    self.payload = payload
  }

  init(mark: Token, payload: T) {
    self.mark = mark
    self.payload = payload
  }

  func hasDifferentMark(as other: Marked<T>) -> Bool {
    self.mark != other.mark
  }
}

final class UiComponentTemplate: UiComponent {
  typealias StateType = State

  struct State {
    var someField: String
  }

  enum Action {
    case doSth
  }

  let uuid = UUID()

  required init(context: ReduxContext, state: StateType) {
    self.context = context

    // set the typed action emit function
    self.emit = context.actionEmitter.typedEmit()

    // init the component with the initial state "state"
    self.someField = state.someField

    // react to the new state
    context.subscribe(uuid: self.uuid) { state in
      Swift.print(state)
    }
  }

  func cleanup() {
    self.context.unsubscribe(uuid: self.uuid)
  }

  func someAction() {
    // when the user does something, emit an action
    self.emit(.doSth)
  }

  private let context: ReduxContext
  private let emit: (Action) -> Void

  private let someField: String
}
