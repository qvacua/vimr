/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import CocoaMarkdown

extension NSColor {

  static var random: NSColor {
    return NSColor(calibratedRed: CGFloat(drand48()), green: CGFloat(drand48()), blue: CGFloat(drand48()), alpha: 1.0)
  }

  var hex: String {
    if let color = self.usingColorSpace(.sRGB) {
      return "#" +
             String(format: "%X", Int(color.redComponent * 255)) +
             String(format: "%X", Int(color.greenComponent * 255)) +
             String(format: "%X", Int(color.blueComponent * 255)) +
             String(format: "%X", Int(color.alphaComponent * 255))
    } else {
      return self.description
    }
  }

  func brightening(by factor: CGFloat) -> NSColor {
    guard let color = self.usingColorSpace(.sRGB) else {
      // TODO: what to do?
      return self
    }

    let h = color.hueComponent
    let s = color.saturationComponent
    let b = color.brightnessComponent
    let a = color.alphaComponent

    return NSColor(hue: h, saturation: s, brightness: b * factor, alpha: a)
  }
}

extension NSImage {

  func tinting(with color: NSColor) -> NSImage {

    let result: NSImage = self.copy() as! NSImage

    result.lockFocus()
    color.set()
    CGRect(origin: .zero, size: self.size).fill(using: .sourceAtop)
    result.unlockFocus()

    return result
  }
}

extension NSButton {

  var boolState: Bool {
    get {
      return self.state == .on ? true : false
    }

    set {
      self.state = newValue ? .on : .off
    }
  }
}

extension NSMenuItem {

  var boolState: Bool {
    get {
      return self.state == .on ? true : false
    }

    set {
      self.state = newValue ? .on : .off
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

  var wholeRange: NSRange {
    return NSRange(location: 0, length: self.length)
  }

  static func infoLabel(markdown: String) -> NSAttributedString {
    let size = NSFont.smallSystemFontSize
    let document = CMDocument(data: markdown.data(using: .utf8), options: .normalize)

    let attrs = CMTextAttributes()
    attrs?.textAttributes = [
      NSAttributedStringKey.font: NSFont.systemFont(ofSize: size),
      NSAttributedStringKey.foregroundColor: NSColor.gray,
    ]
    attrs?.inlineCodeAttributes = [
      NSAttributedStringKey.font: NSFont.userFixedPitchFont(ofSize: size)!,
      NSAttributedStringKey.foregroundColor: NSColor.gray,
    ]

    let renderer = CMAttributedStringRenderer(document: document, attributes: attrs)
    renderer?.register(CMHTMLStrikethroughTransformer())
    renderer?.register(CMHTMLSuperscriptTransformer())
    renderer?.register(CMHTMLUnderlineTransformer())

    guard let result = renderer?.render() else {
      preconditionFailure("Wrong markdown: \(markdown)")
    }

    return result
  }
}

extension NSView {

  func removeAllSubviews() {
    self.subviews.forEach { $0.removeFromSuperview() }
  }

  func removeAllConstraints() {
    self.removeConstraints(self.constraints)
  }

  @objc var isFirstResponder: Bool {
    return self.window?.firstResponder == self
  }

  func beFirstResponder() {
    self.window?.makeFirstResponder(self)
  }
}

extension NSTableView {

  static func standardTableView() -> NSTableView {
    let tableView = NSTableView(frame: CGRect.zero)

    let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("name"))
    column.isEditable = false

    tableView.addTableColumn(column)
    tableView.rowSizeStyle = .default
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
    let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("name"))
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
