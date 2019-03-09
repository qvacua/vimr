/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import NvimView
import PureLayout
import RxSwift
import CocoaFontAwesome
import os

class FileOutlineView: NSOutlineView,
                       UiComponent,
                       NSOutlineViewDelegate,
                       ThemedView {

  typealias StateType = MainWindow.State

  @objc dynamic var content = [Node]()

  private(set) var lastThemeMark = Token()
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
    self.triangleClosed = NSImage.fontAwesomeIcon(
      name: .caretRight,
      style: .solid,
      textColor: self.theme.directoryForeground,
      dimension: triangleImageSize
    )
    self.triangleOpen = NSImage.fontAwesomeIcon(
      name: .caretDown,
      style: .solid,
      textColor: self.theme.directoryForeground,
      dimension: triangleImageSize
    )

    super.init(frame: .zero)

    NSOutlineView.configure(toStandard: self)
    self.delegate = self

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

    source
      .filter { !self.shouldReloadData(for: $0) }
      .filter { $0.lastFileSystemUpdate.mark != self.lastFileSystemUpdateMark }
      .map { $0.lastFileSystemUpdate.payload }
      .throttle(2 * FileMonitor.fileSystemEventsLatency + 1,
                latest: true,
                scheduler: SerialDispatchQueueScheduler(qos: .background))
      .map { ($0, Set(self.childUrls(for: $0))) }
      .observeOn(MainScheduler.instance)
      .subscribe(onNext: { (url, newChildUrls) in
        guard let changeTreeNode = self.changeRootTreeNode(for: url) else {
          return
        }

        self.handleRemoval(changeTreeNode: changeTreeNode,
                           newChildUrls: newChildUrls)
        self.handleAddition(changeTreeNode: changeTreeNode,
                            newChildUrls: newChildUrls)
      })
      .disposed(by: self.disposeBag)

    self.initContextMenu()
    self.initBindings()
    self.reloadRoot()
  }

  // We cannot use outlineView(_:willDisplayOutlineCell:for:item:) delegate
  // method to customize the disclosure triangle in a view-based
  // NSOutlineView.
  // See https://stackoverflow.com/a/20454413/9850227
  override func makeView(
    withIdentifier identifier: NSUserInterfaceItemIdentifier, owner: Any?
  ) -> NSView? {
    let result = super.makeView(withIdentifier: identifier, owner: owner)

    if identifier == NSOutlineView.disclosureButtonIdentifier {
      let triangleButton = result as? NSButton
      triangleButton?.image = self.triangleClosed
      triangleButton?.alternateImage = self.triangleOpen
    }

    return result
  }

  func select(_ url: URL) {
    guard let childrenOfRoot = self.treeController.arrangedObjects.children
      else { return }

    var stack = [NSTreeNode]()

    // NSTreeController.arrangedObjects has no Node.
    for childOfRoot in childrenOfRoot {
      guard let node = childOfRoot.node else { continue }

      if node.url == url {
        self.select(treeNode: childOfRoot)
        return
      }

      if node.url.isParent(of: url) {
        self.expandItem(childOfRoot)
        stack.append(contentsOf: childOfRoot.children ?? [])
        break
      }
    }

    while let item = stack.popLast() {
      self.expandItem(item)

      guard let node = item.node else { continue }
      if node.url == url {
        self.select(treeNode: item)
        return
      }

      if node.url.isParent(of: url) {
        stack.append(contentsOf: item.children ?? [])
      }
    }
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private let emit: (UuidAction<FileBrowser.Action>) -> Void
  private let disposeBag = DisposeBag()

  private let uuid: UUID

  private var root: Node
  private var cwd: URL {
    return self.root.url
  }
  private let treeController = NSTreeController()

  private var cachedColumnWidth = CGFloat(20)
  private var usesTheme: Bool
  private var lastFileSystemUpdateMark = Token()
  private var showsFileIcon: Bool
  private var isShowHidden: Bool

  private var triangleClosed: NSImage
  private var triangleOpen: NSImage

  private let log = OSLog(subsystem: Defs.loggerSubsystem,
                          category: Defs.LoggerCategory.uiComponents)

  private func initContextMenu() {
    // Loading the nib file will set self.menu.
    guard Bundle.main.loadNibNamed(
      NSNib.Name("FileBrowserMenu"),
      owner: self,
      topLevelObjects: nil
    ) else {
      self.log.error("FileBrowserMenu.xib could not be loaded")
      return
    }
    self.menu?.items.forEach { $0.target = self }
    self.doubleAction = #selector(FileOutlineView.doubleClickAction)
  }

  private func initBindings() {
    self.treeController.childrenKeyPath = "children"
    self.treeController.leafKeyPath = "isLeaf"
    self.treeController.countKeyPath = "childrenCount"
    self.treeController.objectClass = Node.self
    self.treeController.avoidsEmptySelection = false
    self.treeController.preservesSelection = true
    self.treeController.sortDescriptors = [
      NSSortDescriptor(key: "isLeaf", ascending: true), // Folders first,
      NSSortDescriptor(key: "displayName", ascending: true) // then, name
    ]
    self.treeController.bind(.contentArray, to: self, withKeyPath: "content")
    self.bind(.content, to: self.treeController, withKeyPath: "arrangedObjects")
    self.bind(.selectionIndexPaths,
              to: self.treeController,
              withKeyPath: "selectionIndexPaths")
  }

  private func changeRootTreeNode(`for` url: URL) -> NSTreeNode? {
    if url == self.cwd {
      return self.treeController.arrangedObjects
    }

    let cwdCompsCount = self.cwd.pathComponents.count
    guard cwdCompsCount <= url.pathComponents.count else { return nil }
    let comps = url.pathComponents.suffix(cwdCompsCount)

    let rootTreeNode = self.treeController.arrangedObjects
    let changeTreeNode = comps.reduce(rootTreeNode) { (prev, comp) in
      return prev.children?.first { child in
        return child.node?.displayName == comp
      } ?? prev
    }

    guard let changeNode = changeTreeNode.node else {
      return nil
    }

    guard changeNode.url == url && changeNode.children != nil else {
      return nil
    }

    return changeTreeNode
  }

  private func handleAddition(
    changeTreeNode: NSTreeNode, newChildUrls: Set<URL>
  ) {
    let existingUrls = changeTreeNode.children?
                         .compactMap { $0.node?.url } ?? []
    let newNodes = newChildUrls
      .subtracting(existingUrls)
      .map { Node(url: $0) }
    let newIndexPaths = (0..<newNodes.count)
      .map { i in changeTreeNode.indexPath.appending(i) }

    self.treeController.insert(newNodes,
                               atArrangedObjectIndexPaths: newIndexPaths)
  }

  private func handleRemoval(
    changeTreeNode: NSTreeNode, newChildUrls: Set<URL>
  ) {
    let indexPathsToRemove =
      changeTreeNode.children?
        .filter { child in
          guard let url = child.node?.url else { return true }
          return newChildUrls.contains(url) == false
        }
        .map { $0.indexPath } ?? []

    self.treeController.removeObjects(
      atArrangedObjectIndexPaths: indexPathsToRemove
    )
  }

  private func childUrls(for url: URL) -> [URL] {
    let urls = FileUtils.directDescendants(of: url).sorted { lhs, rhs in
      return lhs.lastPathComponent < rhs.lastPathComponent
    }

    if self.isShowHidden {
      return urls
    }

    return urls.filter { !$0.isHidden }
  }

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

  private func select(treeNode: NSTreeNode) {
    let targetRow = self.row(forItem: treeNode)
    self.selectRowIndexes(IndexSet(integer: targetRow), byExtendingSelection: false)
    self.scrollRowToVisible(targetRow)
  }

  private func updateTheme(_ theme: Marked<Theme>) {
    self.theme = theme.payload
    self.enclosingScrollView?.backgroundColor = self.theme.background
    self.backgroundColor = self.theme.background
    self.triangleClosed = NSImage.fontAwesomeIcon(
      name: .caretRight,
      style: .solid,
      textColor: self.theme.directoryForeground,
      dimension: triangleImageSize
    )
    self.triangleOpen = NSImage.fontAwesomeIcon(
      name: .caretDown,
      style: .solid,
      textColor: self.theme.directoryForeground,
      dimension: triangleImageSize
    )

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
    return (item as? NSTreeNode)?.node
  }
}

