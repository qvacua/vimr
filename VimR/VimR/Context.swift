/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import os

final class ReduxContext {
  let actionEmitter = ActionEmitter()

  private(set) var state: ReduxTypes.StateType
  private var subscribers: [UUID: (ReduxTypes.StateType) -> Void] = [:]
  private let logger = Logger(
    subsystem: Defs.loggerSubsystem,
    category: Defs.LoggerCategory.redux
  )

  init(baseServerUrl url: URL, state: AppState) {
    self.state = state

    self.setupRedux(baseServerUrl: url)
  }

  // The following should only be used when Cmd-Q'ing
  func savePrefs() {
    if let curMainWindow = self.state.currentMainWindow {
      self.state.mainWindowTemplate = curMainWindow
    }

    self.prefMiddleware.applyPref(from: self.state)
  }

  func setupRedux(baseServerUrl: URL) {
    let uiRootReducer = UiRootReducer()
    let openQuicklyReducer = OpenQuicklyReducer()

    let appStateReduce = { tuple in
      [
        AppDelegateReducer(baseServerUrl: baseServerUrl).reduce,
        uiRootReducer.mainWindow.reduce,
        openQuicklyReducer.mainWindow.reduce,
        openQuicklyReducer.reduce,
        uiRootReducer.reduce,

        // Preferences
        PrefWindowReducer().reduce,
        GeneralPrefReducer().reduce,
        ToolsPrefReducer().reduce,
        AppearancePrefReducer().reduce,
        AdvancedPrefReducer().reduce,
        KeysPrefReducer().reduce,
      ].reduce(tuple) { result, reduceBody in reduceBody(result) }
    }

    let appStateMiddlewareApply = [
      self.prefMiddleware.mainWindow.apply,
      self.prefMiddleware.apply,
    ].reversed().reduce(appStateReduce) { result, middleware in
      middleware(result)
    }

    let markdownPreviewMiddleware = MarkdownPreviewMiddleware()
    let markdownPreviewReducer = MarkdownPreviewReducer(baseServerUrl: baseServerUrl)
    let htmlPreviewReducer = HtmlPreviewReducer(baseServerUrl: baseServerUrl)
    let httpMiddleware = HttpServerMiddleware(port: baseServerUrl.port!)

    let mainWinReduce = { tuple in
      [
        MainWindowReducer().reduce,
        markdownPreviewReducer.mainWindow.reduce,
        markdownPreviewReducer.previewTool.reduce,
        MarkdownToolReducer(baseServerUrl: baseServerUrl).reduce,
        htmlPreviewReducer.mainWindow.reduce,
        htmlPreviewReducer.htmlPreview.reduce,
        FileBrowserReducer().reduce,
        BuffersListReducer().reduce,
        markdownPreviewReducer.buffersList.reduce,
      ].reduce(tuple) { result, reduceBody in reduceBody(result) }
    }

    let mainWinMiddlwareApply = [
      markdownPreviewMiddleware.mainWindow.apply,
      httpMiddleware.markdownPreview.apply,
      markdownPreviewMiddleware.markdownTool.apply,
      HtmlPreviewMiddleware().apply,
      httpMiddleware.htmlPreviewMainWindow.apply,
      httpMiddleware.htmlPreviewTool.apply,
    ].reversed().reduce(mainWinReduce) { result, middleware in
      middleware(result)
    }

    self.actionEmitter.subscribe { action in
      var modified = false

      let tuple = ReduceTuple(state: self.state, action: action, modified: false)

      self.logger.debugAny("AppState Redux tuple before reducing: \(tuple)")
      let result = appStateMiddlewareApply(tuple)
      self.logger.debugAny("AppState Redux tuple after AppState reduce: \(tuple)")

      if result.modified {
        self.state = result.state
        modified = true
      } else {
        self.logger.debugAny("AppState not mofified")
      }

      if let uuidAction = action as? UuidTagged,
         let mainWindowState = self.state.mainWindows[uuidAction.uuid]
      {
        let tuple = ReduceTuple(state: mainWindowState, action: action, modified: false)

        self.logger.debugAny("MainWin \(uuidAction.uuid) Redux tuple before reducing: \(tuple)")
        let result = mainWinMiddlwareApply(tuple)
        self.logger.debugAny("MainWin \(uuidAction.uuid) Redux tuple after reduce: \(tuple)")

        if result.modified {
          self.state.mainWindows[uuidAction.uuid] = result.state
          modified = true
        } else {
          self.logger.debugAny("MainWin \(uuidAction.uuid) state not mofified")
        }
      }

      guard modified else {
        self.logger.debugAny("No need to notify subscribers")
        return
      }

      for subscriber in self.subscribers.values {
        subscriber(self.state)
      }

      self.cleanUpAppState()
    }
  }

  deinit {
    self.subscribers.removeAll()
  }

  func subscribe(uuid: UUID, subscription: @escaping (ReduxTypes.StateType) -> Void) {
    self.subscribers[uuid] = subscription
  }

  func unsubscribe(uuid: UUID) {
    self.subscribers[uuid] = nil
  }

  private let prefMiddleware = PrefMiddleware()

  private func cleanUpAppState() {
    for uuid in self.state.mainWindows.keys {
      self.state.mainWindows[uuid]?.cwdToSet = nil
      self.state.mainWindows[uuid]?.currentBufferToSet = nil
      self.state.mainWindows[uuid]?.viewToBeFocused = nil
      self.state.mainWindows[uuid]?.urlsToOpen.removeAll()
    }
  }
}
