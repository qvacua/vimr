/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import PureLayout

class AppearancePrefPane: NSView, NSComboBoxDelegate, NSControlTextEditingDelegate {

  private let sizeCombo = NSComboBox(forAutoLayout: ())

  // Return true to place this to the upper left corner when the scroll view is bigger than this view.
  override var flipped: Bool {
    return true
  }

  override init(frame: NSRect) {
    super.init(frame: frame)

    self.wantsLayer = true
    self.layer?.backgroundColor = NSColor.yellowColor().CGColor
    self.addViews()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func sizeComboAction(sender: NSComboBox) {
    NSLog("JO")
  }

  private func addViews() {
    let fontTitle = NSTextField(forAutoLayout: ())
    fontTitle.backgroundColor = NSColor.clearColor();
    fontTitle.stringValue = "Default Font:";
    fontTitle.editable = false;
    fontTitle.bordered = false;
    fontTitle.alignment = .Right;

    let fontManager = NSFontManager.sharedFontManager()
    let fontPopup = NSPopUpButton(frame: CGRect.zero, pullsDown: false)
    fontPopup.translatesAutoresizingMaskIntoConstraints = false
    fontPopup.target = self
    fontPopup.addItemsWithTitles(fontManager.availableFontNamesWithTraits(.FixedPitchFontMask)!)

    let sizeCombo = self.sizeCombo
    sizeCombo.target = self
    sizeCombo.action = #selector(AppearancePrefPane.sizeComboAction(_:))
    sizeCombo.setDelegate(self)
    sizeCombo.addItemWithObjectValue("12")
    sizeCombo.addItemWithObjectValue("16")
    sizeCombo.addItemWithObjectValue("24")

    self.addSubview(fontTitle)
    self.addSubview(fontPopup)
    self.addSubview(sizeCombo)

    fontTitle.autoPinEdgeToSuperviewEdge(.Left, withInset: 18)
    fontTitle.autoAlignAxis(.Baseline, toSameAxisOfView: fontPopup)

    fontPopup.autoPinEdgeToSuperviewEdge(.Top, withInset: 18)
    fontPopup.autoPinEdge(.Left, toEdge: .Right, ofView: fontTitle, withOffset: 5)
    fontPopup.autoSetDimension(.Width, toSize: 180)

    sizeCombo.autoSetDimension(.Width, toSize: 75)
    sizeCombo.autoAlignAxis(.Horizontal, toSameAxisOfView: fontPopup) // .Baseline won't do...
    sizeCombo.autoPinEdgeToSuperviewEdge(.Right, withInset: 18)
    sizeCombo.autoPinEdgeToSuperviewEdge(.Bottom, withInset: 18)
    sizeCombo.autoPinEdge(.Left, toEdge: .Right, ofView: fontPopup, withOffset: 5)
  }
}

// MARK: - NSComboBoxDelegate
extension AppearancePrefPane {
  func comboBoxSelectionDidChange(notification: NSNotification) {
    guard notification.object! === self.sizeCombo else {
      return
    }

    NSLog("selection changed by menu")
  }

  override func controlTextDidChange(notification: NSNotification) {
    guard notification.object! === self.sizeCombo else {
      return
    }

    NSLog("text did changed")
  }
}
