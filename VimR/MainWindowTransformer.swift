//
// Created by Tae Won Ha on 1/17/17.
// Copyright (c) 2017 Tae Won Ha. All rights reserved.
//

import Foundation
import RxSwift

class MainWindowTransformer: Transformer {

  typealias Pair = StateActionPair<UuidState<MainWindow.State>, MainWindow.Action>

  func transform(_ source: Observable<Pair>) -> Observable<Pair> {
    return source.map { pair in
      var state = pair.state.payload

      switch pair.action {

      case let .cd(to: cwd):
        if state.cwd != cwd {
          state.cwd = cwd
        }

      case let .setBufferList(buffers):
        buffers
          .flatMap { $0.url }
          .forEach { state.urlsToOpen.removeValue(forKey: $0) }
        state.buffers = buffers

      default:
        break

      }

      return StateActionPair(state: UuidState(uuid: state.uuid, state: state), action: pair.action)
    }
  }
}
