/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import RxSwift
import RxCocoa
import PureLayout

class OpenQuicklyWindow: NSObject,
                         UiComponent,
                         NSWindowDelegate,
                         NSTextFieldDelegate,
                         NSTableViewDelegate, NSTableViewDataSource {

  typealias StateType = AppState

  enum Action {

    case open(URL)
    case close
  }

  let scanCondition = NSCondition()
  var pauseScan = false

  required init(source: Observable<StateType>, emitter: ActionEmitter, state: StateType) {
    self.emit = emitter.typedEmit()
    self.windowController = NSWindowController(windowNibName: NSNib.Name("OpenQuicklyWindow"))

    self.searchStream = self.searchField.rx
      .text.orEmpty
      .throttle(0.2, scheduler: MainScheduler.instance)
      .distinctUntilChanged()

    super.init()

    self.window.delegate = self

    self.filterOpQueue.qualityOfService = .userInitiated
    self.filterOpQueue.name = "open-quickly-filter-operation-queue"

    self.addViews()

    source
      .observeOn(MainScheduler.instance)
      .subscribe(onNext: { [unowned self] state in
        guard state.openQuickly.open else {
          self.windowController.close()
          return
        }

        if self.window.isKeyWindow {
          // already open, so do nothing
          return
        }

        self.cwd = state.openQuickly.cwd
        self.cwdPathCompsCount = self.cwd.pathComponents.count
        self.cwdControl.url = self.cwd

        self.flatFileItemsSource = FileItemUtils.flatFileItems(
          of: state.openQuickly.cwd,
          ignorePatterns: state.openQuickly.ignorePatterns,
          ignoreToken: state.openQuickly.ignoreToken,
          root: state.openQuickly.root
        )

        self.searchStream
          .subscribe(onNext: { [unowned self] pattern in
            self.pattern = pattern
            self.resetAndAddFilterOperation()
          })
          .disposed(by: self.perSessionDisposeBag)

        self.flatFileItemsSource
          .subscribeOn(self.scheduler)
          .do(onNext: { [unowned self] items in
            self.scanCondition.lock()
            while self.pauseScan {
              self.scanCondition.wait()
            }
            self.scanCondition.unlock()

            //
            self.flatFileItems.append(contentsOf: items)
            self.resetAndAddFilterOperation()
          })
          .observeOn(MainScheduler.instance)
          .subscribe(onNext: { [unowned self] items in
            self.count += items.count
            self.countField.stringValue = "\(self.count) items"
          })
          .disposed(by: self.perSessionDisposeBag)

        self.windowController.showWindow(self)
      })
      .disposed(by: self.disposeBag)
  }

  func reloadFileView(withScoredItems items: [ScoredFileItem]) {
    self.fileViewItems = items
    self.fileView.reloadData()
  }

  func startProgress() {
    self.progressIndicator.startAnimation(self)
  }

  func endProgress() {
    self.progressIndicator.stopAnimation(self)
  }

  fileprivate let emit: (Action) -> Void
  fileprivate let disposeBag = DisposeBag()

  fileprivate var flatFileItemsSource = Observable<[FileItem]>.empty()
  fileprivate(set) var cwd = FileUtils.userHomeUrl
  fileprivate var cwdPathCompsCount = 0

  // FIXME: migrate to State later...
  fileprivate(set) var pattern = ""
  fileprivate(set) var flatFileItems = [FileItem]()
  fileprivate(set) var fileViewItems = [ScoredFileItem]()
  fileprivate var count = 0
  fileprivate var perSessionDisposeBag = DisposeBag()
  fileprivate let filterOpQueue = OperationQueue()

  fileprivate let scheduler = ConcurrentDispatchQueueScheduler(qos: .userInitiated)

  fileprivate let windowController: NSWindowController

  fileprivate let searchField = NSTextField(forAutoLayout: ())
  fileprivate let progressIndicator = NSProgressIndicator(forAutoLayout: ())
  fileprivate let cwdControl = NSPathControl(forAutoLayout: ())
  fileprivate let countField = NSTextField(forAutoLayout: ())
  fileprivate let fileView = NSTableView.standardTableView()

  fileprivate let searchStream: Observable<String>

  fileprivate var window: NSWindow {
    return self.windowController.window!
  }

  fileprivate func resetAndAddFilterOperation() {
    self.filterOpQueue.cancelAllOperations()
    let op = OpenQuicklyFilterOperation(forOpenQuickly: self)
    self.filterOpQueue.addOperation(op)
  }

  fileprivate func addViews() {
    let searchField = self.searchField
    searchField.rx.delegate.setForwardToDelegate(self, retainDelegate: false)

    let progressIndicator = self.progressIndicator
    progressIndicator.isIndeterminate = true
    progressIndicator.isDisplayedWhenStopped = false
    progressIndicator.style = .spinning
    progressIndicator.controlSize = .small

    let fileView = self.fileView
    fileView.intercellSpacing = CGSize(width: 4, height: 4)
    fileView.dataSource = self
    fileView.delegate = self

    let fileScrollView = NSScrollView.standardScrollView()
    fileScrollView.autoresizesSubviews = true
    fileScrollView.documentView = fileView

    let cwdControl = self.cwdControl
    cwdControl.pathStyle = .standard
    cwdControl.backgroundColor = NSColor.clear
    cwdControl.refusesFirstResponder = true
    cwdControl.cell?.controlSize = .small
    cwdControl.cell?.font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
    cwdControl.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

    let countField = self.countField
    countField.isEditable = false
    countField.isBordered = false
    countField.alignment = .right
    countField.backgroundColor = NSColor.clear
    countField.stringValue = "0 items"

    let contentView = self.window.contentView!
    contentView.addSubview(searchField)
    contentView.addSubview(progressIndicator)
    contentView.addSubview(fileScrollView)
    contentView.addSubview(cwdControl)
    contentView.addSubview(countField)

    searchField.autoPinEdge(toSuperviewEdge: .top, withInset: 8)
    searchField.autoPinEdge(toSuperviewEdge: .right, withInset: 8)
    searchField.autoPinEdge(toSuperviewEdge: .left, withInset: 8)

    progressIndicator.autoAlignAxis(.horizontal, toSameAxisOf: searchField)
    progressIndicator.autoPinEdge(.right, to: .right, of: searchField, withOffset: -4)

    fileScrollView.autoPinEdge(.top, to: .bottom, of: searchField, withOffset: 8)
    fileScrollView.autoPinEdge(toSuperviewEdge: .left, withInset: -1)
    fileScrollView.autoPinEdge(toSuperviewEdge: .right, withInset: -1)
    fileScrollView.autoSetDimension(.height, toSize: 200, relation: .greaterThanOrEqual)

    cwdControl.autoPinEdge(.top, to: .bottom, of: fileScrollView, withOffset: 4)
//    cwdControl.autoPinEdge(toSuperviewEdge: .bottom)
    cwdControl.autoPinEdge(toSuperviewEdge: .left, withInset: 2)
    cwdControl.autoPinEdge(toSuperviewEdge: .bottom, withInset: 4)

//    countField.autoPinEdge(toSuperviewEdge: .bottom)
    countField.autoPinEdge(.top, to: .bottom, of: fileScrollView, withOffset: 4)
    countField.autoPinEdge(toSuperviewEdge: .right, withInset: 2)
    countField.autoPinEdge(.left, to: .right, of: cwdControl, withOffset: 4)
  }
}

