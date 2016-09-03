/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import PureLayout
import RxSwift
import RxCocoa

class OpenQuicklyWindowComponent: WindowComponent, NSWindowDelegate, NSTableViewDelegate, NSTableViewDataSource {
  
  private let searchField = NSTextField(forAutoLayout: ())
  private let cwdControl = NSPathControl(forAutoLayout: ())
  private let countField = NSTextField(forAutoLayout: ())
  private let fileView = NSTableView.standardSourceListTableView()
  
  private let fileItemService: FileItemService

  private var count = 0
  private var flatFiles = Observable<[FileItem]>.empty()
  private var flatFilesDisposeBag = DisposeBag()
  private let userInitiatedScheduler = ConcurrentDispatchQueueScheduler(globalConcurrentQueueQOS: .UserInitiated)

  private var scoredItems = [ScoredFileItem]()
  private var sortedScoredItems = [ScoredFileItem]()

  private var cwd = NSURL(fileURLWithPath: NSHomeDirectory(), isDirectory: true) {
    didSet {
      self.cwdControl.URL = self.cwd
    }
  }

  init(source: Observable<Any>, fileItemService: FileItemService) {
    self.fileItemService = fileItemService
    
    super.init(source: source, nibName: "OpenQuicklyWindow")

    self.window.delegate = self
    self.searchField.rx_text
      .throttle(0.2, scheduler: MainScheduler.instance)
      .distinctUntilChanged()
      .subscribeOn(self.userInitiatedScheduler)
      .doOnNext { _ in
        self.scoredItems = []
        self.sortedScoredItems = []
      }
      .flatMapLatest { [unowned self] pattern -> Observable<[ScoredFileItem]> in
        if pattern.characters.count == 0 {
          return self.flatFiles
            .map { fileItems in
              return fileItems.concurrentChunkMap(50) { item in
                return ScoredFileItem(score: 0, url: item.url)
              }
          }
        }

        let useFullPath = pattern.containsString("/")
        return self.flatFiles
          .map { fileItems in
            return fileItems.concurrentChunkMap(50) { item in
              let url = item.url
              let target = useFullPath ? url.path! : url.lastPathComponent!
              return ScoredFileItem(score: Scorer.score(target, pattern: pattern), url: url)
            }
        }
      }
      .observeOn(MainScheduler.instance)
      .subscribeNext { [unowned self] items in
        self.scoredItems.appendContentsOf(items)
        self.sortedScoredItems = Array(self.scoredItems.sort(>)[0...min(500, self.scoredItems.count - 1)])
        self.fileView.reloadData()
      }
      .addDisposableTo(self.disposeBag)
  }

  override func addViews() {
    let searchField = self.searchField

    let fileView = self.fileView
    fileView.setDataSource(self)
    fileView.setDelegate(self)

    let fileScrollView = NSScrollView.standardScrollView()
    fileScrollView.autoresizesSubviews = true
    fileScrollView.documentView = fileView

    let cwdControl = self.cwdControl
    cwdControl.pathStyle = .Standard
    cwdControl.backgroundColor = NSColor.clearColor()
    cwdControl.refusesFirstResponder = true
    cwdControl.cell?.controlSize = .SmallControlSize
    cwdControl.cell?.font = NSFont.systemFontOfSize(NSFont.smallSystemFontSize())
    cwdControl.setContentCompressionResistancePriority(NSLayoutPriorityDefaultLow, forOrientation:.Horizontal)

    let countField = self.countField
    countField.editable = false
    countField.bordered = false
    countField.alignment = .Right
    countField.backgroundColor = NSColor.clearColor()
    countField.stringValue = "0 items"

    let contentView = self.window.contentView!
    contentView.addSubview(searchField)
    contentView.addSubview(fileScrollView)
    contentView.addSubview(cwdControl)
    contentView.addSubview(countField)

    searchField.autoPinEdgeToSuperviewEdge(.Top, withInset: 18)
    searchField.autoPinEdgeToSuperviewEdge(.Right, withInset: 18)
    searchField.autoPinEdgeToSuperviewEdge(.Left, withInset: 18)

    fileScrollView.autoPinEdge(.Top, toEdge: .Bottom, ofView: searchField, withOffset: 18)
    fileScrollView.autoPinEdge(.Right, toEdge: .Right, ofView: searchField)
    fileScrollView.autoPinEdge(.Left, toEdge: .Left, ofView: searchField)
    fileScrollView.autoSetDimension(.Height, toSize: 300)

    cwdControl.autoPinEdge(.Top, toEdge: .Bottom, ofView: fileScrollView, withOffset: 18)
    cwdControl.autoPinEdgeToSuperviewEdge(.Left, withInset: 18)
    cwdControl.autoPinEdgeToSuperviewEdge(.Bottom, withInset: 18)

    countField.autoPinEdge(.Top, toEdge: .Bottom, ofView: fileScrollView, withOffset: 18)
    countField.autoPinEdgeToSuperviewEdge(.Right, withInset: 18)
    countField.autoPinEdge(.Left, toEdge: .Right, ofView: cwdControl)
  }

  override func subscription(source source: Observable<Any>) -> Disposable {
    return NopDisposable.instance
  }
  
  func show(forMainWindow mainWindow: MainWindowComponent) {
    self.cwd = mainWindow.cwd
    let flatFiles = self.fileItemService.flatFileItems(ofUrl: self.cwd)
      .subscribeOn(self.userInitiatedScheduler)
      .replayAll()
    flatFiles.connect()

    flatFiles
      .observeOn(MainScheduler.instance)
      .subscribeNext { [unowned self] items in
        self.count += items.count
        self.countField.stringValue = "\(self.count) items"
      }
      .addDisposableTo(self.flatFilesDisposeBag)

    self.flatFiles = flatFiles

    self.show()
    self.searchField.becomeFirstResponder()
  }
}

// MARK: - NSTableViewDataSource
extension OpenQuicklyWindowComponent {

  func numberOfRowsInTableView(_: NSTableView) -> Int {
    return self.sortedScoredItems.count
  }

  func tableView(_: NSTableView, objectValueForTableColumn _: NSTableColumn?, row: Int) -> AnyObject? {
    return self.sortedScoredItems[row].url.lastPathComponent!
  }
}

// MARK: - NSTableViewDelegate
extension OpenQuicklyWindowComponent {

  func tableViewSelectionDidChange(_: NSNotification) {
    Swift.print("selection changed")
  }
}

// MARK: - NSWindowDelegate
extension OpenQuicklyWindowComponent {

  func windowDidClose(notification: NSNotification) {
    self.searchField.stringValue = ""
    self.countField.stringValue = "0 items"
    self.count = 0
    self.scoredItems = []
    self.sortedScoredItems = []
    self.flatFiles = Observable.empty()
    self.flatFilesDisposeBag = DisposeBag()
  }
}
