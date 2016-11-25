/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa

extension NSButton {

  var boolState: Bool {
    get {
      return self.state == NSOnState ? true : false
    }

    set {
      self.state = newValue ? NSOnState : NSOffState
    }
  }
}

extension NSAttributedString {

  func draw(at point: CGPoint, angle: CGFloat) {
    var translation = AffineTransform.identity
    var rotation = AffineTransform.identity

    translation.translate(x: point.x, y: point.y)
    rotation.rotate(byRadians: angle)

    (translation as NSAffineTransform).concat()
    (rotation as NSAffineTransform).concat()

    self.draw(at: CGPoint.zero)

    rotation.invert()
    translation.invert()

    (rotation as NSAffineTransform).concat()
    (translation as NSAffineTransform).concat()
  }

  // From https://developer.apple.com/library/mac/qa/qa1487/_index.html
  static func link(withUrl url: URL, text: String, font: NSFont? = nil) -> NSAttributedString {
    let attrString = NSMutableAttributedString(string: text)
    let range = NSRange(location: 0, length: attrString.length)

    attrString.beginEditing()
    if font != nil {
      attrString.addAttribute(NSFontAttributeName, value: font!, range: range)
    }
    attrString.addAttribute(NSLinkAttributeName, value: url.absoluteString, range: range)
    attrString.addAttribute(NSForegroundColorAttributeName, value: NSColor.blue, range: range)
    attrString.addAttribute(NSUnderlineStyleAttributeName,
                            value: NSNumber(value: NSUnderlineStyle.styleSingle.rawValue as Int), range: range)
    attrString.endEditing()

    return attrString
  }

  var wholeRange: NSRange {
    return NSRange(location: 0, length: self.length)
  }
}

extension NSView {

  func removeAllSubviews() {
    self.subviews.forEach { $0.removeFromSuperview() }
  }

  func removeAllConstraints() {
    self.removeConstraints(self.constraints)
  }

  var isFirstResponder: Bool {
    return self.window?.firstResponder == self
  }

  func beFirstResponder() {
    self.window?.makeFirstResponder(self)
  }
}

extension NSTableView {

  static func standardTableView() -> NSTableView {
    let tableView = NSTableView(frame: CGRect.zero)

    let column = NSTableColumn(identifier: "name")
    column.isEditable = false

    tableView.addTableColumn(column)
    tableView.rowSizeStyle	=	.default
    tableView.sizeLastColumnToFit()
    tableView.allowsEmptySelection = false
    tableView.allowsMultipleSelection = false
    tableView.headerView = nil
    tableView.focusRingType = .none

    return tableView
  }

  static func standardSourceListTableView() -> NSTableView {
    let tableView = self.standardTableView()
    tableView.selectionHighlightStyle = .sourceList

    return tableView
  }
}

extension NSOutlineView {

  static func standardOutlineView() -> NSOutlineView {
    let outlineView = NSOutlineView(frame: CGRect.zero)
    NSOutlineView.configure(toStandard: outlineView)
    return outlineView
  }

  static func configure(toStandard outlineView: NSOutlineView) {
    let column = NSTableColumn(identifier: "name")
    column.resizingMask = .autoresizingMask
    column.isEditable = false

    outlineView.addTableColumn(column)
    outlineView.outlineTableColumn = column
    outlineView.allowsEmptySelection = false
    outlineView.allowsMultipleSelection = false
    outlineView.headerView = nil
    outlineView.focusRingType = .none
  }

  /**
   The selected item. When the selection is empty, then returns `nil`. When multiple items are selected, then returns
   the last selected item.
   */
  var selectedItem: Any? {
    if self.selectedRow < 0 {
      return nil
    }

    return self.item(atRow: self.selectedRow)
  }

  var clickedItem: Any? {
    if self.clickedRow < 0 {
      return nil
    }

    return self.item(atRow: self.clickedRow)
  }

  func toggle(item: Any) {
    if self.isItemExpanded(item) {
      self.collapseItem(item)
    } else {
      self.expandItem(item)
    }
  }
}

extension NSScrollView {

  static func standardScrollView() -> NSScrollView {
    let scrollView = NSScrollView(frame: CGRect.zero)

    scrollView.translatesAutoresizingMaskIntoConstraints = false
    scrollView.hasVerticalScroller = true
    scrollView.hasHorizontalScroller = true
    scrollView.autohidesScrollers = true
    scrollView.borderType = .bezelBorder

    return scrollView
  }
}