// MARK: - NSTableViewDataSource
extension OpenQuicklyWindow {

  @objc(numberOfRowsInTableView:)
  func numberOfRows(in _: NSTableView) -> Int {
    return self.fileViewItems.count
  }
}

// MARK: - NSTableViewDelegate
extension OpenQuicklyWindow {

  func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
    return OpenQuicklyFileViewRow()
  }

  @objc(tableView: viewForTableColumn:row:)
  func tableView(_ tableView: NSTableView, viewFor _: NSTableColumn?, row: Int) -> NSView? {
    let cachedCell = (tableView.makeView(
      withIdentifier: NSUserInterfaceItemIdentifier("file-view-row"), owner: self) as? ImageAndTextTableCell
    )?.reset()
    let cell = cachedCell ?? ImageAndTextTableCell(withIdentifier: "file-view-row")

    let url = self.fileViewItems[row].url
    cell.attributedText = self.rowText(for: url as URL)
    cell.image = FileUtils.icon(forUrl: url)

    return cell
  }

  func tableViewSelectionDidChange(_: Notification) {
//    NSLog("\(#function): selection changed")
  }

  fileprivate func rowText(for url: URL) -> NSAttributedString {
    let pathComps = url.pathComponents
    let truncatedPathComps = pathComps[self.cwdPathCompsCount..<pathComps.count]
    let name = truncatedPathComps.last!

    if truncatedPathComps.dropLast().isEmpty {
      return NSMutableAttributedString(string: name)
    }

    let rowText: NSMutableAttributedString
    let pathInfo = truncatedPathComps.dropLast().reversed().joined(separator: " / ")
    rowText = NSMutableAttributedString(string: "\(name) — \(pathInfo)")
    rowText.addAttribute(NSAttributedStringKey.foregroundColor,
                         value: NSColor.lightGray,
                         range: NSRange(location: name.count, length: pathInfo.count + 3))

    return rowText
  }
}

// MARK: - NSTextFieldDelegate
extension OpenQuicklyWindow {

  @objc(control: textView:doCommandBySelector:)
  func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
    switch commandSelector {
    case NSSelectorFromString("cancelOperation:"):
      self.window.performClose(self)
      return true

    case NSSelectorFromString("insertNewline:"):
      // TODO open the url
      self.emit(.open(self.fileViewItems[self.fileView.selectedRow].url))
      self.window.performClose(self)
      return true

    case NSSelectorFromString("moveUp:"):
      self.moveSelection(ofTableView: self.fileView, byDelta: -1)
      return true

    case NSSelectorFromString("moveDown:"):
      self.moveSelection(ofTableView: self.fileView, byDelta: 1)
      return true

    default:
      return false
    }
  }

  fileprivate func moveSelection(ofTableView tableView: NSTableView, byDelta delta: Int) {
    let selectedRow = tableView.selectedRow
    let lastIdx = tableView.numberOfRows - 1
    let targetIdx: Int

    if selectedRow + delta < 0 {
      targetIdx = 0
    } else if selectedRow + delta > lastIdx {
      targetIdx = lastIdx
    } else {
      targetIdx = selectedRow + delta
    }

    tableView.selectRowIndexes(IndexSet(integer: targetIdx), byExtendingSelection: false)
    tableView.scrollRowToVisible(targetIdx)
  }
}

// MARK: - NSWindowDelegate
extension OpenQuicklyWindow {

  func windowShouldClose(_: NSWindow) -> Bool {
    self.emit(.close)

    return false
  }

  func windowWillClose(_: Notification) {
    self.endProgress()

    self.filterOpQueue.cancelAllOperations()

    self.perSessionDisposeBag = DisposeBag()
    self.pauseScan = false
    self.count = 0

    self.pattern = ""
    self.flatFileItems = []
    self.fileViewItems = []
    self.fileView.reloadData()

    self.searchField.stringValue = ""
    self.countField.stringValue = "0 items"
  }

  func windowDidResignKey(_: Notification) {
    self.window.performClose(self)
  }
}
