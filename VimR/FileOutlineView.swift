/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import PureLayout
import RxSwift

class FileOutlineView: NSOutlineView,
                       UiComponent,
                       NSOutlineViewDataSource,
                       NSOutlineViewDelegate {

  typealias StateType = MainWindow.State

  enum Action {

    case open(url: URL, mode: MainWindow.OpenMode)
    case setAsWorkingDirectory(URL)
  }

  var cwd: URL = FileUtils.userHomeUrl
  var isShowHidden = false {
    didSet {
      if oldValue == self.isShowHidden {
        return
      }

      self.reloadItem(nil)
    }
  }

  required init(source: Observable<StateType>, emitter: ActionEmitter, state: StateType) {
    self.uuid = state.uuid
    self.root = FileBrowserItem(fileItem: state.root)
    self.fileSystemRoot = state.root
    self.emitter = emitter

    super.init(frame: .zero)
    NSOutlineView.configure(toStandard: self)

    self.dataSource = self
    self.delegate = self

    guard Bundle.main.loadNibNamed("FileBrowserMenu", owner: self, topLevelObjects: nil) else {
      NSLog("WARN: FileBrowserMenu.xib could not be loaded")
      return
    }

    self.doubleAction = #selector(FileOutlineView.doubleClickAction)

    source
      .observeOn(MainScheduler.instance)
      .subscribe(onNext: { [unowned self] state in
        if state.cwd != self.cwd {
          self.lastFileSystemUpdateMark = state.lastFileSystemUpdate.mark
          self.cwd = state.cwd

          self.reloadData()

          return
        }

        if state.lastFileSystemUpdate.mark == self.lastFileSystemUpdateMark {
          return
        }

        self.lastFileSystemUpdateMark = state.lastFileSystemUpdate.mark
        self.update(state.lastFileSystemUpdate.payload)
      })
      .addDisposableTo(self.disposeBag)
  }

  func select(_ url: URL) {
    var itemsToExpand: [FileBrowserItem] = []
    var stack = [self.root]

    while let item = stack.popLast() {
      if item.isChildrenScanned == false {
        item.children = FileItemUtils.sortedChildren(for: item.fileItem.url, root: self.fileSystemRoot)
                                     .map(FileBrowserItem.init)
        item.isChildrenScanned = true
      }

      itemsToExpand.append(item)

      if item.fileItem.url.isDirectParent(of: url) {
        if let targetItem = item.children.first(where: { $0.fileItem.url == url }) {
          itemsToExpand.append(targetItem)
        }
        break
      }

      stack.append(contentsOf: item.children.filter { $0.fileItem.url.isParent(of: url) })
    }

    itemsToExpand.forEach { self.expandItem($0) }

    let targetRow = self.row(forItem: itemsToExpand.last)
    self.selectRowIndexes(IndexSet(integer: targetRow), byExtendingSelection: false)
    self.scrollRowToVisible(targetRow)
  }

  fileprivate let emitter: ActionEmitter
  fileprivate let disposeBag = DisposeBag()

  fileprivate let uuid: String
  fileprivate var lastFileSystemUpdateMark = Token()

  fileprivate var root: FileBrowserItem
  fileprivate let fileSystemRoot: FileItem

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  fileprivate func update(_ fileItem: FileItem) {
    let url = fileItem.url

    guard let fileBrowserItem = self.fileBrowserItem(with: url) else {
      return
    }

    self.beginUpdates()
    self.update(fileBrowserItem)
    self.endUpdates()
  }

  fileprivate func handleRemovals(for fileBrowserItem: FileBrowserItem, new newChildren: [FileBrowserItem]) {
    let curChildren = fileBrowserItem.children

    let curPreparedChildren = self.prepare(curChildren)
    let newPreparedChildren = self.prepare(newChildren)

    let childrenToRemoveIndices = curPreparedChildren
      .enumerated()
      .filter { newPreparedChildren.contains($0.1) == false }
      .map { $0.0 }

    fileBrowserItem.children = curChildren.filter { newChildren.contains($0) }

    let parent = fileBrowserItem == self.root ? nil : fileBrowserItem
    self.removeItems(at: IndexSet(childrenToRemoveIndices), inParent: parent)
  }

  fileprivate func handleAdditions(for fileBrowserItem: FileBrowserItem, new newChildren: [FileBrowserItem]) {
    let curChildren = fileBrowserItem.children

    // We don't just take newChildren because NSOutlineView look at the pointer equality for preserving the expanded
    // states...
    fileBrowserItem.children = newChildren.substituting(elements: curChildren)

    let curPreparedChildren = self.prepare(curChildren)
    let newPreparedChildren = self.prepare(newChildren)

    let indicesToInsert = newPreparedChildren
      .enumerated()
      .filter { curPreparedChildren.contains($0.1) == false }
      .map { $0.0 }

    let parent = fileBrowserItem == self.root ? nil : fileBrowserItem
    self.insertItems(at: IndexSet(indicesToInsert), inParent: parent)
  }

  fileprivate func handleChildren(for fileBrowserItem: FileBrowserItem, new newChildren: [FileBrowserItem]) {
    let curChildren = fileBrowserItem.children

    let curPreparedChildren = self.prepare(curChildren)
    let newPreparedChildren = self.prepare(newChildren)

    let keptChildren = curPreparedChildren.filter { newPreparedChildren.contains($0) }
    let childrenToRecurse = keptChildren.filter { self.isItemExpanded($0) }

    childrenToRecurse.forEach(self.update)
  }

  fileprivate func update(_ fileBrowserItem: FileBrowserItem) {
    let url = fileBrowserItem.fileItem.url

    // Sort the array to keep the order.
    let newChildren = FileItemUtils.sortedChildren(for: url, root: self.fileSystemRoot).map(FileBrowserItem.init)

    self.handleRemovals(for: fileBrowserItem, new: newChildren)
    self.handleAdditions(for: fileBrowserItem, new: newChildren)
    self.handleChildren(for: fileBrowserItem, new: newChildren)
  }

  fileprivate func fileBrowserItem(with url: URL) -> FileBrowserItem? {
    if self.cwd == url {
      return self.root
    }

    guard self.cwd.isParent(of: url) else {
      return nil
    }

    let rootPathComps = self.cwd.pathComponents
    let pathComps = url.pathComponents
    let childPart = pathComps[rootPathComps.count..<pathComps.count]

    return childPart.reduce(self.root) { (resultItem, childName) -> FileBrowserItem? in
      guard let parent = resultItem else {
        return nil
      }

      return parent.child(with: parent.fileItem.url.appendingPathComponent(childName))
    }
  }
}

