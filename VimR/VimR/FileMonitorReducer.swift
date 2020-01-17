/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

class FileMonitorReducer: ReducerType {

  typealias StateType = AppState
  typealias ActionType = FileMonitor.Action

  func typedReduce(_ tuple: ReduceTuple) -> ReduceTuple {
    var state = tuple.state

    switch tuple.action {

    case let .change(in: url):
      state.mainWindows
        .filter { (uuid, mainWindow) in url == mainWindow.cwd || url.isContained(in: mainWindow.cwd) }
        .map { $0.0 }
        .forEach { uuid in
          state.mainWindows[uuid]?.lastFileSystemUpdate = Marked(url)
        }

    }

    return (state, tuple.action, true)
  }
}
