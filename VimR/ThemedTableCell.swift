/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import PureLayout

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

  override var backgroundStyle: NSBackgroundStyle {
    didSet {
      let attrStr = NSMutableAttributedString(attributedString: self.attributedText)

      let wholeRange = NSRange(location: 0, length: attrStr.length)
      var nameRange = NSRange(location: 0, length: 0)
      let _ = attrStr.attributes(at: 0, longestEffectiveRange: &nameRange, in: wholeRange)

      if nameRange.length == attrStr.length {
        // If we only have one style, Cocoa automatically inverts the color of the text.
        return
      }

      switch self.backgroundStyle {
      case .light:
        attrStr.addAttribute(NSForegroundColorAttributeName, value: NSColor.black, range: nameRange)

      case .dark:
        attrStr.addAttribute(NSForegroundColorAttributeName, value: NSColor.white, range: nameRange)

      default:
        return
      }

      self.attributedText = attrStr
    }
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