// MARK: - NSOutlineViewDataSource
extension FileOutlineView {

  fileprivate func prepare(_ children: [FileBrowserItem]) -> [FileBrowserItem] {
    return self.isShowHidden ? children : children.filter { !$0.fileItem.isHidden }
  }

  func outlineView(_: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
    if item == nil {
      let rootFileItem = FileItemUtils.item(for: self.cwd, root: self.fileSystemRoot)
                         ?? FileItemUtils.item(for: FileUtils.userHomeUrl, root: self.fileSystemRoot)!
      self.root = FileBrowserItem(fileItem: rootFileItem)
      if self.root.isChildrenScanned == false {
        self.root.children = FileItemUtils.sortedChildren(for: self.cwd, root: self.fileSystemRoot)
                                          .map(FileBrowserItem.init)
        self.root.isChildrenScanned = true
      }

      return self.prepare(self.root.children).count
    }

    guard let fileBrowserItem = item as? FileBrowserItem else {
      return 0
    }

    let fileItem = fileBrowserItem.fileItem
    if fileItem.isDir {
      if fileBrowserItem.isChildrenScanned == false {
        let fileItemChildren = FileItemUtils.sortedChildren(for: fileItem.url, root: self.fileSystemRoot)
        fileBrowserItem.fileItem.children = fileItemChildren
        fileBrowserItem.children = fileItemChildren.map(FileBrowserItem.init)
        fileBrowserItem.isChildrenScanned = true
      }

      return self.prepare(fileBrowserItem.children).count
    }

    return 0
  }

