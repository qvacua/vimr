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

  enum Action {

    case close
  }

  required init(source: Observable<StateType>, emitter: ActionEmitter, state: StateType) {
    self.emitter = emitter
    self.openStatusMark = state.preferencesOpen.mark

    self.windowController = NSWindowController(windowNibName: "PrefWindow")

    self.panes = [
      GeneralPref(source: source, emitter: emitter, state: state),
      AppearancePref(source: source, emitter: emitter, state: state),
    ]

    super.init()

    self.window.delegate = self

    self.addViews()

    source
      .observeOn(MainScheduler.instance)
      .subscribe(onNext: { state in
        if state.preferencesOpen.payload == false {
          self.openStatusMark = state.preferencesOpen.mark
          self.windowController.close()
          return
        }

        if state.preferencesOpen.mark == self.openStatusMark {
          return
        }

        self.openStatusMark = state.preferencesOpen.mark
        self.windowController.showWindow(self)
      })
      .addDisposableTo(self.disposeBag)
  }

  fileprivate let emitter: ActionEmitter
  fileprivate let disposeBag = DisposeBag()

  fileprivate var openStatusMark: Token

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
    let categoryView = self.categoryView
    categoryView.dataSource = self
    categoryView.delegate = self

    let categoryScrollView = self.categoryScrollView
    categoryScrollView.documentView = categoryView

    let paneContainer = self.paneContainer
    paneContainer.hasVerticalScroller = true
    paneContainer.hasHorizontalScroller = true
    paneContainer.autohidesScrollers = true
    paneContainer.borderType = .noBorder
    paneContainer.autoresizesSubviews = false
    paneContainer.backgroundColor = NSColor.windowBackgroundColor

    self.window.contentView?.addSubview(categoryScrollView)
    self.window.contentView?.addSubview(paneContainer)

    categoryScrollView.autoSetDimension(.width, toSize: 150)
    categoryScrollView.autoPinEdge(toSuperviewEdge: .top, withInset: -1)
    categoryScrollView.autoPinEdge(toSuperviewEdge: .bottom, withInset: -1)
    categoryScrollView.autoPinEdge(toSuperviewEdge: .left, withInset: -1)

    paneContainer.autoSetDimension(.width, toSize: 200, relation: .greaterThanOrEqual)
    paneContainer.autoPinEdge(toSuperviewEdge: .top)
    paneContainer.autoPinEdge(toSuperviewEdge: .right)
    paneContainer.autoPinEdge(toSuperviewEdge: .bottom)
    paneContainer.autoPinEdge(.left, to: .right, of: categoryScrollView)

    self.currentPane = self.panes[0]
  }
}

// MARK: - NSWindowDelegate
extension PrefWindow {

  func windowShouldClose(_: Any) -> Bool {
    self.emitter.emit(Action.close)

    return false
  }

//  func windowWillClose(_: Notification) {
//
//  }
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
