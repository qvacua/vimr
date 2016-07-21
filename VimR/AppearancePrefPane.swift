/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import PureLayout
import RxSwift

struct AppearancePrefData {
  let editorFont: NSFont
}

class AppearancePrefPane: NSView, NSComboBoxDelegate, NSControlTextEditingDelegate, ViewComponent {

  private let source: Observable<Any>
  private let disposeBag = DisposeBag()

  private let subject = PublishSubject<Any>()
  var sink: Observable<Any> {
    return self.subject.asObservable()
  }

  var view: NSView {
    return self
  }

  private let sizes = [9, 10, 11, 12, 13, 14, 16, 18, 24, 36, 48, 64]
  private let sizeCombo = NSComboBox(forAutoLayout: ())
  private let fontPopup = NSPopUpButton(frame: CGRect.zero, pullsDown: false)
  private let previewArea = NSTextField(forAutoLayout: ())

  private var font: NSFont
  private var fontSize = CGFloat(13)
  private var fontName = "Menlo"

  // Return true to place this to the upper left corner when the scroll view is bigger than this view.
  override var flipped: Bool {
    return true
  }

  init(source: Observable<Any>, data: AppearancePrefData) {
    self.source = source

    self.font = data.editorFont
    self.fontSize = data.editorFont.pointSize
    self.fontName = data.editorFont.fontName

    super.init(frame: CGRect.zero)
    self.translatesAutoresizingMaskIntoConstraints = false

    self.wantsLayer = true
    self.layer?.backgroundColor = NSColor.yellowColor().CGColor
    self.addViews()
  }

  deinit {
    self.subject.onCompleted()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func addViews() {
    let fontTitle = NSTextField(forAutoLayout: ())
    fontTitle.backgroundColor = NSColor.clearColor();
    fontTitle.stringValue = "Default Font:";
    fontTitle.editable = false;
    fontTitle.bordered = false;
    fontTitle.alignment = .Right;

    let fontManager = NSFontManager.sharedFontManager()
    let fontPopup = self.fontPopup
    fontPopup.translatesAutoresizingMaskIntoConstraints = false
    fontPopup.target = self
    fontPopup.action = #selector(AppearancePrefPane.fontPopupAction)
    fontPopup.addItemsWithTitles(fontManager.availableFontNamesWithTraits(.FixedPitchFontMask)!)

    let sizeCombo = self.sizeCombo
    sizeCombo.setDelegate(self)
    self.sizes.forEach { string in
      sizeCombo.addItemWithObjectValue(string)
    }

    let previewArea = self.previewArea
    previewArea.editable = false
    previewArea.bezeled = true
    previewArea.bezelStyle = .SquareBezel
    previewArea.allowsEditingTextAttributes = false
    previewArea.drawsBackground = true
    previewArea.backgroundColor = NSColor.whiteColor()
    previewArea.lineBreakMode = .ByTruncatingTail
    previewArea.font = self.font
    previewArea.stringValue =
        "abcdefghijklmnopqrstuvwxyz\n" +
        "ABCDEFGHIJKLMNOPQRSTUVWXYZ\n" +
        "0123456789\n" +
        "(){}[] +-*/= .,;:!?#&$%@|^\n" +
        "<- -> => >> << >>= =<< .. \n" +
        ":: -< >- -<< >>- ++ /= =="

    self.addSubview(fontTitle)
    self.addSubview(fontPopup)
    self.addSubview(sizeCombo)
    self.addSubview(previewArea)

    fontTitle.autoPinEdgeToSuperviewEdge(.Left, withInset: 18)
    fontTitle.autoAlignAxis(.Baseline, toSameAxisOfView: fontPopup)

    fontPopup.autoPinEdgeToSuperviewEdge(.Top, withInset: 18)
    fontPopup.autoPinEdge(.Left, toEdge: .Right, ofView: fontTitle, withOffset: 5)
    fontPopup.autoSetDimension(.Width, toSize: 180)

    sizeCombo.autoSetDimension(.Width, toSize: 75)
    // If we use .Baseline the combo box is placed one pixel off...
    sizeCombo.autoAlignAxis(.Horizontal, toSameAxisOfView: fontPopup)
    sizeCombo.autoPinEdgeToSuperviewEdge(.Right, withInset: 18)
    sizeCombo.autoPinEdge(.Left, toEdge: .Right, ofView: fontPopup, withOffset: 5)

    previewArea.autoSetDimension(.Height, toSize: 150)
    previewArea.autoPinEdge(.Top, toEdge: .Bottom, ofView: fontPopup, withOffset: 18)
    previewArea.autoPinEdgeToSuperviewEdge(.Bottom, withInset: 18)
    previewArea.autoPinEdge(.Right, toEdge: .Right, ofView: sizeCombo)
    previewArea.autoPinEdgeToSuperviewEdge(.Left, withInset: 18)

    fontPopup.selectItemWithTitle(self.fontName)
    sizeCombo.stringValue = String(Int(self.fontSize))
  }
}

// MARK: - Actions
extension AppearancePrefPane {

  func fontPopupAction(sender: NSPopUpButton) {
    if let selectedItem = self.fontPopup.selectedItem {
      self.fontName = selectedItem.title
    } else {
      self.fontName = "Menlo"
    }

    self.publishData()
  }

  func comboBoxSelectionDidChange(notification: NSNotification) {
    guard notification.object! === self.sizeCombo else {
      return
    }

    self.fontSize = self.cappedFontSize(Int(self.sizes[self.sizeCombo.indexOfSelectedItem]))
    self.publishData()
  }

  override func controlTextDidChange(notification: NSNotification) {
    guard notification.object! === self.sizeCombo else {
      return
    }

    self.fontSize = self.cappedFontSize(self.sizeCombo.integerValue)
    self.publishData()
  }

  private func publishData() {
    guard let font = NSFont(name: self.fontName, size: CGFloat(self.fontSize)) else {
      return
    }

    self.font = font
    self.previewArea.font = font
    self.subject.onNext(AppearancePrefData(editorFont: font))
  }

  private func cappedFontSize(size: Int) -> CGFloat {
    guard size >= 4 else {
      return 13
    }

    guard size <= 128 else {
      return 128
    }

    return CGFloat(size)
  }
}