  func outlineView(_: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
    let level = self.level(forItem: item)

    if item == nil {
      self.adjustColumnWidth(for: self.root.children, outlineViewLevel: level)
      return self.prepare(self.root.children)[index]
    }

    guard let fileBrowserItem = item as? FileBrowserItem else {
      preconditionFailure("Should not happen")
    }

    self.adjustColumnWidth(for: fileBrowserItem.children, outlineViewLevel: level)
    return self.prepare(fileBrowserItem.children)[index]
  }

  func outlineView(_: NSOutlineView, isItemExpandable item: Any) -> Bool {
    guard let fileBrowserItem = item as? FileBrowserItem else {
      return false
    }

    return fileBrowserItem.fileItem.isDir
  }

  @objc(outlineView: objectValueForTableColumn:byItem:)
  func outlineView(_: NSOutlineView, objectValueFor: NSTableColumn?, byItem item: Any?) -> Any? {
    guard let fileBrowserItem = item as? FileBrowserItem else {
      return nil
    }

    return fileBrowserItem
  }

  fileprivate func adjustColumnWidth() {
    let column = self.outlineTableColumn!

    let rows = (0..<self.numberOfRows).map {
      (item: self.item(atRow: $0) as! FileBrowserItem?, level: self.level(forRow: $0))
    }

    let cellWidth = rows.concurrentChunkMap(20) {
                          guard let fileBrowserItem = $0.item else {
                            return 0
                          }

                          return ImageAndTextTableCell.width(with: fileBrowserItem.fileItem.url.lastPathComponent)
                                 + (CGFloat($0.level + 2) * (self.indentationPerLevel + 2)) // + 2 just to have a buffer... -_-
                        }
                        .max() ?? column.width

    guard column.minWidth != cellWidth else {
      return
    }

    column.minWidth = cellWidth
    column.maxWidth = cellWidth
  }

  fileprivate func adjustColumnWidth(for items: [FileBrowserItem], outlineViewLevel level: Int) {
    let column = self.outlineTableColumn!

    // It seems like that caching the widths is slower due to thread-safeness of NSCache...
    let cellWidth = items.concurrentChunkMap(20) {
                           let result = ImageAndTextTableCell.width(with: $0.fileItem.url.lastPathComponent)
                           return result
                         }
                         .max() ?? column.width

    let width = cellWidth + (CGFloat(level + 2) * (self.indentationPerLevel + 2)) // + 2 just to have a buffer... -_-

    guard column.minWidth < width else {
      return
    }

    column.minWidth = width
    column.maxWidth = width
  }
}

// MARK: - NSOutlineViewDelegate
extension FileOutlineView {

  @objc(outlineView: viewForTableColumn:item:)
  func outlineView(_: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
    guard let fileBrowserItem = item as? FileBrowserItem else {
      return nil
    }

    let cachedCell = (self.make(withIdentifier: "file-view-row", owner: self) as? ImageAndTextTableCell)?.reset()
    let cell = cachedCell ?? ImageAndTextTableCell(withIdentifier: "file-view-row")

    cell.text = fileBrowserItem.fileItem.url.lastPathComponent
    let icon = FileUtils.icon(forUrl: fileBrowserItem.fileItem.url)
    cell.image = fileBrowserItem.fileItem.isHidden ? icon?.tinting(with: NSColor.white.withAlphaComponent(0.4)) : icon

    return cell
  }

  func outlineView(_: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat {
    return 20
  }

  func outlineViewItemDidCollapse(_ notification: Notification) {
    self.adjustColumnWidth()
  }
}

// MARK: - Actions
extension FileOutlineView {

