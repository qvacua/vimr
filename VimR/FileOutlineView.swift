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
  var isExpanded = false

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

    let rootFileItem = fileItemService.fileItemWithChildren(for: self.cwd)
        ?? fileItemService.fileItemWithChildren(for: FileUtils.userHomeUrl)!
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

    Swift.print("got \(fileBrowserItem) to update")
    self.update(fileBrowserItem)
  }

  fileprivate func update(_ fileBrowserItem: FileBrowserItem) {
    let url = fileBrowserItem.fileItem.url

    // Sort the arrays to keep the order.
    let curChildren = fileBrowserItem.children.sorted()
    let newChildren = (self.fileItemService.fileItemWithChildren(for: url)?.children ?? [])
        .map(FileBrowserItem.init)
        .sorted()

    let curPreparedChildren = self.prepare(curChildren)
    let newPreparedChildren = self.prepare(newChildren)

    // Handle removals.
    let childrenToRemoveIndices = curPreparedChildren
        .enumerated()
        .filter { newPreparedChildren.contains($0.1) == false }
        .map { $0.0 }
    self.removeItems(at: IndexSet(childrenToRemoveIndices), inParent: fileBrowserItem)
    fileBrowserItem.children = curChildren.filter { newChildren.contains($0) }

    // Handle additions.

    // Handle children.
    let keptChildren = curChildren.filter { newChildren.contains($0) }

//    let childrenToAdd = newChildren.filter { curChildren.contains($0) == false }
//    let resultChildren = childrenToAdd.add(keptChildren)
//    fileBrowserItem.children = Array(resultChildren)
//    Swift.print("new resulting children: \(resultChildren)")

    let childrenToRecurse = keptChildren.filter { self.isItemExpanded(self.fileBrowserItem(with: $0.fileItem.url)) }
    Swift.print("to recurse: \(childrenToRecurse)")

//    self.reloadItem(fileBrowserItem, reloadChildren: false)

    childrenToRecurse.forEach(self.update)
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
    return children.filter { !$0.fileItem.isHidden }.sorted()
  }

  func outlineView(_: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
    if item == nil {
      let rootFileItem = fileItemService.fileItemWithChildren(for: self.cwd)
          ?? fileItemService.fileItemWithChildren(for: FileUtils.userHomeUrl)!
      self.root = FileBrowserItem(fileItem: rootFileItem)
      self.root.children = rootFileItem.children.map(FileBrowserItem.init)

      return self.prepare(self.root.children).count
    }

    guard let fileBrowserItem = item as? FileBrowserItem else {
      return 0
    }

    let fileItem = fileBrowserItem.fileItem
    if fileItem.isDir {
      let fileItemChildren = self.fileItemService.fileItemWithChildren(for: fileItem.url)?.children ?? []
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

  fileprivate func adjustColumnWidth(for items: [FileBrowserItem], outlineViewLevel level: Int) {
    let cellWidth = items.reduce(CGFloat(0)) { (curMaxWidth, item) in
      let itemWidth = ImageAndTextTableCell.width(with: item.fileItem.url.lastPathComponent)
      if itemWidth > curMaxWidth {
        return itemWidth
      }

      return curMaxWidth
    }

    let width = cellWidth + (CGFloat(level + 2) * (self.indentationPerLevel + 2)) // + 2 just to have a buffer... -_-
    let column = self.outlineTableColumn!
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

    let cachedCell = self.make(withIdentifier: "file-view-row", owner: self)
    let cell = cachedCell as? ImageAndTextTableCell ?? ImageAndTextTableCell(withIdentifier: "file-view-row")

    cell.text = fileBrowserItem.fileItem.url.lastPathComponent
    cell.image = self.fileItemService.icon(forUrl: fileBrowserItem.fileItem.url)

    return cell
  }

  func outlineView(_: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat {
    return 20
  }

  func outlineViewItemDidExpand(_ notification: Notification) {
    if let item = notification.userInfo?["NSObject"] as? FileBrowserItem {
      item.isExpanded = true
    }
  }

  func outlineViewItemDidCollapse(_ notification: Notification) {
    if let item = notification.userInfo?["NSObject"] as? FileBrowserItem {
      item.isExpanded = false
    }
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
