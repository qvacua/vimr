/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import SwiftNeoVim
import PureLayout
import RxSwift

class FileOutlineView: NSOutlineView,
                       UiComponent,
                       NSOutlineViewDataSource,
                       NSOutlineViewDelegate,
                       ThemedView {

  typealias StateType = MainWindow.State

  fileprivate(set) var theme = Theme.default

  required init(source: Observable<StateType>, emitter: ActionEmitter, state: StateType) {
    self.emit = emitter.typedEmit()
    self.uuid = state.uuid

    self.root = FileBrowserItem(state.cwd)
    self.isShowHidden = state.fileBrowserShowHidden

    self.usesTheme = state.appearance.usesTheme
    self.showsFileIcon = state.appearance.showsFileIcon

    super.init(frame: .zero)
    NSOutlineView.configure(toStandard: self)

    self.dataSource = self
    self.delegate = self
    self.allowsEmptySelection = true

    guard Bundle.main.loadNibNamed("FileBrowserMenu", owner: self, topLevelObjects: nil) else {
      NSLog("WARN: FileBrowserMenu.xib could not be loaded")
      return
    }

    // If the target of the menu items is set to the first responder, the actions are not invoked
    // at all when the file monitor fires in the background...
    // Dunno why it worked before the redesign... -_-
    self.menu?.items.forEach { $0.target = self }

    self.doubleAction = #selector(FileOutlineView.doubleClickAction)

    source
      .filter { !self.shouldReloadData(for: $0) }
      .filter { $0.lastFileSystemUpdate.mark != self.lastFileSystemUpdateMark }
      .throttle(2 * FileMonitor.fileSystemEventsLatency + 1,
                latest: true,
                scheduler: SerialDispatchQueueScheduler(qos: .background))
      .observeOn(MainScheduler.instance)
      .subscribe(onNext: { state in
        self.lastFileSystemUpdateMark = state.lastFileSystemUpdate.mark
        self.update(state.lastFileSystemUpdate.payload)
      })
      .disposed(by: self.disposeBag)

    source
      .observeOn(MainScheduler.instance)
      .subscribe(onNext: { state in
        if state.viewToBeFocused != nil, case .fileBrowser = state.viewToBeFocused! {
          self.beFirstResponder()
        }

        let themeChanged = changeTheme(
          themePrefChanged: state.appearance.usesTheme != self.usesTheme,
          themeChanged: state.appearance.theme.mark != self.lastThemeMark,
          usesTheme: state.appearance.usesTheme,
          forTheme: { self.updateTheme(state.appearance.theme) },
          forDefaultTheme: { self.updateTheme(Marked(Theme.default)) })

        self.usesTheme = state.appearance.usesTheme

        guard self.shouldReloadData(for: state, themeChanged: themeChanged) else {
          return
        }

        self.showsFileIcon = state.appearance.showsFileIcon
        self.isShowHidden = state.fileBrowserShowHidden
        self.lastFileSystemUpdateMark = state.lastFileSystemUpdate.mark
        self.root = FileBrowserItem(state.cwd)
        self.reloadData()
      })
      .disposed(by: self.disposeBag)
  }

  func select(_ url: URL) {
    var stack = [self.root]

    while let item = stack.popLast() {
      self.expandItem(item)

      if item.url.isDirectParent(of: url) {
        if let targetItem = item.children.first(where: { $0.url == url }) {
          let targetRow = self.row(forItem: targetItem)
          self.selectRowIndexes(IndexSet(integer: targetRow), byExtendingSelection: false)
          self.scrollRowToVisible(targetRow)
        }

        break
      }

      stack.append(contentsOf: item.children.filter { $0.url.isParent(of: url) })
    }
  }

  fileprivate let emit: (UuidAction<FileBrowser.Action>) -> Void
  fileprivate let disposeBag = DisposeBag()

  fileprivate let uuid: String
  fileprivate var lastFileSystemUpdateMark = Token()
  fileprivate var usesTheme: Bool
  fileprivate var lastThemeMark = Token()
  fileprivate var showsFileIcon: Bool

  fileprivate var cwd: URL {
    return self.root.url
  }
  fileprivate var isShowHidden: Bool

  fileprivate var root: FileBrowserItem

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  fileprivate func updateTheme(_ theme: Marked<Theme>) {
    self.theme = theme.payload
    self.enclosingScrollView?.backgroundColor = self.theme.background
    self.backgroundColor = self.theme.background
    self.lastThemeMark = theme.mark
  }

  fileprivate func shouldReloadData(for state: StateType, themeChanged: Bool = false) -> Bool {
    if self.isShowHidden != state.fileBrowserShowHidden {
      return true
    }

    if themeChanged {
      return true
    }

    if self.showsFileIcon != state.appearance.showsFileIcon {
      return true
    }

    if state.cwd != self.cwd {
      return true
    }

    return false
  }

  fileprivate func update(_ url: URL) {
    guard let fileBrowserItem = self.fileBrowserItem(with: url) else {
      return
    }

    self.update(fileBrowserItem)
  }

  fileprivate func handleRemovals(for fileBrowserItem: FileBrowserItem,
                                  new newChildren: [FileBrowserItem]) {
    let curChildren = fileBrowserItem.children

    let curPreparedChildren = self.prepare(curChildren)
    let newPreparedChildren = self.prepare(newChildren)

    let indicesToRemove = curPreparedChildren
      .enumerated()
      .filter { (_, fileBrowserItem) in newPreparedChildren.contains(fileBrowserItem) == false }
      .map { (idx, _) in idx }

    logger.debug("\(fileBrowserItem): \(curPreparedChildren) vs. \(indicesToRemove)")

    fileBrowserItem.children = curChildren.filter { newChildren.contains($0) }

    let parent = fileBrowserItem == self.root ? nil : fileBrowserItem
    self.removeItems(at: IndexSet(indicesToRemove), inParent: parent)
  }

  fileprivate func handleAdditions(for fileBrowserItem: FileBrowserItem,
                                   new newChildren: [FileBrowserItem]) {
    let curChildren = fileBrowserItem.children

    let curPreparedChildren = self.prepare(curChildren)
    let newPreparedChildren = self.prepare(newChildren)

    let indicesToInsert = newPreparedChildren
      .enumerated()
      .filter { (_, fileBrowserItem) in curPreparedChildren.contains(fileBrowserItem) == false }
      .map { (idx, _) in idx }

    logger.debug("\(fileBrowserItem): \(curPreparedChildren) vs. \(indicesToInsert)")

    // We don't just take newChildren because NSOutlineView look at the pointer equality for
    // preserving the expanded states...
    fileBrowserItem.children = newChildren.substituting(elements: curChildren)

    let parent = fileBrowserItem == self.root ? nil : fileBrowserItem
    self.insertItems(at: IndexSet(indicesToInsert), inParent: parent)
  }

  fileprivate func sortedChildren(of url: URL) -> [FileBrowserItem] {
    return FileUtils.directDescendants(of: url).map(FileBrowserItem.init).sorted()
  }

  fileprivate func update(_ fileBrowserItem: FileBrowserItem) {
    let url = fileBrowserItem.url

    // Sort the array to keep the order.
    let newChildren = self.sortedChildren(of: url)

    self.beginUpdates()
    self.handleRemovals(for: fileBrowserItem, new: newChildren)
    self.endUpdates()

    self.beginUpdates()
    self.handleAdditions(for: fileBrowserItem, new: newChildren)
    self.endUpdates()

    fileBrowserItem.isChildrenScanned = true

    fileBrowserItem.children.filter { self.isItemExpanded($0) }.forEach(self.update)
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

      return parent.child(with: parent.url.appendingPathComponent(childName))
    }
  }
}