  @IBAction func doubleClickAction(_: Any?) {
    guard let item = self.clickedItem as? FileBrowserItem else {
      return
    }

    if item.fileItem.isDir {
      self.toggle(item: item)
    } else {
      self.emitter.emit(UuidAction(uuid: self.uuid, action: Action.open(url: item.fileItem.url, mode: .default)))
    }
  }

  @IBAction func openInNewTab(_: Any?) {
    guard let item = self.clickedItem as? FileBrowserItem else {
      return
    }

    self.emitter.emit(UuidAction(uuid: self.uuid, action: Action.open(url: item.fileItem.url, mode: .newTab)))
  }

  @IBAction func openInCurrentTab(_: Any?) {
    guard let item = self.clickedItem as? FileBrowserItem else {
      return
    }

    self.emitter.emit(UuidAction(uuid: self.uuid, action: Action.open(url: item.fileItem.url, mode: .currentTab)))
  }

  @IBAction func openInHorizontalSplit(_: Any?) {
    guard let item = self.clickedItem as? FileBrowserItem else {
      return
    }

    self.emitter.emit(UuidAction(uuid: self.uuid, action: Action.open(url: item.fileItem.url, mode: .horizontalSplit)))
  }

  @IBAction func openInVerticalSplit(_: Any?) {
    guard let item = self.clickedItem as? FileBrowserItem else {
      return
    }

    self.emitter.emit(UuidAction(uuid: self.uuid, action: Action.open(url: item.fileItem.url, mode: .verticalSplit)))
  }

  @IBAction func setAsWorkingDirectory(_: Any?) {
    guard let item = self.clickedItem as? FileBrowserItem else {
      return
    }

    guard item.fileItem.isDir else {
      return
    }

    self.emitter.emit(UuidAction(uuid: self.uuid, action: Action.setAsWorkingDirectory(item.fileItem.url)))
  }
}

// MARK: - NSUserInterfaceValidations
extension FileOutlineView {

  override func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
    guard let clickedItem = self.clickedItem as? FileBrowserItem else {
      return true
    }

    if item.action == #selector(setAsWorkingDirectory(_:)) {
      return clickedItem.fileItem.isDir
    }

    return true
  }
}

// MARK: - NSView
extension FileOutlineView {

  override func keyDown(with event: NSEvent) {
    guard let char = event.charactersIgnoringModifiers?.characters.first else {
      super.keyDown(with: event)
      return
    }

    guard let item = self.selectedItem as? FileBrowserItem else {
      super.keyDown(with: event)
      return
    }

    switch char {
    case " ", "\r": // Why "\r" and not "\n"?
      if item.fileItem.isDir || item.fileItem.isPackage {
        self.toggle(item: item)
      } else {
        self.emitter.emit(UuidAction(uuid: self.uuid, action: Action.open(url: item.fileItem.url, mode: .newTab)))
      }

    default:
      super.keyDown(with: event)
    }
  }
}

fileprivate class FileBrowserItem: Hashable, Comparable, CustomStringConvertible {

  static func ==(left: FileBrowserItem, right: FileBrowserItem) -> Bool {
    return left.fileItem == right.fileItem
  }

  static func <(left: FileBrowserItem, right: FileBrowserItem) -> Bool {
    return left.fileItem.url.lastPathComponent < right.fileItem.url.lastPathComponent
  }

  var hashValue: Int {
    return self.fileItem.hashValue
  }

  var description: String {
    return self.fileItem.url.path
  }

  let fileItem: FileItem
  var children: [FileBrowserItem] = []
  var isChildrenScanned = false

  /**
    `fileItem` is copied. Children are _not_ populated.
   */
  init(fileItem: FileItem) {
    self.fileItem = fileItem.copy()
  }

  func child(with url: URL) -> FileBrowserItem? {
    return self.children.first { $0.fileItem.url == url }
  }
}
