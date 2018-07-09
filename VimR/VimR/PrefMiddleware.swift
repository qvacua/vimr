/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

class PrefMiddleware: MiddlewareType {

  typealias StateType = AppState
  typealias ActionType = AnyAction

  static let compatibleVersion = "168"
  static let lastCompatibleVersion = "128"

  let mainWindow = MainWindowMiddleware()

  // The following should only be used when Cmd-Q'ing
  func applyPref(from appState: AppState) {
    defaults.setValue(appState.dict(), forKey: PrefMiddleware.compatibleVersion)
  }

  func typedApply(_ reduce: @escaping TypedActionReduceFunction) -> TypedActionReduceFunction {
    return { tuple in
      let result = reduce(tuple)

      guard tuple.modified else {
        return result
      }

      defaults.setValue(result.state.dict(), forKey: PrefMiddleware.compatibleVersion)

      return result
    }
  }

  class MainWindowMiddleware: MiddlewareType {

    typealias StateType = AppState
    typealias ActionType = UuidAction<MainWindow.Action>

    func typedApply(_ reduce: @escaping TypedActionReduceFunction) -> TypedActionReduceFunction {
      return { tuple in
        let result = reduce(tuple)

        guard tuple.modified else {
          return result
        }

        let uuidAction = tuple.action
        guard case .close = uuidAction.payload else {
          return result
        }

        defaults.setValue(result.state.dict(), forKey: PrefMiddleware.compatibleVersion)
        return result
      }
    }
  }
}

private let defaults = UserDefaults.standard
