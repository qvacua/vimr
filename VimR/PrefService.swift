/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import Swifter
import RxSwift

fileprivate let lastCompatibleVersion = "128"

fileprivate let defaults = UserDefaults.standard

class PrefService: Service {

  typealias Element = StateActionPair<AppState, UuidAction<MainWindow.Action>>

  static let compatibleVersion = "200" // yet dummy

  func apply(_ pair: Element) {
    guard case .close = pair.action.payload else {
      return
    }

    NSLog("saving pref!")
    defaults.setValue(pair.state.dict(), forKey: PrefService.compatibleVersion)
  }
}
