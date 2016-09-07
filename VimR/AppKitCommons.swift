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

extension NSTableView {

  static func standardTableView() -> NSTableView {
    let tableView = NSTableView(frame: CGRect.zero)

    tableView.addTableColumn(NSTableColumn(identifier: "name"))
    tableView.rowSizeStyle	=	.Default
    tableView.sizeLastColumnToFit()
    tableView.allowsEmptySelection = false
    tableView.allowsMultipleSelection = false
    tableView.headerView = nil
    tableView.focusRingType = .None

    return tableView
  }

  static func standardSourceListTableView() -> NSTableView {
    let tableView = self.standardTableView()
    tableView.selectionHighlightStyle = .SourceList

    return tableView
  }
}

extension NSScrollView {

  static func standardScrollView() -> NSScrollView {
    let scrollView = NSScrollView(frame: CGRect.zero)

    scrollView.translatesAutoresizingMaskIntoConstraints = false
    scrollView.hasVerticalScroller = true
    scrollView.hasHorizontalScroller = true
    scrollView.autohidesScrollers = true
    scrollView.borderType = .BezelBorder

    return scrollView
  }
}
