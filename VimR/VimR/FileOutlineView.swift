/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import Commons
import MaterialIcons
import NvimView
import os
import PureLayout

final class FileOutlineView: NSOutlineView,
  UiComponent,
  NSOutlineViewDelegate,
  ThemedView
{
  typealias StateType = MainWindow.State

  let uuid = UUID()

  @objc dynamic var content = [Node]()

  private(set) var lastThemeMark = Token()
  private(set) var theme = Theme.default

  required init(context: ReduxContext, state: StateType) {
    self.context = context
    self.emit = context.actionEmitter.typedEmit()

    self.mainWinUuid = state.uuid
    self.root = Node(url: state.cwd)
    self.usesTheme = state.appearance.usesTheme
    self.showsFileIcon = state.appearance.showsFileIcon
    self.isShowHidden = state.fileBrowserShowHidden
    self.triangleClosed = Icon.chevronRight.asImage(
      dimension: triangleImageSize,
      style: .filled,
      color: self.theme.directoryForeground
    )
    self.triangleOpen = Icon.expandMore.asImage(
      dimension: triangleImageSize,
      style: .filled,
      color: self.theme.directoryForeground
    )

    super.init(frame: .zero)

    try? self.fileMonitor.monitor(url: state.cwd) { [weak self] url in
      self?.handleFileSystemChanges(url)
    }

    NSOutlineView.configure(toStandard: self)
    self.delegate = self

    context.subscribe(uuid: self.uuid) { appState in
      guard let state = appState.mainWindows[self.mainWinUuid] else { return }

      if state.viewToBeFocused != nil, case .fileBrowser = state.viewToBeFocused! {
        self.beFirstResponder()
      }

      let themeChanged = changeTheme(
        themePrefChanged: state.appearance.usesTheme != self.usesTheme,
        themeChanged: state.appearance.theme.mark != self.lastThemeMark,
        usesTheme: state.appearance.usesTheme,
        forTheme: { self.updateTheme(state.appearance.theme) },
        forDefaultTheme: { self.updateTheme(Marked(Theme.default)) }
      )

      self.usesTheme = state.appearance.usesTheme

      guard self.shouldReloadData(for: state, themeChanged: themeChanged) else { return }

      self.showsFileIcon = state.appearance.showsFileIcon
      self.isShowHidden = state.fileBrowserShowHidden
      self.lastFileSystemUpdateMark = state.lastFileSystemUpdate.mark

      if self.root.url != state.cwd {
        self.root = Node(url: state.cwd)
        try? self.fileMonitor.monitor(url: state.cwd) { [weak self] url in
          self?.handleFileSystemChanges(url)
        }
      }

      self.reloadRoot()
    }

    self.initContextMenu()
    self.initBindings()
    self.reloadRoot()
  }

  func cleanup() {
    self.context.unsubscribe(uuid: self.uuid)

    self.unbindTreeController()
  }

  // We cannot use outlineView(_:willDisplayOutlineCell:for:item:) delegate
  // method to customize the disclosure triangle in a view-based NSOutlineView.
  // See https://stackoverflow.com/a/20454413
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
    guard let childrenOfRoot = self.treeController.arrangedObjects.children else { return }

    var stack = [NSTreeNode]()

    // NSTreeController.arrangedObjects has no Node.
    for childOfRoot in childrenOfRoot {
      guard let node = childOfRoot.node else { continue }

      if node.url == url {
        self.select(treeNode: childOfRoot)
        return
      }

      if node.url.isAncestor(of: url) {
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

      if node.url.isAncestor(of: url) { stack.append(contentsOf: item.children ?? []) }
    }
  }

  func unbindTreeController() {
    // Forbid addition and removal now.
    // See comment in FileOutlineView.handleRemoval.
    self.treeController.isEditable = false

    self.treeController.unbind(.contentArray)
    self.unbind(.content)
    self.unbind(.selectionIndexPaths)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) { fatalError("init(coder:) has not been implemented") }

  private nonisolated func handleFileSystemChanges(_ changedUrl: URL) {
    Task { @MainActor in
      guard let changeTreeNode = self.changedTreeNode(for: changedUrl) else { return }

      let newChildUrls = Set(self.childUrls(for: changedUrl))
      self.handleRemoval(changeTreeNode: changeTreeNode, newChildUrls: newChildUrls)
      self.handleAddition(changeTreeNode: changeTreeNode, newChildUrls: newChildUrls)
    }
  }

  private let context: ReduxContext
  private let emit: (UuidAction<FileBrowser.Action>) -> Void

  private let mainWinUuid: UUID

  private var root: Node
  private var cwd: URL { self.root.url }
  private let treeController = NSTreeController()
  private let fileMonitor = FileMonitor()

  private var cachedColumnWidth = 20.0
  private var usesTheme: Bool
  private var lastFileSystemUpdateMark = Token()
  private var showsFileIcon: Bool
  private var isShowHidden: Bool

  private var triangleClosed: NSImage
  private var triangleOpen: NSImage

  private let log = Logger(subsystem: Defs.loggerSubsystem, category: Defs.LoggerCategory.ui)

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
      NSSortDescriptor(key: "displayName", ascending: true), // then, name
    ]

    // The following will create a retain cycle. The superview *must* unbind
    // in deinit. See deinit of FileBrowser
    self.treeController.bind(.contentArray, to: self, withKeyPath: "content")

    self.bind(.content, to: self.treeController, withKeyPath: "arrangedObjects")
    self.bind(.selectionIndexPaths, to: self.treeController, withKeyPath: "selectionIndexPaths")
  }

  private func changedTreeNode(for url: URL) -> NSTreeNode? {
    if url == self.cwd { return self.treeController.arrangedObjects }

    let cwdCompsCount = self.cwd.pathComponents.count
    guard cwdCompsCount <= url.pathComponents.count else { return nil }
    let comps = url.pathComponents.suffix(cwdCompsCount)

    let rootTreeNode = self.treeController.arrangedObjects
    let changedTreeNode = comps.reduce(rootTreeNode) { prev, comp in
      prev.children?.first { child in child.node?.displayName == comp } ?? prev
    }

    guard let changeNode = changedTreeNode.node else { return nil }

    guard changeNode.url == url, changeNode.children != nil else { return nil }

    return changedTreeNode
  }

  private func handleAddition(changeTreeNode: NSTreeNode, newChildUrls: Set<URL>) {
    // See comment in FileOutlineView.handleRemoval.
    guard self.treeController.isEditable else { return }

    let existingUrls = changeTreeNode.children?.compactMap { $0.node?.url } ?? []
    let newNodes = newChildUrls.subtracting(existingUrls).map(Node.init)
    let newIndexPaths = (0..<newNodes.count).map { i in changeTreeNode.indexPath.appending(i) }

    self.treeController.insert(newNodes, atArrangedObjectIndexPaths: newIndexPaths)
  }

  private func handleRemoval(changeTreeNode: NSTreeNode, newChildUrls: Set<URL>) {
    // FileOutlineView is deinit'ed a bit after Neovim is closed.
    // If Neovim deletes for example a temporary file, then handleRemoval is
    // called after the self.content is frozen. Thus, we make the controller
    // not editable when unbinding, see FileOutlineView.unbindTreeController,
    // and check here before modifying.
    guard self.treeController.isEditable else { return }

    let indexPathsToRemove = changeTreeNode
      .children?
      .filter { child in
        guard let url = child.node?.url else { return true }
        return newChildUrls.contains(url) == false
      }
      .map(\.indexPath) ?? []

    changeTreeNode
      .children?
      .filter { child in
        guard let url = child.node?.url else { return true }
        return newChildUrls.contains(url) == false
      }
      .forEach { treeNode in self.log.info(treeNode.node) }

    self.treeController.removeObjects(atArrangedObjectIndexPaths: indexPathsToRemove)
  }

  private func childUrls(for url: URL) -> [URL] {
    let urls = FileUtils.directDescendants(of: url).sorted { lhs, rhs in
      lhs.lastPathComponent < rhs.lastPathComponent
    }

    if self.isShowHidden { return urls }

    return urls.filter { !$0.isHidden }
  }

  private func childNodes(for node: Node) -> [Node] {
    if node.isChildrenScanned { return node.children ?? [] }

    let nodes = FileUtils.directDescendants(of: node.url).map(Node.init)

    if self.isShowHidden { return nodes }

    return nodes.filter { !$0.isHidden }
  }

  private func reloadRoot() {
    // See comment in FileOutlineView.handleRemoval.
    guard self.treeController.isEditable else { return }

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
    self.triangleClosed = Icon.chevronRight.asImage(
      dimension: triangleImageSize,
      style: .filled,
      color: self.theme.directoryForeground
    )
    self.triangleOpen = Icon.expandMore.asImage(
      dimension: triangleImageSize,
      style: .filled,
      color: self.theme.directoryForeground
    )

    self.lastThemeMark = theme.mark
  }

  private func shouldReloadData(for state: StateType, themeChanged: Bool = false) -> Bool {
    if self.isShowHidden != state.fileBrowserShowHidden { return true }

    if themeChanged { return true }

    if self.showsFileIcon != state.appearance.showsFileIcon { return true }

    if state.cwd != self.cwd { return true }

    return false
  }

  private func node(from item: Any?) -> Node? { (item as? NSTreeNode)?.node }
}

