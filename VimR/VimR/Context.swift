/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import RxSwift

typealias AnyAction = Any
extension ReduxTypes {
  typealias StateType = AppState
  typealias ActionType = AnyAction
}

final class Context: ReduxContext {
  // The following should only be used when Cmd-Q'ing
  func savePrefs() { self.prefMiddleware.applyPref(from: self.state) }

  init(baseServerUrl: URL, state: AppState) {
    super.init(initialState: state)

    let markdownPreviewMiddleware = MarkdownPreviewMiddleware()
    let markdownPreviewReducer = MarkdownPreviewReducer(baseServerUrl: baseServerUrl)
    let htmlPreviewReducer = HtmlPreviewReducer(baseServerUrl: baseServerUrl)
    let httpMiddleware = HttpServerMiddleware(port: baseServerUrl.port!)
    let uiRootReducer = UiRootReducer()
    let openQuicklyReducer = OpenQuicklyReducer()
    let rpcEpic = RpcAppearanceEpic(emitter: self.actionEmitter)

    // AppState
    self.actionEmitter.observable
      .map { (state: self.state, action: $0, modified: false) }
      .reduce(
        by: [
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
        ],
        middlewares: [
          self.prefMiddleware.mainWindow.apply,
          self.prefMiddleware.apply,
          rpcEpic.apply,
        ]
      )
      .filter(\.modified)
      .subscribe(onNext: self.emitAppState)
      .disposed(by: self.disposeBag)

    // MainWindow.State
    self.actionEmitter.observable
      .compactMap { action in
        guard let uuidAction = action as? UuidTagged else { return nil }

        guard let mainWindowState = self.state.mainWindows[uuidAction.uuid] else { return nil }

        return (mainWindowState, action, false)
      }
      .reduce(
        by: [
          MainWindowReducer().reduce,
          markdownPreviewReducer.mainWindow.reduce,
          markdownPreviewReducer.previewTool.reduce,
          MarkdownToolReducer(baseServerUrl: baseServerUrl).reduce,
          htmlPreviewReducer.mainWindow.reduce,
          htmlPreviewReducer.htmlPreview.reduce,
          FileBrowserReducer().reduce,
          BuffersListReducer().reduce,
          markdownPreviewReducer.buffersList.reduce,
        ],
        middlewares: [
          markdownPreviewMiddleware.mainWindow.apply,
          httpMiddleware.markdownPreview.apply,
          markdownPreviewMiddleware.markdownTool.apply,
          HtmlPreviewMiddleware().apply,
          httpMiddleware.htmlPreviewMainWindow.apply,
          httpMiddleware.htmlPreviewTool.apply,
        ]
      )
      .filter(\.modified)
      .subscribe(onNext: self.emitAppState)
      .disposed(by: self.disposeBag)
  }

  private let prefMiddleware = PrefMiddleware()

  private func emitAppState(_ tuple: (state: MainWindow.State, action: AnyAction, modified: Bool)) {
    guard let uuidAction = tuple.action as? UuidTagged else { return }

    self.state.mainWindows[uuidAction.uuid] = tuple.state
    self.stateSubject.onNext(self.state)

    self.cleanUpAppState()
  }

  private func emitAppState(_ tuple: ReduxTypes.ReduceTuple) {
    self.state = tuple.state
    self.stateSubject.onNext(self.state)

    self.cleanUpAppState()
  }

  private func cleanUpAppState() {
    for uuid in self.state.mainWindows.keys {
      self.state.mainWindows[uuid]?.cwdToSet = nil
      self.state.mainWindows[uuid]?.currentBufferToSet = nil
      self.state.mainWindows[uuid]?.viewToBeFocused = nil
      self.state.mainWindows[uuid]?.urlsToOpen.removeAll()
    }
  }
}
