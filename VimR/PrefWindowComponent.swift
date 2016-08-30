/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import RxSwift
import PureLayout

struct PrefData {
  var general: GeneralPrefData
  var appearance: AppearancePrefData
}

class PrefWindowComponent: WindowComponent, NSTableViewDataSource, NSTableViewDelegate {

  private var data: PrefData

  private let categoryView = NSTableView(frame: CGRect.zero)
  private let categoryScrollView = NSScrollView(forAutoLayout: ())
  private let paneContainer = NSScrollView(forAutoLayout: ())

  private let paneNames = [ "General", "Appearance" ]
  private let panes: [PrefPane]

  private var currentPane: PrefPane {
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
      AppearancePrefPane(source: source, initialData: self.data.appearance)
    ]
    
    super.init(source: source, nibName: "PrefWindow")

    self.addReactions()
  }

  override func subscription(source source: Observable<Any>) -> Disposable {
    return source
      .filter { $0 is PrefData }
      .map { $0 as! PrefData }
      .subscribeNext { [unowned self] prefData in
        if prefData.appearance.editorFont == self.data.appearance.editorFont
          && prefData.appearance.editorUsesLigatures == self.data.appearance.editorUsesLigatures {
          return
        }

        self.data = prefData
      }
  }

  override func addViews() {
    let tableColumn = NSTableColumn(identifier: "name")
    let textFieldCell = NSTextFieldCell()
    textFieldCell.allowsEditingTextAttributes = false
    textFieldCell.lineBreakMode = .ByTruncatingTail
    tableColumn.dataCell = textFieldCell

    let categoryView = self.categoryView
    categoryView.addTableColumn(tableColumn)
    categoryView.rowSizeStyle	=	.Default
    categoryView.sizeLastColumnToFit()
    categoryView.allowsEmptySelection = false
    categoryView.allowsMultipleSelection = false
    categoryView.headerView = nil
    categoryView.focusRingType = .None
    categoryView.selectionHighlightStyle = .SourceList
    categoryView.setDataSource(self)
    categoryView.setDelegate(self)

    let categoryScrollView = self.categoryScrollView
    categoryScrollView.hasVerticalScroller = true
    categoryScrollView.hasHorizontalScroller = true
    categoryScrollView.autohidesScrollers = true
    categoryScrollView.borderType = .BezelBorder
    categoryScrollView.documentView = categoryView

    let paneContainer = self.paneContainer
    paneContainer.hasVerticalScroller = true
    paneContainer.hasHorizontalScroller = true
    paneContainer.autohidesScrollers = true
    paneContainer.borderType = .NoBorder
    paneContainer.autoresizesSubviews = false
    paneContainer.backgroundColor = NSColor.windowBackgroundColor()

    self.window.contentView?.addSubview(categoryScrollView)
    self.window.contentView?.addSubview(paneContainer)

    categoryScrollView.autoSetDimension(.Width, toSize: 150)
    categoryScrollView.autoPinEdgeToSuperviewEdge(.Top, withInset: -1)
    categoryScrollView.autoPinEdgeToSuperviewEdge(.Bottom, withInset: -1)
    categoryScrollView.autoPinEdgeToSuperviewEdge(.Left, withInset: -1)

    paneContainer.autoSetDimension(.Width, toSize: 200, relation: .GreaterThanOrEqual)
    paneContainer.autoPinEdgeToSuperviewEdge(.Top)
    paneContainer.autoPinEdgeToSuperviewEdge(.Right)
    paneContainer.autoPinEdgeToSuperviewEdge(.Bottom)
    paneContainer.autoPinEdge(.Left, toEdge: .Right, ofView: categoryScrollView)

    self.currentPane = self.panes[0]
  }

  private func addReactions() {
    self.panes
      .map { $0.sink }
      .toMergedObservables()
      .map { [unowned self] action in
        switch action {
        case let data as AppearancePrefData:
          self.data.appearance = data
        case let data as GeneralPrefData:
          self.data.general = data
        default:
          NSLog("nothing to see here")
        }

        return self.data
      }
      .subscribeNext { [unowned self] action in self.publish(event: action) }
      .addDisposableTo(self.disposeBag)
  }
}

// MARK: - NSTableViewDataSource
extension PrefWindowComponent {

  func numberOfRowsInTableView(_: NSTableView) -> Int {
    return self.paneNames.count
  }

  func tableView(_: NSTableView, objectValueForTableColumn _: NSTableColumn?, row: Int) -> AnyObject? {
    return self.paneNames[row]
  }
}

// MARK: - NSTableViewDelegate
extension PrefWindowComponent {

  func tableViewSelectionDidChange(_: NSNotification) {
    let idx = self.categoryView.selectedRow
    self.currentPane = self.panes[idx]
  }
}