// MARK: - NSOutlineViewDataSource
extension FileOutlineView {

  fileprivate func scanChildrenIfNecessary(_ fileBrowserItem: FileBrowserItem) {
    guard fileBrowserItem.isChildrenScanned == false else {
      return
    }

    fileBrowserItem.children = self.sortedChildren(of: fileBrowserItem.url)
    fileBrowserItem.isChildrenScanned = true
  }

  fileprivate func prepare(_ children: [FileBrowserItem]) -> [FileBrowserItem] {
    return self.isShowHidden ? children : children.filter { !$0.isHidden }
  }

  func outlineView(_: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
    if item == nil {
      self.scanChildrenIfNecessary(self.root)

      return self.prepare(self.root.children).count
    }

    guard let fileBrowserItem = item as? FileBrowserItem else {
      return 0
    }

    if fileBrowserItem.url.isDir {
      self.scanChildrenIfNecessary(fileBrowserItem)
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

    return fileBrowserItem.url.isDir
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

      // + 2 just to have a buffer... -_-
      return ThemedTableCell.width(with: fileBrowserItem.url.lastPathComponent)
             + (CGFloat($0.level + 2) * (self.indentationPerLevel + 2))
    }.max() ?? column.width

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
      let result = ThemedTableCell.width(with: $0.url.lastPathComponent)
      return result
    }.max() ?? column.width

