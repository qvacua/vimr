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

  static func standardSourceListTableView() -> NSTableView {
    let tableView = NSTableView(frame: CGRect.zero)

    tableView.addTableColumn(NSTableColumn.standardCellBasedColumn(withName: "name"))
    tableView.rowSizeStyle	=	.Default
    tableView.sizeLastColumnToFit()
    tableView.allowsEmptySelection = false
    tableView.allowsMultipleSelection = false
    tableView.headerView = nil
    tableView.focusRingType = .None
    tableView.selectionHighlightStyle = .SourceList

    return tableView
  }
}

extension NSTableColumn {

  static func standardCellBasedColumn(withName name: String) -> NSTableColumn {
    let tableColumn = NSTableColumn(identifier: name)
    
    let textFieldCell = NSTextFieldCell()
    textFieldCell.allowsEditingTextAttributes = false
    textFieldCell.lineBreakMode = .ByTruncatingTail
    tableColumn.dataCell = textFieldCell

    return tableColumn
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
