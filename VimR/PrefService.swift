/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import Swifter
import RxSwift

fileprivate let defaults = UserDefaults.standard

class PrefService: Service {

  typealias Pair = StateActionPair<AppState, UuidAction<MainWindow.Action>>

  static let compatibleVersion = "168"
  static let lastCompatibleVersion = "128"

  func apply(_ pair: Pair) {
    guard case .close = pair.action.payload else {
      return
    }

    NSLog("Saving pref!")
    defaults.setValue(pair.state.dict(), forKey: PrefService.compatibleVersion)
  }
}
