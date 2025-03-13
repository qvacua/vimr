/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import os

enum ReduxTypes {
  typealias StateType = AppState
  typealias ActionType = Sendable

  typealias ReduceFunction = (ReduceTuple<StateType, ActionType>) -> ReduceTuple<
    StateType,
    ActionType
  >
}

struct ReduceTuple<State, Action> {
  var state: State
  let action: Action
  var modified: Bool
}

final class ActionEmitter {
  typealias ActionSubscription = (ReduxTypes.ActionType) -> Void

  private var subscribers = [ActionSubscription]()
  private let logger = Logger(subsystem: Defs.loggerSubsystem, category: Defs.LoggerCategory.redux)

  @MainActor
  func typedEmit<T: ReduxTypes.ActionType>() -> (T) -> Void {
    { [weak self] action in
      self?.logger.debugAny("Action emitted: \(action)")
      Task { @MainActor in
        self?.subscribers.forEach { $0(action) }
      }
    }
  }

  @MainActor
  func emit(_ action: ReduxTypes.ActionType) {
    Task {
      self.subscribers.forEach { $0(action) }
    }
    self.logger.debugAny("Action emitted: \(action)")
  }

  func subscribe(_ subscription: @escaping ActionSubscription) {
    self.subscribers.append(subscription)
  }
}

protocol ReducerType {
  associatedtype StateType
  associatedtype ActionType: Sendable

  typealias TypedReduceTuple = ReduceTuple<StateType, ActionType>
  typealias ActionTypeErasedReduceTuple = ReduceTuple<StateType, ReduxTypes.ActionType>

  func typedReduce(_ tuple: TypedReduceTuple) -> TypedReduceTuple
}

extension ReducerType {
  func reduce(_ tuple: ActionTypeErasedReduceTuple) -> ActionTypeErasedReduceTuple {
    guard let typedAction = tuple.action as? ActionType else { return tuple }

    let typedResult = self.typedReduce(TypedReduceTuple(
      state: tuple.state, action: typedAction, modified: tuple.modified
    ))

    return .init(
      state: typedResult.state, action: typedResult.action, modified: typedResult.modified
    )
  }
}

protocol MiddlewareType {
  associatedtype StateType
  associatedtype ActionType: Sendable

  typealias TypedReduceTuple = ReduceTuple<StateType, ActionType>
  typealias ActionTypeErasedReduceTuple = ReduceTuple<StateType, ReduxTypes.ActionType>

  typealias TypedActionReduceFunction = (TypedReduceTuple) -> ActionTypeErasedReduceTuple
  typealias ActionTypeErasedReduceFunction = (ActionTypeErasedReduceTuple)
    -> ActionTypeErasedReduceTuple

  func typedApply(_ reduce: @escaping TypedActionReduceFunction) -> TypedActionReduceFunction
}

extension MiddlewareType {
  func apply(_ reduce: @escaping ActionTypeErasedReduceFunction) -> ActionTypeErasedReduceFunction {
    { tuple in
      guard let typedAction = tuple.action as? ActionType else { return reduce(tuple) }

      let typedTuple = TypedReduceTuple(
        state: tuple.state, action: typedAction, modified: tuple.modified
      )

      let typedReduce: (TypedReduceTuple) -> ActionTypeErasedReduceTuple = { typedTuple in
        reduce(.init(
          state: typedTuple.state,
          action: typedTuple.action,
          modified: typedTuple.modified
        ))
      }

      return self.typedApply(typedReduce)(typedTuple)
    }
  }
}

@MainActor
protocol UiComponent {
  associatedtype StateType

  var uuid: UUID { get }

  init(context: ReduxContext, emitter: ActionEmitter, state: StateType)
}
