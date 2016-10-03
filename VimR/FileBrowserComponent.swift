/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import RxSwift

enum FileBrowserAction {

  case open(url: URL)
}

class FileBrowserComponent: ViewComponent, NSOutlineViewDataSource, NSOutlineViewDelegate {

  fileprivate var cwd = FileUtils.userHomeUrl
  fileprivate var cwdFileItem = FileItem(FileUtils.userHomeUrl)

  fileprivate let fileView: FileOutlineView
  fileprivate let fileItemService: FileItemService

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override var isFirstResponder: Bool {
    return self.fileView.isFirstResponder
  }

  init(source: Observable<Any>, fileItemService: FileItemService) {
    self.fileItemService = fileItemService
    self.fileView = FileOutlineView(source: source)
    
    super.init(source: source)
    self.addReactions()
  }

  override func beFirstResponder() {
    self.window?.makeFirstResponder(self.fileView)
  }

  fileprivate func addReactions() {
    self.fileView.sink
      .filter { $0 is FileOutlineViewAction }
      .map { $0 as! FileOutlineViewAction }
      .subscribe(onNext: { [unowned self] action in
        switch action {
        case let .openFileItem(fileItem):
          self.doubleAction(for: fileItem)
        }
      })
      .addDisposableTo(self.disposeBag)

    self.fileItemService.sink
      .filter { $0 is FileItemServiceChange }
      .map { $0 as! FileItemServiceChange }
      .subscribe(onNext: { [unowned self] action in
        switch action {
        case let .childrenChanged(root, fileItem):
          guard root == self.cwd else {
            return
          }

//          NSLog("\(root) -> \(fileItem)")
          DispatchUtils.gui {
            self.fileView.reloadItem(fileItem, reloadChildren: true)
          }
        }
        })
      .addDisposableTo(self.disposeBag)
  }

  override func addViews() {
    let fileView = self.fileView
    NSOutlineView.configure(toStandard: fileView)
    fileView.dataSource = self
    fileView.delegate = self
    fileView.doubleAction = #selector(FileBrowserComponent.fileViewDoubleAction)

    let scrollView = NSScrollView.standardScrollView()
    scrollView.borderType = .noBorder
    scrollView.documentView = fileView

    self.addSubview(scrollView)
    scrollView.autoPinEdgesToSuperviewEdges()
  }

  override func subscription(source: Observable<Any>) -> Disposable {
    return source
      .filter { $0 is MainWindowAction }
      .map { $0 as! MainWindowAction }
      .subscribe(onNext: { [unowned self] action in
        switch action {
        case let .changeCwd(mainWindow: mainWindow):
          self.cwd = mainWindow.cwd
          self.cwdFileItem = self.fileItemService.fileItemWithChildren(for: self.cwd) ??
                             self.fileItemService.fileItemWithChildren(for: FileUtils.userHomeUrl)!
//          NSLog("cwd changed to \(self.cwd) of \(mainWindow.uuid)")
          self.fileView.reloadData()

        default:
          break
        }
      })
  }
}

// MARK: - Actions
extension FileBrowserComponent {

  func fileViewDoubleAction() {
    guard let item = self.fileView.selectedItem as? FileItem else {
      return
    }

    self.doubleAction(for: item)
  }

  fileprivate func doubleAction(for item: FileItem) {
    if item.dir {
      self.fileView.toggle(item: item)
    } else {
      self.publish(event: FileBrowserAction.open(url: item.url))
    }
  }
}

// MARK: - NSOutlineViewDataSource
extension FileBrowserComponent {

  func outlineView(_: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
    if item == nil {
      return self.fileItemService.fileItemWithChildren(for: self.cwd)?.children
        .filter { !$0.hidden }
        .count ?? 0
    }

    guard let fileItem = item as? FileItem else {
      return 0
    }

    if fileItem.dir {
      return self.fileItemService.fileItemWithChildren(for: fileItem.url)?.children
        .filter { !$0.hidden }
        .count ?? 0
    }

    return 0
  }

  func outlineView(_: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
    if item == nil {
      return self.fileItemService.fileItemWithChildren(for: self.cwd)!.children.filter { !$0.hidden }[index]
    }
    
    guard let fileItem = item as? FileItem else {
      preconditionFailure("Should not happen")
    }
    
    return self.fileItemService.fileItemWithChildren(for: fileItem.url)!.children.filter { !$0.hidden }[index]
  }

  func outlineView(_: NSOutlineView, isItemExpandable item: Any) ->  Bool {
    guard let fileItem = item as? FileItem else {
      return false
    }
    
    return fileItem.dir
  }

  @objc(outlineView:objectValueForTableColumn:byItem:)
  func outlineView(_: NSOutlineView, objectValueFor: NSTableColumn?, byItem item: Any?) -> Any? {
    guard let fileItem = item as? FileItem else {
      return nil
    }
    
    return fileItem
  }
}

// MARK: - NSOutlineViewDelegate
extension FileBrowserComponent {
  
  @objc(outlineView:viewForTableColumn:item:)
  func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
    guard let fileItem = item as? FileItem else {
      return nil
    }
    
    let cachedCell = outlineView.make(withIdentifier: "file-view-row", owner: self)
    let cell = cachedCell as? ImageAndTextTableCell ?? ImageAndTextTableCell(withIdentifier: "file-view-row")

    cell.text = fileItem.url.lastPathComponent
    cell.image = self.fileItemService.icon(forUrl: fileItem.url)

    return cell
  }
  
  func outlineView(_ outlineView: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat {
    return 20
  }
}
