/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import PureLayout
import RxSwift

enum FileOutlineViewAction {

  case open(fileItem: FileItem)
  case openFileInNewTab(fileItem: FileItem)
  case openFileInCurrentTab(fileItem: FileItem)
  case openFileInHorizontalSplit(fileItem: FileItem)
  case openFileInVerticalSplit(fileItem: FileItem)
  case setAsWorkingDirectory(fileItem: FileItem)
  case setParentAsWorkingDirectory(fileItem: FileItem)
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

  /**
    `fileItem` is copied. Children are _not_ populated.
   */
  init(fileItem: FileItem) {
    self.fileItem = fileItem.copy()
  }

  func child(with url: URL) -> FileBrowserItem? {
    return self.children.filter { $0.fileItem.url == url }.first
  }
}

class FileOutlineView: NSOutlineView, Flow, NSOutlineViewDataSource, NSOutlineViewDelegate {

  fileprivate let flow: EmbeddableComponent

  fileprivate var root: FileBrowserItem

  fileprivate let fileItemService: FileItemService

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - API
  var sink: Observable<Any> {
    return self.flow.sink
  }

  var cwd: URL = FileUtils.userHomeUrl

  init(source: Observable<Any>, fileItemService: FileItemService) {
    self.flow = EmbeddableComponent(source: source)
    self.fileItemService = fileItemService

    let rootFileItem = fileItemService.fileItem(for: self.cwd) ?? fileItemService.fileItem(for: FileUtils.userHomeUrl)!
    self.root = FileBrowserItem(fileItem: rootFileItem)

    super.init(frame: CGRect.zero)
    NSOutlineView.configure(toStandard: self)

    self.dataSource = self
    self.delegate = self

    guard Bundle.main.loadNibNamed("FileBrowserMenu", owner: self, topLevelObjects: nil) else {
      NSLog("WARN: FileBrowserMenu.xib could not be loaded")
      return
    }

    self.doubleAction = #selector(FileOutlineView.doubleClickAction)
  }

  func update(_ fileItem: FileItem) {
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
    let newChildren = self.fileItemService.sortedChildren(for: url).map(FileBrowserItem.init)

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
    let childPart = pathComps[rootPathComps.count ..< pathComps.count]

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
    return children.filter { !$0.fileItem.isHidden }
  }

  func outlineView(_: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
    if item == nil {
      let rootFileItem = fileItemService.fileItem(for: self.cwd)
        ?? fileItemService.fileItem(for: FileUtils.userHomeUrl)!
      self.root = FileBrowserItem(fileItem: rootFileItem)
      self.root.children = fileItemService.sortedChildren(for: self.cwd).map(FileBrowserItem.init)

      return self.prepare(self.root.children).count
    }

    guard let fileBrowserItem = item as? FileBrowserItem else {
      return 0
    }

    let fileItem = fileBrowserItem.fileItem
    if fileItem.isDir {
      let fileItemChildren = self.fileItemService.sortedChildren(for: fileItem.url)
      fileBrowserItem.fileItem.children = fileItemChildren
      fileBrowserItem.children = fileItemChildren.map(FileBrowserItem.init)
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
    cell.image = self.fileItemService.icon(forUrl: fileBrowserItem.fileItem.url)

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
      self.flow.publish(event: FileOutlineViewAction.open(fileItem: item.fileItem))
    }
  }

  @IBAction func openInNewTab(_: Any?) {
    guard let item = self.clickedItem as? FileBrowserItem else {
      return
    }

    self.flow.publish(event: FileOutlineViewAction.openFileInNewTab(fileItem: item.fileItem))
  }

  @IBAction func openInCurrentTab(_: Any?) {
    guard let item = self.clickedItem as? FileBrowserItem else {
      return
    }

    self.flow.publish(event: FileOutlineViewAction.openFileInCurrentTab(fileItem: item.fileItem))
  }

  @IBAction func openInHorizontalSplit(_: Any?) {
    guard let item = self.clickedItem as? FileBrowserItem else {
      return
    }

    self.flow.publish(event: FileOutlineViewAction.openFileInHorizontalSplit(fileItem: item.fileItem))
  }

  @IBAction func openInVerticalSplit(_: Any?) {
    guard let item = self.clickedItem as? FileBrowserItem else {
      return
    }

    self.flow.publish(event: FileOutlineViewAction.openFileInVerticalSplit(fileItem: item.fileItem))
  }

  @IBAction func setAsWorkingDirectory(_: Any?) {
    guard let item = self.clickedItem as? FileBrowserItem else {
      return
    }

    guard item.fileItem.isDir else {
      return
    }

    self.flow.publish(event: FileOutlineViewAction.setAsWorkingDirectory(fileItem: item.fileItem))
  }

  @IBAction func setParentAsWorkingDirectory(_: Any?) {
    guard let item = self.clickedItem as? FileBrowserItem else {
      return
    }

    guard self.level(forItem: clickedItem) > 0 else {
      return
    }

    guard item.fileItem.url.path != "/" else {
      return
    }

    self.flow.publish(event: FileOutlineViewAction.setParentAsWorkingDirectory(fileItem: item.fileItem))
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

    if item.action == #selector(setParentAsWorkingDirectory(_:)) {
      return self.level(forItem: clickedItem) > 0
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
        self.flow.publish(event: FileOutlineViewAction.openFileInNewTab(fileItem: item.fileItem))
      }

    default:
      super.keyDown(with: event)
    }
  }
}
