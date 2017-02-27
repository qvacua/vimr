/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import RxSwift
import PureLayout

class PrefWindow: NSObject,
                  UiComponent,
                  NSWindowDelegate,
                  NSTableViewDataSource, NSTableViewDelegate {

  typealias StateType = AppState

  required init(source: Observable<StateType>, emitter: ActionEmitter, state: StateType) {
    self.emitter = emitter

    self.windowController = NSWindowController(windowNibName: "PrefWindow")

    super.init()

    self.addViews()

    source
      .observeOn(MainScheduler.instance)
      .subscribe(onNext: { state in

      })
      .addDisposableTo(self.disposeBag)
  }

  fileprivate let emitter: ActionEmitter
  fileprivate let disposeBag = DisposeBag()

  fileprivate let windowController: NSWindowController
  fileprivate var window: NSWindow { return self.windowController.window! }

  fileprivate let categoryView = NSTableView.standardSourceListTableView()
  fileprivate let categoryScrollView = NSScrollView.standardScrollView()
  fileprivate let paneContainer = NSScrollView(forAutoLayout: ())

  fileprivate let panes: [PrefPane]
  fileprivate var currentPane: PrefPane {
    get {
      return self.paneContainer.documentView as! PrefPane
    }

    set {
      self.paneContainer.documentView = newValue

      // Auto-layout seems to be smart enough not to add redundant constraints.
      if newValue.pinToContainer {
        newValue.autoPinEdgesToSuperviewEdges()
      }
    }
  }

  fileprivate func addViews() {

  }
}

// MARK: - NSTableViewDataSource
extension PrefWindow {

  @objc(numberOfRowsInTableView:) func numberOfRows(in _: NSTableView) -> Int {
    return self.panes.count
  }

  @objc(tableView:objectValueForTableColumn:row:) func tableView(_: NSTableView, objectValueFor _: NSTableColumn?, row: Int) -> Any? {
    return self.panes[row].displayName
  }
}

// MARK: - NSTableViewDelegate
extension PrefWindow {

  func tableViewSelectionDidChange(_: Notification) {
    let idx = self.categoryView.selectedRow
    self.currentPane = self.panes[idx]
  }
}
