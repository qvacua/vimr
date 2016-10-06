/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import RxSwift

enum FileOutlineViewAction {

  case openFileItem(fileItem: FileItem)
}

class FileOutlineView: NSOutlineView, Flow, NSOutlineViewDataSource, NSOutlineViewDelegate {

  fileprivate let flow: EmbeddableComponent
  fileprivate let fileItemService: FileItemService

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
  }
}

// MARK: - NSOutlineView
extension FileOutlineView {

  override func reloadItem(_ item: Any?, reloadChildren: Bool) {
    let selectedItem = self.selectedItem
    let visibleRect = self.enclosingScrollView?.contentView.visibleRect

    let expandedItems = self.expandedItems
    super.reloadItem(item, reloadChildren: reloadChildren)
    self.adjustFileViewWidth()

    self.restore(expandedItems: expandedItems)
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
    //NSLog("\(#function): \(item)")
    guard item.dir && states.contains(item) else {
      return
    }

    self.expandItem(item)

    item.children.forEach { [unowned self] child in
      self.restoreExpandedState(for: child, states: states)
    }
  }

  fileprivate func restore(expandedItems: Set<FileItem>) {
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

  func outlineView(_ outlineView: NSOutlineView, shouldExpandItem item: Any) -> Bool {
    guard let fileItem = item as? FileItem else {
      return true
    }

    self.expandedItems.insert(fileItem)

    return true
  }

  func outlineView(_ outlineView: NSOutlineView, shouldCollapseItem item: Any) -> Bool {
    guard let fileItem = item as? FileItem else {
      return true
    }

    self.expandedItems.remove(fileItem)

    return true
  }

  func outlineViewItemDidExpand(_ notification: Notification) {
    self.adjustFileViewWidth()
  }

  func outlineViewItemDidCollapse(_ notification: Notification) {
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
      if item.dir || item.package {
        self.toggle(item: item)
      } else {
        self.flow.publish(event: FileOutlineViewAction.openFileItem(fileItem: item))
      }

    default:
      super.keyDown(with: event)
    }
  }
}
