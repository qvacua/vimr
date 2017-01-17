//
// Created by Tae Won Ha on 1/16/17.
// Copyright (c) 2017 Tae Won Ha. All rights reserved.
//

import Foundation
import RxSwift

class AppDelegateTransformer: Transformer {

  typealias Pair = StateActionPair<MainWindowStates, AppDelegate.Action>

  func transform(_ source: Observable<Pair>) -> Observable<Pair> {
    return source.map { pair in
      switch pair.action {

      case let .newMainWindow(urls, cwd):
        var state = pair.state

        var mainWindow = state.last
        mainWindow.uuid = UUID().uuidString
        mainWindow.urlsToOpen = urls.toDict { url in MainWindow.OpenMode.default }
        mainWindow.cwd = cwd

        state.current[mainWindow.uuid] = mainWindow

        return StateActionPair(state: state, action: pair.action)

      }
    }
  }
}
