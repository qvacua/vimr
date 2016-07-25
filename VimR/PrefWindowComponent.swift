/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import RxSwift
import PureLayout

struct PrefData {
  var appearance: AppearancePrefData
}

class PrefWindowComponent: NSObject, NSTableViewDataSource, NSTableViewDelegate, Component {

  private static let defaultEditorFont = NSFont(name: "Menlo", size: 13)!

  private let source: Observable<Any>
  private let disposeBag = DisposeBag()

  private let subject = PublishSubject<Any>()
  var sink: Observable<Any> {
    return self.subject.asObservable()
  }

  private var data = PrefData(
    appearance: AppearancePrefData(editorFont: PrefWindowComponent.defaultEditorFont)
  )

  private let windowController = NSWindowController(windowNibName: "PrefWindow")
  private let window: NSWindow

  private let categoryView = NSTableView(frame: CGRect.zero)
  private let categoryScrollView = NSScrollView(forAutoLayout: ())
  private let paneScrollView = NSScrollView(forAutoLayout: ())

  private let paneNames = [ "Appearance" ]
  private let panes: [ViewComponent]

  init(source: Observable<Any>) {
    self.source = source

    self.panes = [
      AppearancePrefPane(source: Observable.empty(), data: self.data.appearance)
    ]
    
    self.window = self.windowController.window!

    super.init()
    
    self.addViews()
    self.addReactions()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  deinit {
    self.subject.onCompleted()
  }

  func show() {
    self.windowController.showWindow(self)
  }

  private func addReactions() {
    self.panes
      .map { $0.sink }
      .toObservable()
      .flatMap { $0 }
      .map { [unowned self] action in
        switch action {
        case let data as AppearancePrefData:
          self.data.appearance = data
        default:
          NSLog("nothing to see here")
        }

        return self.data
      }
      .subscribeNext { [unowned self] action in self.subject.onNext(action) }
      .addDisposableTo(self.disposeBag)
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
    paneScrollView.hasHorizontalScroller = false;
    paneScrollView.autohidesScrollers = true;
    paneScrollView.borderType = .NoBorder;
    paneScrollView.autoresizesSubviews = true;
    paneScrollView.backgroundColor = NSColor.windowBackgroundColor();

    self.window.contentView?.addSubview(categoryScrollView)
    self.window.contentView?.addSubview(paneScrollView)

    categoryScrollView.autoSetDimension(.Width, toSize: 150)
    categoryScrollView.autoPinEdgeToSuperviewEdge(.Top, withInset: -1)
    categoryScrollView.autoPinEdgeToSuperviewEdge(.Bottom, withInset: -1)
    categoryScrollView.autoPinEdgeToSuperviewEdge(.Left, withInset: -1)
    paneScrollView.autoSetDimension(.Width, toSize: 200, relation: .GreaterThanOrEqual)
    paneScrollView.autoPinEdgeToSuperviewEdge(.Top)
    paneScrollView.autoPinEdgeToSuperviewEdge(.Right)
    paneScrollView.autoPinEdgeToSuperviewEdge(.Bottom)
    paneScrollView.autoPinEdge(.Left, toEdge: .Right, ofView: categoryScrollView)

    let pane = self.panes[0].view
    self.paneScrollView.documentView = pane
    pane.autoPinEdgeToSuperviewEdge(.Right)
    pane.autoPinEdgeToSuperviewEdge(.Left)
  }
}

// MARK: - NSTableViewDataSource
extension PrefWindowComponent {

  func numberOfRowsInTableView(tableView: NSTableView) -> Int {
    return self.paneNames.count
  }

  func tableView(_: NSTableView, objectValueForTableColumn _: NSTableColumn?, row: Int) -> AnyObject? {
    return self.paneNames[row]
  }
}

// MARK: - NSTableViewDelegate
extension PrefWindowComponent {

  func tableViewSelectionDidChange(notification: NSNotification) {
  }
}
