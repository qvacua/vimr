/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

class RpcAppearanceEpic: EpicType {

  typealias StateType = AppState
  typealias ActionType = UuidAction<MainWindow.Action>
  typealias EmitActionType = AppearancePref.Action

  required init(emitter: ActionEmitter) {
    self.emit = emitter.typedEmit()
  }

  func typedApply(
    _ reduce: @escaping TypedActionReduceFunction
  ) -> TypedActionReduceFunction {
    return { tuple in
      let result = reduce(tuple)

      switch tuple.action.payload {

      case .setFont(let font):
        self.emit(.setFont(font))

      case .setLinespacing(let linespacing):
        self.emit(.setLinespacing(linespacing))

      default:
        break

      }

      return result
    }
  }

  private let emit: (EmitActionType) -> Void
}
