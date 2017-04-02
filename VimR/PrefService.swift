/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import Swifter
import RxSwift

fileprivate let defaults = UserDefaults.standard

class PrefService {

  static let compatibleVersion = "168"
  static let lastCompatibleVersion = "128"

  let forMainWindow = PrefMainWindowService()
  let forPrefPanes = PrefPaneService()
}

extension PrefService {

  class PrefMainWindowService: Service {

    typealias Pair = StateActionPair<AppState, UuidAction<MainWindow.Action>>

    func apply(_ pair: Pair) {
      guard case .close = pair.action.payload else {
        return
      }

      NSLog("Saving pref!")
      defaults.setValue(pair.state.dict(), forKey: PrefService.compatibleVersion)
    }
  }

  class PrefPaneService: StateService {

    typealias StateType = AppState

    func apply(_ state: StateType) {
      NSLog("Saving pref!")
      defaults.setValue(state.dict(), forKey: PrefService.compatibleVersion)
    }
  }
}