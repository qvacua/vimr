/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import PureLayout
import RxSwift
import RxCocoa

class OpenQuicklyWindowComponent: WindowComponent,
                                  NSWindowDelegate,
                                  NSTableViewDelegate, NSTableViewDataSource,
                                  NSTextFieldDelegate
{
  let scanCondition = NSCondition()
  var pauseScan = false

  fileprivate(set) var pattern = ""
  fileprivate(set) var cwd = URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true) {
    didSet {
      self.cwdPathCompsCount = self.cwd.pathComponents.count
      self.cwdControl.url = self.cwd
    }
  }
  fileprivate(set) var flatFileItems = [FileItem]()
  fileprivate(set) var fileViewItems = [ScoredFileItem]()

  fileprivate let userInitiatedScheduler = ConcurrentDispatchQueueScheduler(globalConcurrentQueueQOS: .userInitiated)
  
  fileprivate let searchField = NSTextField(forAutoLayout: ())
  fileprivate let progressIndicator = NSProgressIndicator(forAutoLayout: ())
  fileprivate let cwdControl = NSPathControl(forAutoLayout: ())
  fileprivate let countField = NSTextField(forAutoLayout: ())
  fileprivate let fileView = NSTableView.standardTableView()
  
  fileprivate let fileItemService: FileItemService

  fileprivate var count = 0
  fileprivate var perSessionDisposeBag = DisposeBag()

  fileprivate var cwdPathCompsCount = 0
  fileprivate let searchStream: Observable<String>
  fileprivate let filterOpQueue = OperationQueue()
  
  weak fileprivate var mainWindow: MainWindowComponent?

  init(source: Observable<Any>, fileItemService: FileItemService) {
    self.fileItemService = fileItemService
    self.searchStream = self.searchField.rx.textInput.text
      .throttle(0.2, scheduler: MainScheduler.instance)
      .distinctUntilChanged()

    super.init(source: source, nibName: "OpenQuicklyWindow")

    self.window.delegate = self
    self.filterOpQueue.qualityOfService = .userInitiated
    self.filterOpQueue.name = "open-quickly-filter-operation-queue"
  }

  override func addViews() {
    let searchField = self.searchField
    searchField.rx.delegate.setForwardToDelegate(self, retainDelegate: false)

    let progressIndicator = self.progressIndicator
    progressIndicator.isIndeterminate = true
    progressIndicator.isDisplayedWhenStopped = false
    progressIndicator.style = .spinningStyle
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
    cwdControl.cell?.font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize())
    cwdControl.setContentCompressionResistancePriority(NSLayoutPriorityDefaultLow, for:.horizontal)

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
    cwdControl.autoPinEdge(toSuperviewEdge: .left, withInset: 2)
    cwdControl.autoPinEdge(toSuperviewEdge: .bottom, withInset: 4)

    countField.autoPinEdge(.top, to: .bottom, of: fileScrollView, withOffset: 4)
    countField.autoPinEdge(toSuperviewEdge: .right, withInset: 2)
    countField.autoPinEdge(.left, to: .right, of: cwdControl, withOffset: 4)
  }

  override func subscription(source: Observable<Any>) -> Disposable {
    return Disposables.create()
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
  
  func show(forMainWindow mainWindow: MainWindowComponent) {
    self.mainWindow = mainWindow
    self.mainWindow?.sink
      .filter { $0 is MainWindowAction }
      .map { $0 as! MainWindowAction }
      .subscribe(onNext: { [unowned self] action in
        switch action {
        case .close:
          self.window.performClose(self)
          return
          
        default:
          return
        }
      })
      .addDisposableTo(self.perSessionDisposeBag)
    
    self.cwd = mainWindow.cwd as URL
    let flatFiles = self.fileItemService.flatFileItems(ofUrl: self.cwd)
      .subscribeOn(self.userInitiatedScheduler)

    self.searchStream
      .subscribe(onNext: { [unowned self] pattern in
        self.pattern = pattern
        self.resetAndAddFilterOperation()
        })
      .addDisposableTo(self.perSessionDisposeBag)

    flatFiles
      .subscribeOn(self.userInitiatedScheduler)
      .do(onNext: { [unowned self] items in
        self.scanCondition.lock()
        while self.pauseScan {
          self.scanCondition.wait()
        }
        self.scanCondition.unlock()

        self.flatFileItems.append(contentsOf: items)
        self.resetAndAddFilterOperation()
      })
      .observeOn(MainScheduler.instance)
      .subscribe(onNext: { [unowned self] items in
        self.count += items.count
        self.countField.stringValue = "\(self.count) items"
        })
      .addDisposableTo(self.perSessionDisposeBag)

    self.show()
    self.searchField.becomeFirstResponder()
  }

  fileprivate func resetAndAddFilterOperation() {
    self.filterOpQueue.cancelAllOperations()
    let op = OpenQuicklyFilterOperation(forOpenQuicklyWindow: self)
    self.filterOpQueue.addOperation(op)
  }
}

// MARK: - NSTableViewDataSource
extension OpenQuicklyWindowComponent {

  @objc(numberOfRowsInTableView:)
  func numberOfRows(in _: NSTableView) -> Int {
    return self.fileViewItems.count
  }
}

// MARK: - NSTableViewDelegate
extension OpenQuicklyWindowComponent {

  func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
    return OpenQuicklyFileViewRow()
  }

  @objc(tableView:viewForTableColumn:row:)
  func tableView(_ tableView: NSTableView, viewFor _: NSTableColumn?, row: Int) -> NSView? {
    let cachedCell = tableView.make(withIdentifier: "file-view-row", owner: self)
    let cell = cachedCell as? ImageAndTextTableCell ?? ImageAndTextTableCell(withIdentifier: "file-view-row")

    let url = self.fileViewItems[row].url
    cell.text = self.rowText(forUrl: url as URL)
    cell.image = self.fileItemService.icon(forUrl: url)
    
    return cell
  }

  func tableViewSelectionDidChange(_: Notification) {
//    NSLog("\(#function): selection changed")
  }

  fileprivate func rowText(forUrl url: URL) -> NSAttributedString {
    let pathComps = url.pathComponents
    let truncatedPathComps = pathComps[self.cwdPathCompsCount..<pathComps.count]
    let name = truncatedPathComps.last!

    if truncatedPathComps.dropLast().isEmpty {
      return NSMutableAttributedString(string: name)
    }

    let rowText: NSMutableAttributedString
    let pathInfo = truncatedPathComps.dropLast().reversed().joined(separator: " / ")
    rowText = NSMutableAttributedString(string: "\(name) — \(pathInfo)")
    rowText.addAttribute(NSForegroundColorAttributeName,
                         value: NSColor.lightGray,
                         range: NSRange(location:name.characters.count,
                         length: pathInfo.characters.count + 3))

    return rowText
  }
}

// MARK: - NSTextFieldDelegate
extension OpenQuicklyWindowComponent {

  @objc(control:textView:doCommandBySelector:)
  func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
    switch commandSelector {
    case NSSelectorFromString("cancelOperation:"):
      self.window.performClose(self)
      return true
      
    case NSSelectorFromString("insertNewline:"):
      self.mainWindow?.open(urls: [self.fileViewItems[self.fileView.selectedRow].url])
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
extension OpenQuicklyWindowComponent {

  func windowWillClose(_ notification: Notification) {
    self.endProgress()
    
    self.mainWindow = nil
    
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

  func windowDidResignKey(_ notification: Notification) {
    self.window.performClose(self)
  }
}
