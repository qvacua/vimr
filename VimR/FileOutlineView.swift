/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
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

class FileOutlineView: NSOutlineView, Flow, NSOutlineViewDataSource, NSOutlineViewDelegate {

  fileprivate let flow: EmbeddableComponent
  fileprivate let fileItemService: FileItemService

  fileprivate var fileItems = Set<FileItem>()

  fileprivate var expandedItems = Set<FileItem>()

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

    super.init(frame: CGRect.zero)

    self.dataSource = self
    self.delegate = self

    guard Bundle.main.loadNibNamed("FileBrowserMenu", owner: self, topLevelObjects: nil) else {
      NSLog("WARN: FileBrowserMenu.xib could not be loaded")
      return
    }

    self.doubleAction = #selector(FileOutlineView.doubleClickAction)
  }
}

// MARK: - NSOutlineView
extension FileOutlineView {

  override func reloadItem(_ item: Any?, reloadChildren: Bool) {
//    NSLog("\(#function): \(item)")
    let selectedItem = self.selectedItem
    let visibleRect = self.enclosingScrollView?.contentView.visibleRect

    let expandedItems = self.expandedItems

    if item == nil {
      self.fileItems.removeAll()
    } else {
      guard let fileItem = item as? FileItem else {
        preconditionFailure("Should not happen")
      }

      self.fileItems.remove(fileItem)
      if fileItem.isDir {
        self.fileItems
          .filter { fileItem.url.isParent(of: $0.url) }
          .forEach { self.fileItems.remove($0) }
      }
    }

    super.reloadItem(item, reloadChildren: reloadChildren)

    self.restore(expandedItems: expandedItems)
    self.adjustFileViewWidth()

    self.scrollToVisible(visibleRect!)

    guard let selectedFileItem = selectedItem as? FileItem else {
      return
    }

    for idx in 0..<self.numberOfRows {
      guard let itemAtRow = self.item(atRow: idx) as? FileItem else {
        continue
      }

      if itemAtRow == selectedFileItem {
        self.selectRowIndexes(IndexSet([idx]), byExtendingSelection: false)
        return
      }
    }
  }

  fileprivate func restoreExpandedState(for item: FileItem, states: Set<FileItem>) {
    guard item.isDir && states.contains(item) else {
      return
    }

    self.expandItem(item)
    self.expandedItems.insert(item)

    item.children.forEach { [unowned self] child in
      self.restoreExpandedState(for: child, states: states)
    }
  }

  fileprivate func restore(expandedItems: Set<FileItem>) {
//    NSLog("\(#function): \(expandedItems)")
    if expandedItems.isEmpty {
      return
    }

    guard let root = self.fileItemService.fileItemWithChildren(for: self.cwd) else {
      self.expandedItems.removeAll()
      return
    }

    self.expandedItems.removeAll()
    root.children.forEach { self.restoreExpandedState(for: $0, states: expandedItems) }
  }
}

// MARK: - NSOutlineViewDataSource
extension FileOutlineView {

  func outlineView(_: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
    if item == nil {
      return self.fileItemService.fileItemWithChildren(for: self.cwd)?.children
        .filter { !$0.isHidden }
        .count ?? 0
    }

    guard let fileItem = item as? FileItem else {
      return 0
    }

    if fileItem.isDir {
      return self.fileItemService.fileItemWithChildren(for: fileItem.url)?.children
        .filter { !$0.isHidden }
        .count ?? 0
    }

    return 0
  }

  func outlineView(_: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
    if item == nil {
      let result = self.fileItemService.fileItemWithChildren(for: self.cwd)!.children.filter { !$0.isHidden }[index]
      self.fileItems.insert(result)

      return result
    }

    guard let fileItem = item as? FileItem else {
      preconditionFailure("Should not happen")
    }

    let result = self.fileItemService.fileItemWithChildren(for: fileItem.url)!.children.filter { !$0.isHidden }[index]
    self.fileItems.insert(result)

    return result
  }