// MARK: - Actions
extension FileOutlineView {

  @IBAction func doubleClickAction(_: Any?) {
    let clickedTreeNode = self.clickedItem
    guard let node = self.node(from: clickedTreeNode) else {
      return
    }

    if node.isDir {
      self.toggle(item: clickedTreeNode)
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
    let view = self.makeView(
      withIdentifier: NSUserInterfaceItemIdentifier("file-row-view"),
      owner: self
    ) as? ThemedTableRow ?? ThemedTableRow(withIdentifier: "file-row-view",
                                           themedView: self)

    return view
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

    let rv = rowView as? ThemedTableRow
    guard rv?.themeToken != self.lastThemeMark else {
      return
    }

    let triangleView = rv?.triangleView
    triangleView?.image = self.triangleClosed
    triangleView?.alternateImage = self.triangleOpen
    rv?.themeToken = self.lastThemeMark
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

// MARK: - NSView
extension FileOutlineView {

  override func keyDown(with event: NSEvent) {
    guard let char = event.charactersIgnoringModifiers?.first else {
      super.keyDown(with: event)
      return
    }

    guard let node = self.node(from: self.selectedItem) else {
      super.keyDown(with: event)
      return
    }

    switch char {
    case " ", "\r": // Why "\r" and not "\n"?
      if node.url.isDir || node.url.isPackage {
        self.toggle(item: node)
      } else {
        self.emit(
          UuidAction(uuid: self.uuid,
                     action: .open(url: node.url, mode: .newTab))
        )
      }

    default:
      super.keyDown(with: event)
    }
  }
}

class Node: NSObject, Comparable {

  static func <(lhs: Node, rhs: Node) -> Bool {
    return lhs.displayName < rhs.displayName
  }

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

  override var description: String {
    return "<Node: \(self.url): \(self.childrenCount) children>"
  }

  override var hash: Int {
    return self.url.hashValue
  }

  init(url: URL) {
    self.url = url
    self.isLeaf = !url.isDir
    self.isHidden = url.isHidden
  }
}

private extension NSTreeNode {

  var node: Node? {
    return self.representedObject as? Node
  }
}

private let columnWidthRightPadding = CGFloat(40)
private let triangleImageSize = CGFloat(18)
