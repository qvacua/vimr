/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import Down

extension NSColor {

  static var random: NSColor {
    NSColor(
      calibratedRed: .random(in: 0...1),
      green: .random(in: 0...1),
      blue: .random(in: 0...1),
      alpha: 1.0
    )
  }

  var int: Int {
    if let color = self.usingColorSpace(.sRGB) {
      let a = Int(color.alphaComponent * 255)
      let r = Int(color.redComponent * 255)
      let g = Int(color.greenComponent * 255)
      let b = Int(color.blueComponent * 255)
      return a << 24 | r << 16 | g << 8 | b
    } else {
      return 0
    }
  }

  var hex: String { String(String(format: "%06X", self.int).suffix(6)) }

  convenience init(rgb: Int) {
    // @formatter:off
    let red =   ((rgb >> 16) & 0xFF).cgf / 255.0;
    let green = ((rgb >>  8) & 0xFF).cgf / 255.0;
    let blue =  ((rgb      ) & 0xFF).cgf / 255.0;
    // @formatter:on

    self.init(srgbRed: red, green: green, blue: blue, alpha: 1.0)
  }

  convenience init?(hex: String) {
    var result: UInt32 = 0
    guard hex.count == 6, Scanner(string: hex).scanHexInt32(&result) else { return nil }

    let r = (result & 0xFF0000) >> 16
    let g = (result & 0x00FF00) >> 8
    let b = (result & 0x0000FF)

    self.init(srgbRed: r.cgf / 255, green: g.cgf / 255, blue: b.cgf / 255, alpha: 1)
  }

  func brightening(by factor: CGFloat) -> NSColor {
    guard let color = self.usingColorSpace(.sRGB) else { return self }

    let h = color.hueComponent
    let s = color.saturationComponent
    let b = color.brightnessComponent
    let a = color.alphaComponent

    return NSColor(hue: h, saturation: s, brightness: b * factor, alpha: a)
  }
}

extension NSImage {

  func tinting(with color: NSColor) -> NSImage {
    let result = self.copy() as! NSImage

    result.lockFocus()
    color.set()
    CGRect(origin: .zero, size: self.size).fill(using: .sourceAtop)
    result.unlockFocus()

    return result
  }
}

extension NSButton {

  var boolState: Bool {
    get { self.state == .on ? true : false }
    set { self.state = newValue ? .on : .off }
  }
}

extension NSMenuItem {

  var boolState: Bool {
    get { self.state == .on ? true : false }
    set { self.state = newValue ? .on : .off }
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

  var wholeRange: NSRange { NSRange(location: 0, length: self.length) }

  static func infoLabel(markdown: String) -> NSAttributedString {
    let size = NSFont.smallSystemFontSize
    let down = Down(markdownString: markdown)
    guard let result = try? down.toAttributedString(styler: downStyler) else {
      preconditionFailure("Wrong markdown: \(markdown)")
    }

    return result
  }
}

extension NSView {

  func removeAllSubviews() { self.subviews.forEach { $0.removeFromSuperview() } }

  func removeAllConstraints() { self.removeConstraints(self.constraints) }

  @objc var isFirstResponder: Bool { self.window?.firstResponder == self }

  func beFirstResponder() { self.window?.makeFirstResponder(self) }
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
   The selected item. When the selection is empty, then returns `nil`.
   When multiple items are selected, then returns the last selected item.
   */
  var selectedItem: Any? {
    if self.selectedRow < 0 { return nil }

    return self.item(atRow: self.selectedRow)
  }

  var clickedItem: Any? {
    if self.clickedRow < 0 { return nil }

    return self.item(atRow: self.clickedRow)
  }

  func toggle(item: Any?) {
    if self.isItemExpanded(item) {
      self.collapseItem(item)
    } else {
      self.expandItem(item)
    }
  }
}

extension NSTextField {

  static func defaultTitleTextField() -> NSTextField {
    let field = NSTextField(forAutoLayout: ())
    field.backgroundColor = NSColor.clear;
    field.isEditable = false;
    field.isBordered = false;
    return field
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

private let fontCollection = StaticFontCollection(
  body: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize),
  code: NSFont.userFixedPitchFont(ofSize: NSFont.smallSystemFontSize)!
)

private let downStyler = AttributedStringMarkdownStyler.new()