// MARK: - Actions

extension FileOutlineView {
  @IBAction func doubleClickAction(_: Any?) {
    let clickedTreeNode = self.clickedItem
    guard let node = self.node(from: clickedTreeNode) else { return }

    if node.isDir {
      self.toggle(item: clickedTreeNode)
    } else {
      self.emit(UuidAction(uuid: self.mainWinUuid, action: .open(url: node.url, mode: .default)))
    }
  }

  @IBAction func openInNewTab(_: Any?) {
    guard let node = self.node(from: self.clickedItem) else { return }

    self.emit(UuidAction(uuid: self.mainWinUuid, action: .open(url: node.url, mode: .newTab)))
  }

  @IBAction func openInCurrentTab(_: Any?) {
    guard let node = self.node(from: self.clickedItem) else { return }

    self.emit(UuidAction(uuid: self.mainWinUuid, action: .open(url: node.url, mode: .currentTab)))
  }

  @IBAction func openInHorizontalSplit(_: Any?) {
    guard let node = self.node(from: self.clickedItem) else { return }

    self.emit(UuidAction(
      uuid: self.mainWinUuid,
      action: .open(url: node.url, mode: .horizontalSplit)
    ))
  }

  @IBAction func openInVerticalSplit(_: Any?) {
    guard let node = self.node(from: self.clickedItem) else { return }

    self.emit(UuidAction(
      uuid: self.mainWinUuid,
      action: .open(url: node.url, mode: .verticalSplit)
    ))
  }

