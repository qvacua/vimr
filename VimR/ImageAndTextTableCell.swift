/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import PureLayout

class ImageAndTextTableCell: NSView {

  var text: NSAttributedString {
    get {
      return self.textField.attributedStringValue
    }

    set {
      self.textField.attributedStringValue = newValue
    }
  }

  var image: NSImage? {
    get {
      return self.imageView.image
    }

    set {
      self.imageView.image = newValue
    }
  }
  
  private let textField: NSTextField = NSTextField(forAutoLayout: ())
  private let imageView: NSImageView = NSImageView(forAutoLayout: ())
  
  init(withIdentifier identifier: String) {
    super.init(frame: CGRect.zero)
    
    self.identifier = identifier
    
    let textField = self.textField
    textField.bordered = false
    textField.editable = false
    textField.lineBreakMode = .ByTruncatingTail
    textField.drawsBackground = false
    
    let imageView = self.imageView
    
    self.addSubview(textField)
    self.addSubview(imageView)
    
    imageView.autoPinEdgeToSuperviewEdge(.Top, withInset: 2)
    imageView.autoPinEdgeToSuperviewEdge(.Left, withInset: 2)
    imageView.autoSetDimension(.Width, toSize: 16)
    imageView.autoSetDimension(.Height, toSize: 16)
    
    textField.autoPinEdgeToSuperviewEdge(.Top, withInset: 2)
    textField.autoPinEdgeToSuperviewEdge(.Right, withInset: 2)
    textField.autoPinEdgeToSuperviewEdge(.Bottom, withInset: 2)
    textField.autoPinEdge(.Left, toEdge: .Right, ofView: imageView, withOffset: 4)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}