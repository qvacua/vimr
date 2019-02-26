/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa

class ShortcutTableRow: NSTableRowView {

  init(withIdentifier identifier: String) {
    super.init(frame: .zero)
    self.identifier = NSUserInterfaceItemIdentifier(identifier)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

class ShortcutTableCell: NSTableCellView {

  static let font = NSFont.systemFont(ofSize: 13)
  static let boldFont = NSFont.boldSystemFont(ofSize: 13)

  var isDir = false {
    didSet {
      if self.isDir {
        self.textField?.font = ShortcutTableCell.boldFont
      } else {
        self.textField?.font = ShortcutTableCell.font
      }
    }
  }

  var attributedText: NSAttributedString {
    get {
      return self.textField!.attributedStringValue
    }

    set {
      self.textField?.attributedStringValue = newValue
      self.addTextField()
    }
  }

  var text: String {
    get {
      return self.textField!.stringValue
    }

    set {
      if self.isDir {
        self.textField?.font = ShortcutTableCell.boldFont
      } else {
        self.textField?.font = ShortcutTableCell.font
      }
      self.textField?.stringValue = newValue
      self.addTextField()
    }
  }

  init(withIdentifier identifier: String) {
    super.init(frame: .zero)

    self.identifier = NSUserInterfaceItemIdentifier(identifier)

    self.textField = self._textField

    let textField = self._textField
    textField.font = ShortcutTableCell.font
    textField.isBordered = false
    textField.isBezeled = false
    textField.allowsEditingTextAttributes = false
    textField.isEditable = false
    textField.usesSingleLineMode = true
    textField.drawsBackground = false
  }

  func reset() -> ShortcutTableCell {
    self.text = ""
    self.removeAllSubviews()
    return self
  }

  private func addTextField() {
    let textField = self._textField

    textField.removeFromSuperview()
    self.addSubview(textField)

    textField.autoPinEdgesToSuperviewEdges(
      with: NSEdgeInsets(top: 2, left: 4, bottom: 2, right: 2)
    )
  }

  private let _textField = NSTextField(forAutoLayout: ())

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
