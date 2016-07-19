/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import RxSwift
import PureLayout

enum PrefAction {
  case PrefChanged(prefs: [String: Any])
}

class PrefWindowController: NSWindowController, NSTableViewDataSource, NSTableViewDelegate {

  private let windowMask = NSTitledWindowMask
    | NSResizableWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask
  
  private let source: Observable<Any>
  private let disposeBag = DisposeBag()
  let sink = PublishSubject<Any>().asObserver()
  
  private let categoryView = NSTableView(frame: CGRect.zero)
  private let categoryScrollView = NSScrollView(forAutoLayout: ())
  private let paneScrollView = NSScrollView(forAutoLayout: ())

  private let paneNames = [ "Appearance" ]
  private let panes = [ AppearancePrefPane(forAutoLayout: ()) ]

  init(source: Observable<Any>) {
    self.source = source
    
    let window = NSWindow(
      contentRect: CGRect(x: 100, y: 100, width: 640, height: 480),
      styleMask: self.windowMask,
      backing: .Buffered,
      defer: true
    )
    window.title = "Preferences"
    window.releasedWhenClosed = false
    window.center()

    super.init(window: window)
    
    self.addViews()
  }
  
  private func addViews() {
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

    let paneScrollView = self.paneScrollView
    paneScrollView.hasVerticalScroller = true;
    paneScrollView.hasHorizontalScroller = true;
    paneScrollView.borderType = .NoBorder;
    paneScrollView.autohidesScrollers = true;
    paneScrollView.autoresizesSubviews = true;
    paneScrollView.backgroundColor = NSColor.windowBackgroundColor();
    paneScrollView.autohidesScrollers = true;

    self.window?.contentView?.addSubview(categoryScrollView)
    self.window?.contentView?.addSubview(paneScrollView)

    categoryScrollView.autoSetDimension(.Width, toSize: 150)
    categoryScrollView.autoPinEdgeToSuperviewEdge(.Top, withInset: -1)
    categoryScrollView.autoPinEdgeToSuperviewEdge(.Bottom, withInset: -1)
    categoryScrollView.autoPinEdgeToSuperviewEdge(.Left, withInset: -1)
    paneScrollView.autoSetDimension(.Width, toSize: 200, relation: .GreaterThanOrEqual)
    paneScrollView.autoPinEdgeToSuperviewEdge(.Top)
    paneScrollView.autoPinEdgeToSuperviewEdge(.Right)
    paneScrollView.autoPinEdgeToSuperviewEdge(.Bottom)
    paneScrollView.autoPinEdge(.Left, toEdge: .Right, ofView: categoryScrollView)

    self.paneScrollView.documentView = self.panes[0]
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

// MARK: - NSTableViewDataSource
extension PrefWindowController {
  func numberOfRowsInTableView(tableView: NSTableView) -> Int {
    return self.paneNames.count
  }

  /* This method is required for the "Cell Based" TableView, and is optional for the "View Based" TableView. If implemented in the latter case, the value will be set to the view at a given row/column if the view responds to -setObjectValue: (such as NSControl and NSTableCellView).
   */
  func tableView(tableView: NSTableView, objectValueForTableColumn tableColumn: NSTableColumn?, row: Int) -> AnyObject? {
    return self.paneNames[row]
  }
}

// MARK: - NSTableViewDelegate
extension PrefWindowController {
  func tableViewSelectionDidChange(notification: NSNotification) {
  }
}
