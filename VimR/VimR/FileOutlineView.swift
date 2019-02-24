/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import NvimView
import PureLayout
import RxSwift

class FileOutlineView: NSOutlineView,
                       UiComponent,
                       NSOutlineViewDelegate,
                       ThemedView {

  typealias StateType = MainWindow.State

  @objc dynamic var content = [Node]()
  private(set) var theme = Theme.default

  required init(
    source: Observable<StateType>,
    emitter: ActionEmitter,
    state: StateType
  ) {
    self.emit = emitter.typedEmit()
    self.uuid = state.uuid
    self.root = Node(url: state.cwd)
    self.usesTheme = state.appearance.usesTheme
    self.showsFileIcon = state.appearance.showsFileIcon
    self.isShowHidden = state.fileBrowserShowHidden

    super.init(frame: .zero)

    NSOutlineView.configure(toStandard: self)
    self.delegate = self

    // Load context menu.
    // This will set self.menu.
    guard Bundle.main.loadNibNamed(
      NSNib.Name("FileBrowserMenu"),
      owner: self,
      topLevelObjects: nil
    ) else {
      NSLog("WARN: FileBrowserMenu.xib could not be loaded")
      return
    }
    self.menu?.items.forEach { $0.target = self }
    self.doubleAction = #selector(FileOutlineViewOld.doubleClickAction)

    source
      .observeOn(MainScheduler.instance)
      .subscribe(onNext: { state in
        if state.viewToBeFocused != nil,
           case .fileBrowser = state.viewToBeFocused! {
          self.beFirstResponder()
        }

        let themeChanged = changeTheme(
          themePrefChanged: state.appearance.usesTheme != self.usesTheme,
          themeChanged: state.appearance.theme.mark != self.lastThemeMark,
          usesTheme: state.appearance.usesTheme,
          forTheme: { self.updateTheme(state.appearance.theme) },
          forDefaultTheme: { self.updateTheme(Marked(Theme.default)) })

        self.usesTheme = state.appearance.usesTheme

        guard self.shouldReloadData(
          for: state, themeChanged: themeChanged
        ) else {
          return
        }

        self.showsFileIcon = state.appearance.showsFileIcon
        self.isShowHidden = state.fileBrowserShowHidden
        self.lastFileSystemUpdateMark = state.lastFileSystemUpdate.mark
        self.root = Node(url: state.cwd)
        self.reloadRoot()
      })
      .disposed(by: self.disposeBag)

    self.treeController.childrenKeyPath = "children"
    self.treeController.leafKeyPath = "isLeaf"
    self.treeController.countKeyPath = "childrenCount"
    self.treeController.objectClass = Node.self
    self.treeController.avoidsEmptySelection = false
    self.treeController.sortDescriptors = [
      NSSortDescriptor(key: "isLeaf", ascending: true), // Folders first,
      NSSortDescriptor(key: "displayName", ascending: true) // then, name
    ]
    self.treeController.bind(.contentArray, to: self, withKeyPath: "content")
    self.bind(.content, to: self.treeController, withKeyPath: "arrangedObjects")
    self.bind(.selectionIndexPaths,
              to: self.treeController,
              withKeyPath: "selectionIndexPaths")

    self.reloadRoot()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private let emit: (UuidAction<FileBrowser.Action>) -> Void
  private let disposeBag = DisposeBag()

  private let uuid: String

  private var root: Node
  private var cwd: URL {
    return self.root.url
  }
  private let treeController = NSTreeController()

  private var cachedColumnWidth = CGFloat(20)
  private var usesTheme: Bool
  private var lastThemeMark = Token()
  private var lastFileSystemUpdateMark = Token()
  private var showsFileIcon: Bool
  private var isShowHidden: Bool

  private func childNodes(for node: Node) -> [Node] {
    if node.isChildrenScanned {
      return node.children ?? []
    }

    let nodes = FileUtils
      .directDescendants(of: node.url)
      .map { Node(url: $0) }

    if self.isShowHidden {
      return nodes
    }

    return nodes.filter { !$0.isHidden }
  }

  private func reloadRoot() {
    let children = self.childNodes(for: self.root)

    self.root.children = children
    self.content.removeAll()
    self.content.append(contentsOf: children)
  }

  private func updateTheme(_ theme: Marked<Theme>) {
    self.theme = theme.payload
    self.enclosingScrollView?.backgroundColor = self.theme.background
    self.backgroundColor = self.theme.background
    self.lastThemeMark = theme.mark
  }

  private func shouldReloadData(
    for state: StateType, themeChanged: Bool = false
  ) -> Bool {
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

  private func node(from item: Any?) -> Node? {
    return (item as? NSTreeNode)?.representedObject as? Node
  }
}

// MARK: - Actions
extension FileOutlineView {

  @IBAction func doubleClickAction(_: Any?) {
    guard let node = self.node(from: self.clickedItem) else {
      return
    }

    if node.url.isDir {
      self.toggle(item: node)
    } else {
      self.emit(
        UuidAction(uuid: self.uuid,
                   action: .open(url: node.url, mode: .default))
      )
    }
  }

  @IBAction func openInNewTab(_: Any?) {
    guard let node = self.node(from: self.clickedItem) else {
      return
    }

    self.emit(
      UuidAction(uuid: self.uuid, action: .open(url: node.url, mode: .newTab))
    )
  }

  @IBAction func openInCurrentTab(_: Any?) {
    guard let node = self.node(from: self.clickedItem) else {
      return
    }

    self.emit(
      UuidAction(uuid: self.uuid,
                 action: .open(url: node.url, mode: .currentTab))
    )
  }

  @IBAction func openInHorizontalSplit(_: Any?) {
    guard let node = self.node(from: self.clickedItem) else {
      return
    }

    self.emit(
      UuidAction(uuid: self.uuid,
                 action: .open(url: node.url, mode: .horizontalSplit))
    )
  }

  @IBAction func openInVerticalSplit(_: Any?) {
    guard let node = self.node(from: self.clickedItem) else {
      return
    }

    self.emit(
      UuidAction(uuid: self.uuid,
                 action: .open(url: node.url, mode: .verticalSplit))
    )
  }

  @IBAction func setAsWorkingDirectory(_: Any?) {
    guard let node = self.node(from: self.clickedItem) else {
      return
    }

    guard node.url.isDir else {
      return
    }

    self.emit(
      UuidAction(uuid: self.uuid, action: .setAsWorkingDirectory(node.url))
    )
  }
}

// MARK: - NSOutlineViewDelegate
extension FileOutlineView {

  func outlineView(
    _ outlineView: NSOutlineView,
    rowViewForItem item: Any
  ) -> NSTableRowView? {
    return self.makeView(
      withIdentifier: NSUserInterfaceItemIdentifier("file-row-view"),
      owner: self
    ) as? ThemedTableRow ?? ThemedTableRow(withIdentifier: "file-row-view",
                                           themedView: self)
  }

  func outlineView(
    _: NSOutlineView,
    viewFor tableColumn: NSTableColumn?,
    item: Any
  ) -> NSView? {
    guard let node = self.node(from: item) else {
      return nil
    }

    let cellView = self.makeView(
      withIdentifier: NSUserInterfaceItemIdentifier("file-cell-view"),
      owner: self
    ) as? ThemedTableCell ?? ThemedTableCell(withIdentifier: "file-cell-view")

    cellView.isDir = node.isDir
    cellView.text = node.displayName

    let icon = FileUtils.icon(forUrl: node.url)
    cellView.image = node.isHidden
      ? icon?.tinting(with: NSColor.white.withAlphaComponent(0.4))
      : icon

    return cellView
  }

  func outlineView(_: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat {
    return 20
  }

  func outlineView(
    _ outlineView: NSOutlineView,
    shouldExpandItem item: Any
  ) -> Bool {
    guard let node = self.node(from: item) else {
      return false
    }

    if node.isChildrenScanned {
      return true
    }

    node.children = FileUtils.directDescendants(of: node.url).map { url in
      return Node(url: url)
    }

    return true
  }

  func outlineView(
    _ outlineView: NSOutlineView,
    didAdd rowView: NSTableRowView,
    forRow row: Int
  ) {
    guard let cellWidth = (rowView.view(atColumn: 0) as? NSTableCellView)?
      .fittingSize.width
      else {
      return
    }

    let level = CGFloat(self.level(forRow: row))
    let width = level * self.indentationPerLevel + cellWidth
                + columnWidthRightPadding
    self.cachedColumnWidth = max(self.cachedColumnWidth, width)
    self.tableColumns[0].width = cachedColumnWidth
  }
}

// MARK: - NSUserInterfaceValidations
extension FileOutlineView {

  override func validateUserInterfaceItem(
    _ item: NSValidatedUserInterfaceItem
  ) -> Bool {
    guard let clickedNode = self.node(from: self.clickedItem) else {
      return true
    }

    if item.action == #selector(setAsWorkingDirectory(_:)) {
      return clickedNode.url.isDir
    }

    return true
  }
}

class Node: NSObject {

  @objc dynamic var url: URL
  @objc dynamic var isLeaf: Bool
  @objc dynamic var isHidden: Bool
  @objc dynamic var children: [Node]?

  @objc dynamic var childrenCount: Int {
    return self.children?.count ?? -1
  }
  @objc dynamic var displayName: String {
    return self.url.lastPathComponent
  }

  var isDir: Bool {
    return !self.isLeaf
  }
  var isChildrenScanned = false

  override var hash: Int {
    return self.url.hashValue
  }

  init(url: URL) {
    self.url = url
    self.isLeaf = !url.isDir
    self.isHidden = url.isHidden
  }
}

// MARK: - OLD
class FileOutlineViewOld: NSOutlineView,
                          UiComponent,
                          NSOutlineViewDataSource,
                          NSOutlineViewDelegate,
                          ThemedView {

  typealias StateType = MainWindow.State

  private(set) var theme = Theme.default

  required init(
    source: Observable<StateType>,
    emitter: ActionEmitter,
    state: StateType) {

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

    guard Bundle.main.loadNibNamed(
      NSNib.Name("FileBrowserMenu"),
      owner: self,
      topLevelObjects: nil
    ) else {
      NSLog("WARN: FileBrowserMenu.xib could not be loaded")
      return
    }

    // If the target of the menu items is set to the first responder,
    // the actions are not invoked at all when the file monitor fires
    // in the background... Dunno why it worked before the redesign... -_-
    self.menu?.items.forEach { $0.target = self }

    self.doubleAction = #selector(FileOutlineViewOld.doubleClickAction)

    source
      .filter { !self.shouldReloadData(for: $0) }
      .filter { $0.lastFileSystemUpdate.mark != self.lastFileSystemUpdateMark }
      .throttle(2 * FileMonitor.fileSystemEventsLatency + 1,
                latest: true,
                scheduler: SerialDispatchQueueScheduler(qos: .background))
      .observeOn(MainScheduler.instance)
      .subscribe(onNext: { state in
        self.lastFileSystemUpdateMark = state.lastFileSystemUpdate.mark
        guard let fileBrowserItem = self.fileBrowserItem(
          with: state.lastFileSystemUpdate.payload
        ) else {
          return
        }

        self.update(fileBrowserItem)
      })
      .disposed(by: self.disposeBag)

    source
      .observeOn(MainScheduler.instance)
      .subscribe(onNext: { state in
        if state.viewToBeFocused != nil,
           case .fileBrowser = state.viewToBeFocused! {
          self.beFirstResponder()
        }

        let themeChanged = changeTheme(
          themePrefChanged: state.appearance.usesTheme != self.usesTheme,
          themeChanged: state.appearance.theme.mark != self.lastThemeMark,
          usesTheme: state.appearance.usesTheme,
          forTheme: { self.updateTheme(state.appearance.theme) },
          forDefaultTheme: { self.updateTheme(Marked(Theme.default)) })

        self.usesTheme = state.appearance.usesTheme

        guard self.shouldReloadData(
          for: state, themeChanged: themeChanged
        ) else {
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

  override func reloadData() {
    self.cells.removeAll()
    self.widths.removeAll()
    super.reloadData()
  }

  func select(_ url: URL) {
    var stack = [self.root]

    while let item = stack.popLast() {
      self.expandItem(item)

      if item.url.isDirectParent(of: url) {
        if let targetItem = item.children.first(where: { $0.url == url }) {
          let targetRow = self.row(forItem: targetItem)
          self.selectRowIndexes(
            IndexSet(integer: targetRow), byExtendingSelection: false
          )
          self.scrollRowToVisible(targetRow)
        }

        break
      }

      stack.append(contentsOf: item.children.filter {
        $0.url.isParent(of: url)
      })
    }
  }

  private let emit: (UuidAction<FileBrowser.Action>) -> Void
  private let disposeBag = DisposeBag()

  private let uuid: String
  private var lastFileSystemUpdateMark = Token()
  private var usesTheme: Bool
  private var lastThemeMark = Token()
  private var showsFileIcon: Bool

  private var cwd: URL {
    return self.root.url
  }
  private var isShowHidden: Bool

  private var root: FileBrowserItem

  private var widths = [String: CGFloat]()
  private var cells = [String: ThemedTableCell]()

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func updateTheme(_ theme: Marked<Theme>) {
    self.theme = theme.payload
    self.enclosingScrollView?.backgroundColor = self.theme.background
    self.backgroundColor = self.theme.background
    self.lastThemeMark = theme.mark
  }

  private func shouldReloadData(
    for state: StateType, themeChanged: Bool = false
  ) -> Bool {
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

  private func handleRemovals(for fileBrowserItem: FileBrowserItem,
                              new newChildren: [FileBrowserItem]) {
    let curChildren = fileBrowserItem.children

    let curPreparedChildren = self.prepare(curChildren)
    let newPreparedChildren = self.prepare(newChildren)

    let indicesToRemove = curPreparedChildren
      .enumerated()
      .filter { (_, fileBrowserItem) in
        newPreparedChildren.contains(fileBrowserItem) == false
      }
      .map { (idx, _) in idx }

    indicesToRemove.forEach { index in
      let path = curPreparedChildren[index].url.path

      self.cells.removeValue(forKey: path)
      self.widths.removeValue(forKey: path)
    }

    fileBrowserItem.children = curChildren.filter { newChildren.contains($0) }

    let parent = fileBrowserItem == self.root ? nil : fileBrowserItem
    self.removeItems(at: IndexSet(indicesToRemove), inParent: parent)
  }

  private func handleAdditions(for fileBrowserItem: FileBrowserItem,
                               new newChildren: [FileBrowserItem]) {
    let curChildren = fileBrowserItem.children

    let curPreparedChildren = self.prepare(curChildren)
    let newPreparedChildren = self.prepare(newChildren)

    let indicesToInsert = newPreparedChildren
      .enumerated()
      .filter { (_, fileBrowserItem) in
        curPreparedChildren.contains(fileBrowserItem) == false
      }
      .map { (idx, _) in idx }

    // We don't just take newChildren because NSOutlineView look
    // at the pointer equality for preserving the expanded states...
    fileBrowserItem.children = newChildren.substituting(elements: curChildren)

    let parent = fileBrowserItem == self.root ? nil : fileBrowserItem
    self.insertItems(at: IndexSet(indicesToInsert), inParent: parent)
  }

  private func sortedChildren(of url: URL) -> [FileBrowserItem] {
    return FileUtils.directDescendants(of: url)
      .map(FileBrowserItem.init).sorted {
        if ($0.isDir == $1.isDir) {
          return $0.url.absoluteString < $1.url.absoluteString
        }

        return $0.isDir
      }
  }

  private func update(_ fileBrowserItem: FileBrowserItem) {
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

    fileBrowserItem.children
      .filter { self.isItemExpanded($0) }
      .forEach(self.update)
  }

  private func fileBrowserItem(with url: URL) -> FileBrowserItem? {
    if self.cwd == url {
      return self.root
    }

    guard self.cwd.isParent(of: url) else {
      return nil
    }

    let rootPathComps = self.cwd.pathComponents
    let pathComps = url.pathComponents
    let childPart = pathComps[rootPathComps.count..<pathComps.count]

    return childPart
      .reduce(self.root) { (resultItem, childName) -> FileBrowserItem? in
      guard let parent = resultItem else {
        return nil
      }

      return parent.child(with: parent.url.appendingPathComponent(childName))
    }
  }
}

// MARK: - NSOutlineViewDataSource
extension FileOutlineViewOld {

  private func scanChildrenIfNecessary(_ fileBrowserItem: FileBrowserItem) {
    guard fileBrowserItem.isChildrenScanned == false else {
      return
    }

    fileBrowserItem.children = self.sortedChildren(of: fileBrowserItem.url)
    fileBrowserItem.isChildrenScanned = true
  }

  private func prepare(_ children: [FileBrowserItem]) -> [FileBrowserItem] {
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

  func outlineView(
    _: NSOutlineView, child index: Int, ofItem item: Any?
  ) -> Any {
    let level = self.level(forItem: item) + 2
    defer { self.adjustColumnWidths() }

    if item == nil {
      let child = self.prepare(self.root.children)[index]

      let cell = self.cell(forItem: child)
      self.cells[child.url.path] = cell
      self.widths[child.url.path] = self.cellWidth(for: cell, level: level)

      return child
    }

    guard let fileBrowserItem = item as? FileBrowserItem else {
      preconditionFailure("Should not happen")
    }

    let child = self.prepare(fileBrowserItem.children)[index]

    let cell = self.cell(forItem: child)
    self.cells[child.url.path] = cell
    self.widths[child.url.path] = self.cellWidth(for: cell, level: level)

    return child
  }

  private func cell(forItem item: FileBrowserItem) -> ThemedTableCell {
    if let existingCell = self.cells[item.url.path] {
      return existingCell
    }

    let cell = ThemedTableCell(withIdentifier: "file-cell-view")

    cell.isDir = item.isDir
    cell.text = item.url.lastPathComponent

    if self.showsFileIcon {
      let icon = FileUtils.icon(forUrl: item.url)
      cell.image = cell.isHidden
        ? icon?.tinting(with: NSColor.white.withAlphaComponent(0.4))
        : icon
    }

    return cell
  }

  func outlineView(_: NSOutlineView, isItemExpandable item: Any) -> Bool {
    guard let fileBrowserItem = item as? FileBrowserItem else {
      return false
    }
    return fileBrowserItem.url.isDir
  }

  @objc(outlineView:objectValueForTableColumn:byItem:)
  func outlineView(_: NSOutlineView,
                   objectValueFor: NSTableColumn?,
                   byItem item: Any?) -> Any? {

    guard let fileBrowserItem = item as? FileBrowserItem else {
      return nil
    }

    return fileBrowserItem
  }

  private func cellWidth(for cell: NSView?, level: Int) -> CGFloat {
    let cellWidth = cell?.intrinsicContentSize.width ?? 0
    let indentation = CGFloat(level + 1) * self.indentationPerLevel + 4
    return cellWidth + indentation
  }

  private func adjustColumnWidths() {
    guard let column = self.outlineTableColumn else {
      return
    }

    column.minWidth = self.widths.values.max() ?? 100
    column.maxWidth = self.widths.values.max() ?? 100
  }
}

// MARK: - NSOutlineViewDelegate
extension FileOutlineViewOld {

  func outlineView(
    _ outlineView: NSOutlineView, rowViewForItem item: Any
  ) -> NSTableRowView? {
    return self.makeView(
      withIdentifier: NSUserInterfaceItemIdentifier("file-row-view"),
      owner: self
    ) as? ThemedTableRow ?? ThemedTableRow(withIdentifier: "file-row-view",
                                           themedView: self)
  }

  func outlineView(
    _: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any
  ) -> NSView? {
    guard let fileBrowserItem = item as? FileBrowserItem else {
      return nil
    }

    return self.cells[fileBrowserItem.url.path]
  }

  func outlineView(_: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat {
    return 20
  }
}

// MARK: - Actions
extension FileOutlineViewOld {

  @IBAction func doubleClickAction(_: Any?) {
    guard let item = self.clickedItem as? FileBrowserItem else {
      return
    }

    if item.url.isDir {
      self.toggle(item: item)
    } else {
      self.emit(
        UuidAction(uuid: self.uuid,
                   action: .open(url: item.url, mode: .default))
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
      UuidAction(uuid: self.uuid,
                 action: .open(url: item.url, mode: .currentTab))
    )
  }

  @IBAction func openInHorizontalSplit(_: Any?) {
    guard let item = self.clickedItem as? FileBrowserItem else {
      return
    }

    self.emit(
      UuidAction(uuid: self.uuid,
                 action: .open(url: item.url, mode: .horizontalSplit))
    )
  }

  @IBAction func openInVerticalSplit(_: Any?) {
    guard let item = self.clickedItem as? FileBrowserItem else {
      return
    }

    self.emit(
      UuidAction(uuid: self.uuid,
                 action: .open(url: item.url, mode: .verticalSplit))
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
extension FileOutlineViewOld {

  override func validateUserInterfaceItem(
    _ item: NSValidatedUserInterfaceItem
  ) -> Bool {
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
extension FileOutlineViewOld {

  override func keyDown(with event: NSEvent) {
    guard let char = event.charactersIgnoringModifiers?.first else {
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
          UuidAction(uuid: self.uuid,
                     action: .open(url: item.url, mode: .newTab))
        )
      }

    default:
      super.keyDown(with: event)
    }
  }
}

private class FileBrowserItem: Hashable, Comparable, CustomStringConvertible {

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

    // We cache the value here since we often get the value when the file is
    // not there, eg when updating because the file gets deleted
    // (in self.prepare() function)
    self.isHidden = url.isHidden
    self.isDir = url.isDir
  }

  func child(with url: URL) -> FileBrowserItem? {
    return self.children.first { $0.url == url }
  }
}

private let columnWidthRightPadding = CGFloat(40)