  func outlineView(_: NSOutlineView, isItemExpandable item: Any) ->  Bool {
    guard let fileItem = item as? FileItem else {
      return false
    }

    return fileItem.isDir
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
extension FileOutlineView {

  @objc(outlineView:viewForTableColumn:item:)
  func outlineView(_: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
    guard let fileItem = item as? FileItem else {
      return nil
    }

    let cachedCell = self.make(withIdentifier: "file-view-row", owner: self)
    let cell = cachedCell as? ImageAndTextTableCell ?? ImageAndTextTableCell(withIdentifier: "file-view-row")

    cell.text = fileItem.url.lastPathComponent
    cell.image = self.fileItemService.icon(forUrl: fileItem.url)

    return cell
  }

  func outlineView(_: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat {
    return 20
  }

  func outlineViewItemDidExpand(_ notification: Notification) {
    if let fileItem = notification.userInfo?["NSObject"] as? FileItem {
      self.expandedItems.insert(fileItem)
    }
    
    self.adjustFileViewWidth()
  }

  func outlineViewItemDidCollapse(_ notification: Notification) {
    if let fileItem = notification.userInfo?["NSObject"] as? FileItem {
      self.expandedItems.remove(fileItem)
    }

    self.adjustFileViewWidth()
  }

  fileprivate func adjustFileViewWidth() {
    let indentationPerLevel = self.indentationPerLevel
    let attrs = [NSFontAttributeName: ImageAndTextTableCell.font]

    let maxWidth = (0..<self.numberOfRows).reduce(CGFloat(0)) { (curMaxWidth, idx) in
      guard let item = self.item(atRow: idx) as? FileItem else {
        return curMaxWidth
      }

      let level = CGFloat(self.level(forRow: idx) + 1)
      let indentation = level * indentationPerLevel
      let width = (item.url.lastPathComponent as NSString).size(withAttributes: attrs).width + indentation

      return max(curMaxWidth, width)
    }

    let column = self.outlineTableColumn!
    column.minWidth = maxWidth + ImageAndTextTableCell.widthWithoutText
    column.maxWidth = column.minWidth
  }
}

// MARK: - Actions
extension FileOutlineView {

  @IBAction func doubleClickAction(_: Any?) {
    guard let item = self.clickedItem as? FileItem else {
      return
    }

    if item.isDir {
      self.toggle(item: item)
    } else {
      self.flow.publish(event: FileOutlineViewAction.open(fileItem: item))
    }
  }

  @IBAction func openInNewTab(_: Any?) {
    guard let item = self.clickedItem as? FileItem else {
      return
    }

    self.flow.publish(event: FileOutlineViewAction.openFileInNewTab(fileItem: item))
  }

  @IBAction func openInCurrentTab(_: Any?) {
    guard let item = self.clickedItem as? FileItem else {
      return
    }

    self.flow.publish(event: FileOutlineViewAction.openFileInCurrentTab(fileItem: item))
  }

  @IBAction func openInHorizontalSplit(_: Any?) {
    guard let item = self.clickedItem as? FileItem else {
      return
    }

    self.flow.publish(event: FileOutlineViewAction.openFileInHorizontalSplit(fileItem: item))
  }

  @IBAction func openInVerticalSplit(_: Any?) {
    guard let item = self.clickedItem as? FileItem else {
      return
    }

    self.flow.publish(event: FileOutlineViewAction.openFileInVerticalSplit(fileItem: item))
  }

  @IBAction func setAsWorkingDirectory(_: Any?) {
    guard let item = self.clickedItem as? FileItem else {
      return
    }

    guard item.isDir else {
      return
    }

    self.flow.publish(event: FileOutlineViewAction.setAsWorkingDirectory(fileItem: item))
  }

  @IBAction func setParentAsWorkingDirectory(_: Any?) {
    guard let item = self.clickedItem as? FileItem else {
      return
    }

    guard self.level(forItem: clickedItem) > 0 else {
      return
    }

    guard item.url.path != "/" else {
      return
    }

    self.flow.publish(event: FileOutlineViewAction.setParentAsWorkingDirectory(fileItem: item))
  }
}

// MARK: - NSUserInterfaceValidations
extension FileOutlineView {

  override func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
    guard let clickedItem = self.clickedItem as? FileItem else {
      return true
    }

    if item.action == #selector(setAsWorkingDirectory(_:)) {
      return clickedItem.isDir
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

    guard let item = self.selectedItem as? FileItem else {
      super.keyDown(with: event)
      return
    }

    switch char {
    case " ", "\r": // Why "\r" and not "\n"?
      if item.isDir || item.isPackage {
        self.toggle(item: item)
      } else {
        self.flow.publish(event: FileOutlineViewAction.openFileInNewTab(fileItem: item))
      }

    default:
      super.keyDown(with: event)
    }
  }
}
