/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import PureLayout
import RxSwift

struct AppearancePrefData {
  let editorFont: NSFont
  let editorUsesLigatures: Bool
}

class AppearancePrefPane: PrefPane, NSComboBoxDelegate, NSControlTextEditingDelegate {

  private let sizes = [9, 10, 11, 12, 13, 14, 16, 18, 24, 36, 48, 64]
  private let sizeCombo = NSComboBox(forAutoLayout: ())
  private let fontPopup = NSPopUpButton(frame: CGRect.zero, pullsDown: false)
  private let ligatureCheckbox = NSButton(forAutoLayout: ())
  private let previewArea = NSTextView(frame: CGRect.zero)

  private let exampleText =
    "abcdefghijklmnopqrstuvwxyz\n" +
    "ABCDEFGHIJKLMNOPQRSTUVWXYZ\n" +
    "0123456789\n" +
    "(){}[] +-*/= .,;:!?#&$%@|^\n" +
    "<- -> => >> << >>= =<< .. \n" +
    ":: -< >- -<< >>- ++ /= =="

  private var font: NSFont
  private var fontSize = CGFloat(13)
  private var fontName = "Menlo"
  private var usesLigatures = false

  init(source: Observable<Any>, initialData: AppearancePrefData) {
    self.font = initialData.editorFont
    self.fontSize = initialData.editorFont.pointSize
    self.fontName = initialData.editorFont.fontName
    self.usesLigatures = initialData.editorUsesLigatures

    super.init(source: source)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func subscription(source source: Observable<Any>) -> Disposable {
    return source
      .filter { $0 is PrefData }
      .map { ($0 as! PrefData).appearance }
      .filter { [unowned self] appearance in
        appearance.editorFont != self.font || appearance.editorUsesLigatures != self.usesLigatures
      }
      .subscribeNext { [unowned self] appearance in
        let editorFont = appearance.editorFont
        self.font = editorFont
        self.fontName = editorFont.fontName
        self.fontSize = editorFont.pointSize
        self.usesLigatures = appearance.editorUsesLigatures
        self.updateViews()
    }
  }

  override func addViews() {
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
    sizeCombo.target = self
    sizeCombo.action = #selector(AppearancePrefPane.sizeComboBoxDidEnter(_:))
    self.sizes.forEach { string in
      sizeCombo.addItemWithObjectValue(string)
    }
    
    let ligatureCheckbox = self.ligatureCheckbox
    ligatureCheckbox.title = "Use Ligatures"
    ligatureCheckbox.setButtonType(.SwitchButton)
    ligatureCheckbox.bezelStyle = .ThickSquareBezelStyle
    ligatureCheckbox.target = self
    ligatureCheckbox.action = #selector(AppearancePrefPane.usesLigaturesAction(_:))

    let previewArea = self.previewArea
    previewArea.editable = true
    previewArea.maxSize = CGSize(width: CGFloat.max, height: CGFloat.max)
    previewArea.verticallyResizable = true
    previewArea.horizontallyResizable = true
    previewArea.textContainer?.heightTracksTextView = false
    previewArea.textContainer?.widthTracksTextView = false
    previewArea.autoresizingMask = [ .ViewWidthSizable, .ViewHeightSizable]
    previewArea.textContainer?.containerSize = CGSize.init(width: CGFloat.max, height: CGFloat.max)
    previewArea.layoutManager?.replaceTextStorage(NSTextStorage(string: self.exampleText))
    previewArea.richText = false
    previewArea.turnOffLigatures(self)

    let previewScrollView = NSScrollView(forAutoLayout: ())
    previewScrollView.hasVerticalScroller = true
    previewScrollView.hasHorizontalScroller = true
    previewScrollView.autohidesScrollers = true
    previewScrollView.borderType = .BezelBorder
    previewScrollView.documentView = previewArea

    self.addSubview(fontTitle)
    self.addSubview(fontPopup)
    self.addSubview(sizeCombo)
    self.addSubview(ligatureCheckbox)
    self.addSubview(previewScrollView)

    fontTitle.autoPinEdgeToSuperviewEdge(.Left, withInset: 18)
    fontTitle.autoAlignAxis(.Baseline, toSameAxisOfView: fontPopup)

    fontPopup.autoPinEdgeToSuperviewEdge(.Top, withInset: 18)
    fontPopup.autoPinEdge(.Left, toEdge: .Right, ofView: fontTitle, withOffset: 5)
    fontPopup.autoSetDimension(.Width, toSize: 240)

    sizeCombo.autoSetDimension(.Width, toSize: 60)
    // If we use .Baseline the combo box is placed one pixel off...
    sizeCombo.autoAlignAxis(.Horizontal, toSameAxisOfView: fontPopup)
    sizeCombo.autoPinEdge(.Left, toEdge: .Right, ofView: fontPopup, withOffset: 5)

    ligatureCheckbox.autoPinEdge(.Top, toEdge: .Bottom, ofView: sizeCombo, withOffset: 18)
    ligatureCheckbox.autoPinEdge(.Left, toEdge: .Right, ofView: fontTitle, withOffset: 5)

    previewScrollView.autoSetDimension(.Height, toSize: 200)
    previewScrollView.autoPinEdge(.Top, toEdge: .Bottom, ofView: ligatureCheckbox, withOffset: 18)
    previewScrollView.autoPinEdgeToSuperviewEdge(.Right, withInset: 18)
    previewScrollView.autoPinEdgeToSuperviewEdge(.Bottom, withInset: 18)
    previewScrollView.autoPinEdgeToSuperviewEdge(.Left, withInset: 18)

    self.updateViews()
  }

  private func updateViews() {
    self.fontPopup.selectItemWithTitle(self.fontName)
    self.sizeCombo.stringValue = String(Int(self.fontSize))
    self.ligatureCheckbox.state = self.usesLigatures ? NSOnState : NSOffState
    self.previewArea.font = self.font
    if self.usesLigatures {
      self.previewArea.useAllLigatures(self)
    } else {
      self.previewArea.turnOffLigatures(self)
    }
  }
}

// MARK: - Actions
extension AppearancePrefPane {
  
  func usesLigaturesAction(sender: NSButton) {
    self.publishData()
  }

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

  func sizeComboBoxDidEnter(sender: AnyObject!) {
    self.fontSize = self.cappedFontSize(self.sizeCombo.integerValue)
    self.publishData()
  }

  private func publishData() {
    guard let font = NSFont(name: self.fontName, size: CGFloat(self.fontSize)) else {
      return
    }

    self.font = font
    self.usesLigatures = self.ligatureCheckbox.state == NSOnState
    self.updateViews()

    self.publish(event: AppearancePrefData(editorFont: font, editorUsesLigatures: usesLigatures))
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