    // + 2 just to have a buffer... -_-
    let width = cellWidth + (CGFloat(level + 2) * (self.indentationPerLevel + 2))

    guard column.minWidth < width else {
      return
    }

    column.minWidth = width
    column.maxWidth = width
  }
}

// MARK: - NSOutlineViewDelegate
extension FileOutlineView {

  func outlineView(_ outlineView: NSOutlineView, rowViewForItem item: Any) -> NSTableRowView? {
    return self.make(withIdentifier: "file-row-view", owner: self) as? ThemedTableRow
           ?? ThemedTableRow(withIdentifier: "file-row-view", themedView: self)
  }

  func outlineView(_: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
    guard let fileBrowserItem = item as? FileBrowserItem else {
      return nil
    }

    let cell = (self.make(withIdentifier: "file-cell-view", owner: self) as? ThemedTableCell)?.reset()
               ?? ThemedTableCell(withIdentifier: "file-cell-view")

    cell.isDir = fileBrowserItem.isDir
    cell.text = fileBrowserItem.url.lastPathComponent

    guard self.showsFileIcon else {
      return cell
    }

    let icon = FileUtils.icon(forUrl: fileBrowserItem.url)
    cell.image = fileBrowserItem.isHidden ? icon?.tinting(with: NSColor.white.withAlphaComponent(0.4)) : icon

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

    if item.url.isDir {
      self.toggle(item: item)
    } else {
      self.emit(
        UuidAction(uuid: self.uuid, action: .open(url: item.url, mode: .default))
      )
    }
  }

  @IBAction func openInNewTab(_: Any?) {
    guard let item = self.clickedItem as? FileBrowserItem else {
      return
    }

    self.emit(
      UuidAction(uuid: self.uuid, action: .open(url: item.url, mode: .newTab))
    )
  }

  @IBAction func openInCurrentTab(_: Any?) {
    guard let item = self.clickedItem as? FileBrowserItem else {
      return
    }

    self.emit(
      UuidAction(uuid: self.uuid, action: .open(url: item.url, mode: .currentTab))
    )
  }

  @IBAction func openInHorizontalSplit(_: Any?) {
    guard let item = self.clickedItem as? FileBrowserItem else {
      return
    }

    self.emit(
      UuidAction(uuid: self.uuid, action: .open(url: item.url, mode: .horizontalSplit))
    )
  }

  @IBAction func openInVerticalSplit(_: Any?) {
    guard let item = self.clickedItem as? FileBrowserItem else {
      return
    }

    self.emit(
      UuidAction(uuid: self.uuid, action: .open(url: item.url, mode: .verticalSplit))
    )
  }

  @IBAction func setAsWorkingDirectory(_: Any?) {
    guard let item = self.clickedItem as? FileBrowserItem else {
      return
    }

    guard item.url.isDir else {
      return
    }

    self.emit(
      UuidAction(uuid: self.uuid, action: .setAsWorkingDirectory(item.url))
    )
  }
}

// MARK: - NSUserInterfaceValidations
extension FileOutlineView {

  override func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
    guard let clickedItem = self.clickedItem as? FileBrowserItem else {
      return true
    }

    if item.action == #selector(setAsWorkingDirectory(_:)) {
      return clickedItem.url.isDir
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
      if item.url.isDir || item.url.isPackage {
        self.toggle(item: item)
      } else {
        self.emit(
          UuidAction(uuid: self.uuid, action: .open(url: item.url, mode: .newTab))
        )
      }

    default:
      super.keyDown(with: event)
    }
  }
}

fileprivate class FileBrowserItem: Hashable, Comparable, CustomStringConvertible {

  static func ==(left: FileBrowserItem, right: FileBrowserItem) -> Bool {
    return left.url == right.url
  }

  static func <(left: FileBrowserItem, right: FileBrowserItem) -> Bool {
    return left.url.lastPathComponent < right.url.lastPathComponent
  }

  var hashValue: Int {
    return self.url.hashValue
  }

  var description: String {
    return self.url.path
  }

  let url: URL
  let isDir: Bool
  let isHidden: Bool
  var children: [FileBrowserItem] = []
  var isChildrenScanned = false

  init(_ url: URL) {
    self.url = url

    // We cache the value here since we often get the value when the file is not there, eg when
    // updating because the file gets deleted (in self.prepare() function)
    self.isHidden = url.isHidden
    self.isDir = url.isDir
  }

  func child(with url: URL) -> FileBrowserItem? {
    return self.children.first { $0.url == url }
  }
}
