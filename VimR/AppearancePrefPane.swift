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

func == (left: AppearancePrefData, right: AppearancePrefData) -> Bool {
  return left.editorUsesLigatures == right.editorUsesLigatures && left.editorFont.isEqualTo(right.editorFont)
}

func != (left: AppearancePrefData, right: AppearancePrefData) -> Bool {
  return !(left == right)
}

class AppearancePrefPane: PrefPane, NSComboBoxDelegate, NSControlTextEditingDelegate {
  
  override var pinToContainer: Bool {
    return true
  }

  private var data: AppearancePrefData {
    willSet {
      self.updateViews(newData: newValue)
    }

    didSet {
      self.publish(event: self.data)
    }
  }

  private let fontManager = NSFontManager.sharedFontManager()

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

  init(source: Observable<Any>, initialData: AppearancePrefData) {
    self.data = initialData
    super.init(source: source)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func subscription(source source: Observable<Any>) -> Disposable {
    return source
      .filter { $0 is PrefData }
      .map { ($0 as! PrefData).appearance }
      .filter { [unowned self] data in data != self.data }
      .subscribeNext { [unowned self] data in self.data = data }
  }

  override func addViews() {
    let paneTitle = self.paneTitleTextField(title: "Appearance")

    let fontTitle = self.titleTextField(title: "Default Font:")

    let fontPopup = self.fontPopup
    fontPopup.translatesAutoresizingMaskIntoConstraints = false
    fontPopup.target = self
    fontPopup.action = #selector(AppearancePrefPane.fontPopupAction)
    fontPopup.addItemsWithTitles(self.fontManager.availableFontNamesWithTraits(.FixedPitchFontMask)!)

    let sizeCombo = self.sizeCombo
    sizeCombo.setDelegate(self)
    sizeCombo.target = self
    sizeCombo.action = #selector(AppearancePrefPane.sizeComboBoxDidEnter(_:))
    self.sizes.forEach { string in
      sizeCombo.addItemWithObjectValue(string)
    }

    let ligatureCheckbox = self.ligatureCheckbox
    self.configureCheckbox(button: ligatureCheckbox,
                           title: "Use Ligatures",
                           action: #selector(AppearancePrefPane.usesLigaturesAction(_:)))

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

    self.addSubview(paneTitle)

    self.addSubview(fontTitle)
    self.addSubview(fontPopup)
    self.addSubview(sizeCombo)
    self.addSubview(ligatureCheckbox)
    self.addSubview(previewScrollView)

    paneTitle.autoPinEdgeToSuperviewEdge(.Top, withInset: 18)
    paneTitle.autoPinEdgeToSuperviewEdge(.Left, withInset: 18)

    fontTitle.autoPinEdge(.Left, toEdge: .Left, ofView: paneTitle)
    fontTitle.autoAlignAxis(.Baseline, toSameAxisOfView: fontPopup)

    fontPopup.autoPinEdge(.Top, toEdge: .Bottom, ofView: paneTitle, withOffset: 18)
    fontPopup.autoPinEdge(.Left, toEdge: .Right, ofView: fontTitle, withOffset: 5)
    fontPopup.autoSetDimension(.Width, toSize: 240)

    sizeCombo.autoSetDimension(.Width, toSize: 60)
    // If we use .Baseline the combo box is placed one pixel off...
    sizeCombo.autoAlignAxis(.Horizontal, toSameAxisOfView: fontPopup)
    sizeCombo.autoPinEdge(.Left, toEdge: .Right, ofView: fontPopup, withOffset: 5)

    ligatureCheckbox.autoPinEdge(.Top, toEdge: .Bottom, ofView: sizeCombo, withOffset: 18)
    ligatureCheckbox.autoPinEdge(.Left, toEdge: .Right, ofView: fontTitle, withOffset: 5)

    previewScrollView.autoSetDimension(.Height, toSize: 200, relation: .GreaterThanOrEqual)
    previewScrollView.autoPinEdge(.Top, toEdge: .Bottom, ofView: ligatureCheckbox, withOffset: 18)
    previewScrollView.autoPinEdgeToSuperviewEdge(.Right, withInset: 18)
    previewScrollView.autoPinEdgeToSuperviewEdge(.Bottom, withInset: 18)
    previewScrollView.autoPinEdgeToSuperviewEdge(.Left, withInset: 18)

    self.fontPopup.selectItemWithTitle(self.data.editorFont.fontName)
    self.sizeCombo.stringValue = String(Int(self.data.editorFont.pointSize))
    self.ligatureCheckbox.state = self.data.editorUsesLigatures ? NSOnState : NSOffState
    self.previewArea.font = self.data.editorFont
    if self.data.editorUsesLigatures {
      self.previewArea.useAllLigatures(self)
    } else {
      self.previewArea.turnOffLigatures(self)
    }
  }

  private func updateViews(newData newData: AppearancePrefData) {
    let oldFont = self.data.editorFont
    let newFont = newData.editorFont
    let ligatureValueDiffers = newData.editorUsesLigatures != self.data.editorUsesLigatures

    call(self.fontPopup.selectItemWithTitle(newFont.fontName), whenNot: newFont.fontName == oldFont.fontName)
    call(self.sizeCombo.stringValue = String(Int(newFont.pointSize)), whenNot: newFont.pointSize == oldFont.pointSize)
    call(self.ligatureCheckbox.boolState = newData.editorUsesLigatures, when: ligatureValueDiffers)
    call(self.previewArea.font = newData.editorFont, whenNot: newFont.isEqualTo(self.data.editorFont))
    if ligatureValueDiffers {
      if newData.editorUsesLigatures {
        self.previewArea.useAllLigatures(self)
      } else {
        self.previewArea.turnOffLigatures(self)
      }
    }
  }
}

// MARK: - Actions
extension AppearancePrefPane {
  
  func usesLigaturesAction(sender: NSButton) {
    self.data = AppearancePrefData(editorFont: self.data.editorFont, editorUsesLigatures: sender.boolState)
  }

  func fontPopupAction(sender: NSPopUpButton) {
    guard let selectedItem = self.fontPopup.selectedItem else {
      return
    }

    guard selectedItem != self.data.editorFont.fontName else {
      return
    }

    guard let newFont = NSFont(name: selectedItem.title, size: self.data.editorFont.pointSize) else {
      return
    }

    self.data = AppearancePrefData(editorFont: newFont, editorUsesLigatures: self.data.editorUsesLigatures)
  }

  func comboBoxSelectionDidChange(notification: NSNotification) {
    guard notification.object! === self.sizeCombo else {
      return
    }

    let newFontSize = self.cappedFontSize(Int(self.sizes[self.sizeCombo.indexOfSelectedItem]))
    let newFont = self.fontManager.convertFont(self.data.editorFont, toSize: newFontSize)

    self.data = AppearancePrefData(editorFont: newFont, editorUsesLigatures: self.data.editorUsesLigatures)
  }

  func sizeComboBoxDidEnter(sender: AnyObject!) {
    let newFontSize = self.cappedFontSize(self.sizeCombo.integerValue)
    let newFont = self.fontManager.convertFont(self.data.editorFont, toSize: newFontSize)

    self.data = AppearancePrefData(editorFont: newFont, editorUsesLigatures: self.data.editorUsesLigatures)
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
