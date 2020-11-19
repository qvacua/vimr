/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import DictionaryCoding
import os

class PrefMiddleware: MiddlewareType {
  typealias StateType = AppState
  typealias ActionType = AnyAction

  static let compatibleVersion = "168"

  let mainWindow = MainWindowMiddleware()

  // The following should only be used when Cmd-Q'ing
  func applyPref(from appState: AppState) {
    do {
      let dictionary: [String: Any] = try dictEncoder.encode(appState)
      defaults.set(dictionary, forKey: PrefMiddleware.compatibleVersion)
    } catch {
      self.log.error("AppState could not converted to Dictionary: \(error)")
    }
  }

  func typedApply(_ reduce: @escaping TypedActionReduceFunction) -> TypedActionReduceFunction {
    { tuple in
      let result = reduce(tuple)

      guard result.modified else {
        return result
      }

      let newFont = result.state.mainWindowTemplate.appearance.font
      let traits = newFont.fontDescriptor.symbolicTraits

      if newFont != self.currentFont {
        self.currentFont = newFont

        let newFontNameText: String
        if let newFontName = newFont.displayName {
          newFontNameText = ", \(newFontName),"
        } else {
          newFontNameText = ""
        }

        if !traits.contains(.monoSpace) {
          let notification = NSUserNotification()
          notification.identifier = UUID().uuidString
          notification.title = "No monospaced font"
          notification.informativeText = "The font you selected\(newFontNameText) does not seem "
            + "to be a monospaced font. The rendering will most likely be broken."
          NSUserNotificationCenter.default.deliver(notification)
        }
      }

      do {
        let dictionary: [String: Any] = try dictEncoder.encode(result.state)
        defaults.set(dictionary, forKey: PrefMiddleware.compatibleVersion)
      } catch {
        self.log.error("AppState could not converted to Dictionary: \(error)")
      }

      return result
    }
  }

  private let log = OSLog(subsystem: Defs.loggerSubsystem, category: Defs.LoggerCategory.middleware)

  private var currentFont = NSFont.userFixedPitchFont(ofSize: 13)!

  class MainWindowMiddleware: MiddlewareType {
    typealias StateType = AppState
    typealias ActionType = UuidAction<MainWindow.Action>

    func typedApply(_ reduce: @escaping TypedActionReduceFunction) -> TypedActionReduceFunction {
      { tuple in
        let result = reduce(tuple)

        guard case .close = tuple.action.payload else {
          return result
        }

        do {
          let dictionary: [String: Any] = try dictEncoder.encode(result.state)
          defaults.set(dictionary, forKey: PrefMiddleware.compatibleVersion)
        } catch {
          self.log.error("AppState could not converted to Dictionary: \(error)")
        }

        return result
      }
    }

    private let log = OSLog(
      subsystem: Defs.loggerSubsystem,
      category: Defs.LoggerCategory.middleware
    )
  }
}

private let defaults = UserDefaults.standard
private let dictEncoder = DictionaryEncoder()
