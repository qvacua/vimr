/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import PureLayout

class ImageAndTextTableCell: NSTableCellView {

  static let font = NSFont.systemFont(ofSize: 12)
  static let widthWithoutText = CGFloat(2 + 16 + 4 + 2)

  fileprivate let _textField = NSTextField(forAutoLayout: ())
  fileprivate let _imageView = NSImageView(forAutoLayout: ())

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
    super.init(frame: CGRect.zero)
    
    self.identifier = identifier

    self.textField = self._textField
    self.imageView = self._imageView

    let textField = self._textField
    textField.font = ImageAndTextTableCell.font
    textField.isBordered = false
    textField.isBezeled = false
    textField.allowsDefaultTighteningForTruncation = true
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
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
