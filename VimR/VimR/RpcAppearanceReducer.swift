/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa

final class RpcAppearanceReducer: ReducerType {
  typealias StateType = AppState
  typealias ActionType = UuidAction<MainWindow.Action>

  func typedReduce(_ tuple: TypedReduceTuple) -> TypedReduceTuple {
    var state = tuple.state
    var modified = tuple.modified

    switch tuple.action.payload {
    case let .setFont(font):
      state.mainWindowTemplate.appearance.font = font
      modified = true

    case let .setLinespacing(linespacing):
      state.mainWindowTemplate.appearance.linespacing = linespacing
      modified = true

    case let .setCharacterspacing(characterspacing):
      state.mainWindowTemplate.appearance.characterspacing = characterspacing
      modified = true

    default:
      break
    }

    if modified {
      for key in state.mainWindows.keys {
        state.mainWindows[key]?.appearance = state.mainWindowTemplate.appearance
      }
      return TypedReduceTuple(state: state, action: tuple.action, modified: true)
    } else {
      return tuple
    }
  }
}
