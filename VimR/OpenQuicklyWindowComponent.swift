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

  private var cwdPathCompsCount = 0
  private var cwd = NSURL(fileURLWithPath: NSHomeDirectory(), isDirectory: true) {
    didSet {
      self.cwdPathCompsCount = self.cwd.pathComponents!.count
      self.cwdControl.URL = self.cwd
    }
  }
  
  private let filterOpQueue = NSOperationQueue()

  init(source: Observable<Any>, fileItemService: FileItemService) {
    self.fileItemService = fileItemService
    
    super.init(source: source, nibName: "OpenQuicklyWindow")

    self.window.delegate = self
    self.filterOpQueue.qualityOfService = .UserInitiated
    self.filterOpQueue.name = "open-quickly-filter-operation-queue"
    
    self.searchField.rx_text
      .throttle(0.2, scheduler: MainScheduler.instance)
      .distinctUntilChanged()
      .flatMapLatest { [unowned self] pattern in
        self.flatFiles.
        self.filterOpQueue.addOperationWithBlock {
          
        }
        
        return self.flatFiles
      }
      .subscribe(onNext: { [unowned self] pattern in
        NSLog("filtering \(pattern)")
        
      })
      
//      .subscribeOn(self.userInitiatedScheduler)
//      .doOnNext { _ in
//        self.scoredItems = []
//        self.sortedScoredItems = []
//      }
//      .subscribeOn(MainScheduler.instance)
//      .doOnNext { _ in
//        self.fileView.reloadData()
//      }
//      .subscribeOn(self.userInitiatedScheduler)
//      .flatMapLatest { [unowned self] pattern -> Observable<[ScoredFileItem]> in
//        NSLog("Flat map start: \(pattern)")
//        if pattern.characters.count == 0 {
//          return self.flatFiles
//            .map { fileItems in
//              return fileItems.concurrentChunkMap(200) { ScoredFileItem(score: 0, url: $0.url) }
//          }
//        }
//
//        let useFullPath = pattern.containsString("/")
//        let cwdPath = self.cwd.path! + "/"
//        
//        let result: Observable<[ScoredFileItem]> = self.flatFiles
//          .map { fileItems in
//            return fileItems.concurrentChunkMap(200) { item in
//              let url = item.url
//              let target = useFullPath ? url.path!.stringByReplacingOccurrencesOfString(cwdPath, withString: "")
//                                       : url.lastPathComponent!
//              
//              return ScoredFileItem(score: Scorer.score(target, pattern: pattern), url: url)
//            }
//        }
//        NSLog("Flat map end: \(pattern)")
//        
//        return result
//      }
//      .doOnNext { [unowned self] items in
//        self.scoredItems.appendContentsOf(items)
//        self.sortedScoredItems = Array(self.scoredItems.sort(>)[0..<min(201, self.scoredItems.count)])
//      }
//      .observeOn(MainScheduler.instance)
//      .subscribe(onNext: { [unowned self] items in
//        self.fileView.reloadData()
//        })
      .addDisposableTo(self.disposeBag)
  }

  override func addViews() {
    let searchField = self.searchField

    let fileView = self.fileView
    fileView.intercellSpacing = CGSize(width: 4, height: 4)
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
    flatFiles.connect().addDisposableTo(self.flatFilesDisposeBag)

    flatFiles
      .observeOn(MainScheduler.instance)
      .subscribe(onNext: { [unowned self] items in
        self.count += items.count
        self.countField.stringValue = "\(self.count) items"
        })
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
  
  func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
    let url = self.sortedScoredItems[row].url
    let pathComps = url.pathComponents!
    let truncatedPathComps = pathComps[self.cwdPathCompsCount..<pathComps.count]
    let name = truncatedPathComps.last!
    let pathInfo = truncatedPathComps.dropLast().reverse().joinWithSeparator(" / ")
    
    let result = NSMutableAttributedString(string: "\(name) — \(pathInfo)")
    result.addAttribute(NSForegroundColorAttributeName, value: NSColor.lightGrayColor(),
                        range: NSRange(location:name.characters.count, length: pathInfo.characters.count + 3))
    
    let cell = tableView.makeViewWithIdentifier("file-view-row", owner: self) as? ImageAndTextTableCell
               ?? ImageAndTextTableCell(withIdentifier: "file-view-row")
    
    cell.textField.attributedStringValue = result
    cell.imageView.image = self.fileItemService.icon(forUrl: url)
    
    return cell
  }

//  func tableView(_: NSTableView, objectValueForTableColumn _: NSTableColumn?, row: Int) -> AnyObject? {
//    let url = self.sortedScoredItems[row].url
//    let pathComps = self.sortedScoredItems[row].url.pathComponents!
//    let truncatedPathComps = pathComps[self.cwdPathCompsCount..<pathComps.count]
//    let name = truncatedPathComps.last!
//    let pathInfo = truncatedPathComps.dropLast().reverse().joinWithSeparator("/")
//    
//    let textAttachment = NSTextAttachment()
//    textAttachment.image = self.fileItemService.icon(forUrl: url)
//    
//    let result: NSMutableAttributedString = NSAttributedString(attachment: textAttachment).mutableCopy() as! NSMutableAttributedString
//    result.mutableString.appendString("\(name) — \(pathInfo)")
//    result.addAttribute(NSForegroundColorAttributeName, value: NSColor.lightGrayColor(),
//                        range: NSRange(location:name.characters.count, length: pathInfo.characters.count + 3))
//    
//    return result
//  }
}

// MARK: - NSTableViewDelegate
extension OpenQuicklyWindowComponent {

  func tableViewSelectionDidChange(_: NSNotification) {
//    NSLog("\(#function): selection changed")
  }
  
//  func tableView(tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
//    return 34
//  }
}

// MARK: - NSWindowDelegate
extension OpenQuicklyWindowComponent {

  func windowWillClose(notification: NSNotification) {
    self.flatFilesDisposeBag = DisposeBag()
    self.flatFiles = Observable.empty()
    self.count = 0
    
    self.scoredItems = []
    self.sortedScoredItems = []
    
    self.searchField.stringValue = ""
    self.countField.stringValue = "0 items"
  }
}