  @IBAction func newFile(_: Any?) {
    guard let node = self.node(from: self.clickedItem) else { return }

    guard node.url.hasDirectoryPath else { return }

    let panel = NSSavePanel()
    panel.directoryURL = node.url
    panel.nameFieldLabel = "Filename"
    panel.prompt = "Open"
    panel.showsTagField = false
    panel.beginSheetModal(for: self.window!) { result in
      guard result == .OK else {
        return
      }

      let showAlert: () -> Void = {
        let alert = NSAlert()
        alert.addButton(withTitle: "OK")
        alert.messageText = "Invalid File Name"
        alert
          .informativeText =
          "The file name you have entered cannot be used. Please use a different name."
        alert.alertStyle = .warning

        alert.runModal()
      }

      guard let url = panel.url else {
        showAlert()
        return
      }

      self.emit(UuidAction(uuid: self.mainWinUuid, action: .open(url: url, mode: .newTab)))
    }
  }

  @IBAction func deleteFile(_: Any?) {
    guard let node = self.node(from: self.clickedItem) else { return }

    let fileManager = FileManager.default

    let showAlert: () -> Void = {
      let alert = NSAlert()
      alert.addButton(withTitle: "OK")
      alert.messageText = "Could not move file to Trash"
      alert.alertStyle = .warning

      alert.runModal()
    }

    do {
      try fileManager.trashItem(at: node.url, resultingItemURL: nil)
    } catch {
      showAlert()
      return
    }

    self.emit(UuidAction(uuid: self.mainWinUuid, action: .refresh))
  }

