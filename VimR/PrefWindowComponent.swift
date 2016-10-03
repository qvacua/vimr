/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import RxSwift
import PureLayout

class PrefWindowComponent: WindowComponent, NSWindowDelegate, NSTableViewDataSource, NSTableViewDelegate {

  fileprivate var data: PrefData

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

  init(source: Observable<Any>, initialData: PrefData) {
    self.data = initialData

    self.panes = [
      GeneralPrefPane(source: source, initialData: self.data.general),
      AppearancePrefPane(source: source, initialData: self.data.appearance),
      AdvancedPrefPane(source: source, initialData: self.data.advanced)
    ]
    
    super.init(source: source, nibName: "PrefWindow")

    self.window.delegate = self

    self.addReactions()
  }

  override func subscription(source: Observable<Any>) -> Disposable {
    return source
      .filter { $0 is PrefData }
      .map { $0 as! PrefData }
      .subscribe(onNext: { [unowned self] prefData in
        if prefData.appearance.editorFont == self.data.appearance.editorFont
          && prefData.appearance.editorUsesLigatures == self.data.appearance.editorUsesLigatures {
          return
        }

        self.data = prefData
      })
  }

  override func addViews() {
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

  fileprivate func addReactions() {
    self.panes
      .map { $0.sink }
      .toMergedObservables()
      .map { [unowned self] action in
        switch action {
        case let data as AppearancePrefData:
          self.data.appearance = data
        case let data as GeneralPrefData:
          self.data.general = data
        case let data as AdvancedPrefData:
          self.data.advanced = data
        default:
          NSLog("nothing to see here")
        }

        return self.data
      }
      .subscribe(onNext: { [unowned self] action in self.publish(event: action) })
      .addDisposableTo(self.disposeBag)
  }

  func windowWillClose(_ notification: Notification) {
    self.panes.forEach { $0.windowWillClose() }
  }
}

// MARK: - NSTableViewDataSource
extension PrefWindowComponent {

  @objc(numberOfRowsInTableView:) func numberOfRows(in _: NSTableView) -> Int {
    return self.panes.count
  }

  @objc(tableView:objectValueForTableColumn:row:) func tableView(_: NSTableView, objectValueFor _: NSTableColumn?, row: Int) -> Any? {
    return self.panes[row].displayName
  }
}

// MARK: - NSTableViewDelegate
extension PrefWindowComponent {

  func tableViewSelectionDidChange(_: Notification) {
    let idx = self.categoryView.selectedRow
    self.currentPane = self.panes[idx]
  }
}
