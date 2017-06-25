/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import SwiftNeoVim
import PureLayout

protocol ThemedView: class {

  var theme: NeoVimView.Theme { get }
}

class ThemedTableRow: NSTableRowView {

  init(withIdentifier identifier: String, themedView: ThemedView) {
    self.themedView = themedView

    super.init(frame: .zero)

    self.identifier = identifier
  }

  open override func drawBackground(in dirtyRect: NSRect) {
    if let cell = self.view(atColumn: 0) as? ThemedTableCell {
      cell.textField?.textColor = self.themedView?.theme.foreground ?? NeoVimView.Theme.default.foreground
    }

    self.themedView?.theme.background.set()
    NSRectFill(dirtyRect)
  }

  override func drawSelection(in dirtyRect: NSRect) {
    if let cell = self.view(atColumn: 0) as? ThemedTableCell {
      cell.textField?.textColor = self.themedView?.theme.visualForeground ?? NeoVimView.Theme.default.visualForeground
    }

    self.themedView?.theme.visualBackground.set()
    NSRectFill(dirtyRect)
  }

  fileprivate weak var themedView: ThemedView?

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

class ThemedTableCell: NSTableCellView {

  // MARK: - API
  static let font = NSFont.systemFont(ofSize: 12)
  static let widthWithoutText = CGFloat(2 + 16 + 4 + 2)

  static func width(with text: String) -> CGFloat {
    let attrStr = NSAttributedString(string: text, attributes: [NSFontAttributeName: ThemedTableCell.font])

    return self.widthWithoutText + attrStr.size().width
  }

  override var intrinsicContentSize: CGSize {
    return CGSize(width: ThemedTableCell.widthWithoutText + self._textField.intrinsicContentSize.width,
                  height: max(self._textField.intrinsicContentSize.height, 16))
  }

  var attributedText: NSAttributedString {
    get {
      return self.textField!.attributedStringValue
    }

    set {
      self.textField?.attributedStringValue = newValue
    }
  }

  var text: String {
    get {
      return self.textField!.stringValue
    }

    set {
      self.textField?.stringValue = newValue
    }
  }

  var image: NSImage? {
    get {
      return self.imageView?.image
    }

    set {
      self.imageView?.image = newValue
    }
  }

  init(withIdentifier identifier: String) {
    super.init(frame: .zero)

    self.identifier = identifier

    self.textField = self._textField
    self.imageView = self._imageView

    let textField = self._textField
    textField.font = ThemedTableCell.font
    textField.isBordered = false
    textField.isBezeled = false
    textField.allowsEditingTextAttributes = false
    textField.isEditable = false
    textField.usesSingleLineMode = true
    textField.drawsBackground = false

    let imageView = self._imageView

    self.addSubview(textField)
    self.addSubview(imageView)

    imageView.autoPinEdge(toSuperviewEdge: .top, withInset: 2)
    imageView.autoPinEdge(toSuperviewEdge: .left, withInset: 2)
    imageView.autoSetDimension(.width, toSize: 16)
    imageView.autoSetDimension(.height, toSize: 16)

    textField.autoPinEdge(toSuperviewEdge: .top, withInset: 2)
    textField.autoPinEdge(toSuperviewEdge: .right, withInset: 2)
    textField.autoPinEdge(toSuperviewEdge: .bottom, withInset: 2)
    textField.autoPinEdge(.left, to: .right, of: imageView, withOffset: 4)
  }

  func reset() -> ThemedTableCell {
    self.text = ""
    self.image = nil

    return self
  }

  fileprivate let _textField = NSTextField(forAutoLayout: ())
  fileprivate let _imageView = NSImageView(forAutoLayout: ())

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