  @IBAction func setAsWorkingDirectory(_: Any?) {
    guard let node = self.node(from: self.clickedItem) else { return }

    guard node.url.hasDirectoryPath else { return }

    self.emit(UuidAction(uuid: self.mainWinUuid, action: .setAsWorkingDirectory(node.url)))
  }
}

// MARK: - NSOutlineViewDelegate

extension FileOutlineView {
  func outlineView(_: NSOutlineView, rowViewForItem _: Any) -> NSTableRowView? {
    let view = self.makeView(
      withIdentifier: NSUserInterfaceItemIdentifier("file-row-view"),
      owner: self
    ) as? ThemedTableRow ?? ThemedTableRow(withIdentifier: "file-row-view", themedView: self)

    return view
  }

  func outlineView(_: NSOutlineView, viewFor _: NSTableColumn?, item: Any) -> NSView? {
    guard let node = self.node(from: item) else { return nil }

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

  func outlineView(_: NSOutlineView, heightOfRowByItem _: Any) -> CGFloat { 20 }

  func outlineView(_: NSOutlineView, shouldExpandItem item: Any) -> Bool {
    guard let node = self.node(from: item) else { return false }

    if node.isChildrenScanned { return true }

    node.children = FileUtils.directDescendants(of: node.url).map(Node.init)

    return true
  }

  func outlineView(_: NSOutlineView, didAdd rowView: NSTableRowView, forRow row: Int) {
    guard let cellWidth = (rowView.view(atColumn: 0) as? NSTableCellView)?.fittingSize.width else {
      return
    }

    let level = self.level(forRow: row).cgf
    let width = level * self.indentationPerLevel + cellWidth + columnWidthRightPadding
    self.cachedColumnWidth = max(self.cachedColumnWidth, width)
    self.tableColumns[0].width = self.cachedColumnWidth

    let rv = rowView as? ThemedTableRow
    guard rv?.themeToken != self.lastThemeMark else { return }

    let triangleView = rv?.triangleView
    triangleView?.image = self.triangleClosed
    triangleView?.alternateImage = self.triangleOpen
    rv?.themeToken = self.lastThemeMark
  }
}

// MARK: - NSUserInterfaceValidations

extension FileOutlineView {
  override func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
    guard let clickedNode = self.node(from: self.clickedItem) else { return true }

    let isValid: Bool = switch item.action {
    case #selector(self.setAsWorkingDirectory(_:)):
      clickedNode.url.hasDirectoryPath
    case #selector(self.newFile(_:)):
      clickedNode.url.hasDirectoryPath
    default:
      true
    }

    return isValid
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
      if node.url.hasDirectoryPath || node.url.isPackage {
        self.toggle(item: node)
      } else {
        self.emit(UuidAction(uuid: self.mainWinUuid, action: .open(url: node.url, mode: .newTab)))
      }

    default:
      super.keyDown(with: event)
    }
  }
}

final class Node: NSObject, Comparable {
  static func < (lhs: Node, rhs: Node) -> Bool { lhs.displayName < rhs.displayName }

  @objc dynamic var url: URL
  @objc dynamic var isLeaf: Bool
  @objc dynamic var isHidden: Bool
  @objc dynamic var children: [Node]?

  @objc dynamic var childrenCount: Int { self.children?.count ?? -1 }
  @objc dynamic var displayName: String { self.url.lastPathComponent }

  var isDir: Bool { !self.isLeaf }
  var isChildrenScanned = false

  override var description: String { "<Node: \(self.url): \(self.childrenCount) children>" }

  override var hash: Int { self.url.hashValue }

  init(url: URL) {
    self.url = url
    self.isLeaf = !url.hasDirectoryPath
    self.isHidden = url.isHidden
  }
}

private extension NSTreeNode {
  var node: Node? { self.representedObject as? Node }
}

private let columnWidthRightPadding = 40.0
private let triangleImageSize = 18.0
