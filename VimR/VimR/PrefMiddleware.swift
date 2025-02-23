/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
@preconcurrency import DictionaryCoding
import os
import UserNotifications

final class PrefMiddleware: MiddlewareType {
  typealias StateType = AppState
  typealias ActionType = AnyAction

  static let compatibleVersion = "168"

  let mainWindow = MainWindowMiddleware()

  // The following should only be used when Cmd-Q'ing
  func applyPref(from appState: AppState) {
    do {
      let dictionary: [String: Any] = try dictEncoder.encode(appState)
      defaults.set(dictionary, forKey: PrefMiddleware.compatibleVersion)
      defaults.synchronize()
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

        let newFontNameText = if let newFontName = newFont.displayName {
          ", \(newFontName),"
        } else {
          ""
        }

        if !traits.contains(.monoSpace) {
          let content = UNMutableNotificationContent()
          content.title = "No monospaced font"
          content.body = "The font you selected\(newFontNameText) does not seem "
            + "to be a monospaced font. The rendering will most likely be broken."
          content.sound = .default

          let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
          )

          UNUserNotificationCenter.current().add(request)
        }
      }

      do {
        let dictionary: [String: Any] = try dictEncoder.encode(result.state)
        defaults.set(dictionary, forKey: PrefMiddleware.compatibleVersion)
        defaults.synchronize()
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
          defaults.synchronize()
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

// UserDefaults is thread-safe
// https://developer.apple.com/documentation/foundation/userdefaults#2926903
private nonisolated(unsafe) let defaults = UserDefaults.standard
private let dictEncoder = DictionaryEncoder()
