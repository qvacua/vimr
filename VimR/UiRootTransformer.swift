//
// Created by Tae Won Ha on 1/17/17.
// Copyright (c) 2017 Tae Won Ha. All rights reserved.
//

import Foundation
import RxSwift

class UiRootTransformer: Transformer {

  typealias Pair = StateActionPair<MainWindowStates, UuidAction<MainWindow.Action>>

  func transform(_ source: Observable<Pair>) -> Observable<Pair> {
    return source.map { pair in
      var state = pair.state
      let uuid = pair.action.uuid

      switch pair.action.payload {

      case .becomeKey:
        state.last = state.current[uuid] ?? state.last

      case .close:
        state.current.removeValue(forKey: uuid)

      default:
        break

      }

      return StateActionPair(state: state, action: pair.action)
    }
  }
}
