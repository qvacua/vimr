/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import CocoaMarkdown

extension NSColor {

  static var random: NSColor {
    NSColor(
      calibratedRed: .random(in: 0...1),
      green: .random(in: 0...1),
      blue: .random(in: 0...1),
      alpha: 1.0
    )
  }

  var hex: String {
    guard let color = self.usingColorSpace(.sRGB) else { return self.description }
    return "#" +
           String(format: "%X", Int(color.redComponent * 255)) +
           String(format: "%X", Int(color.greenComponent * 255)) +
           String(format: "%X", Int(color.blueComponent * 255)) +
           String(format: "%X", Int(color.alphaComponent * 255))
  }

  func brightening(by factor: CGFloat) -> NSColor {
    let h = self.hueComponent
    let s = self.saturationComponent
    let b = self.brightnessComponent
    let a = self.alphaComponent

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
    let document = CMDocument(data: markdown.data(using: .utf8), options: .normalize)

    let attrs = CMTextAttributes()
    attrs?.textAttributes = [
      NSAttributedString.Key.font: NSFont.systemFont(ofSize: size),
      NSAttributedString.Key.foregroundColor: NSColor.gray,
    ]
    attrs?.inlineCodeAttributes = [
      NSAttributedString.Key.font: NSFont.userFixedPitchFont(ofSize: size)!,
      NSAttributedString.Key.foregroundColor: NSColor.gray,
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

extension NSFontManager {

  func monospacedRegularFontNames() -> [String] {
    self
      .availableFontFamilies
      .compactMap { name -> [(String, [Any])]? in
        guard let members = self.availableMembers(ofFontFamily: name) else { return nil }
        return members.map { member in (name, member) }
      }
      .flatMap { $0 }
      .filter { element in
        guard let trait = element.1[3] as? NSNumber,
              let weight = element.1[2] as? NSNumber,
              trait.uint32Value == NSFontDescriptor.SymbolicTraits.monoSpace.rawValue,
              weight.intValue == regularWeight
          else { return false }

        return true
      }
      .map { $0.0 }
      .uniqueing()
  }
}

private let regularWeight = 5
