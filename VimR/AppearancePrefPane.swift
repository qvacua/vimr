/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import PureLayout
import RxSwift

struct AppearancePrefData: Equatable {
  let editorFont: NSFont
  let editorUsesLigatures: Bool
}

func == (left: AppearancePrefData, right: AppearancePrefData) -> Bool {
  return left.editorUsesLigatures == right.editorUsesLigatures && left.editorFont.isEqual(to: right.editorFont)
}

class AppearancePrefPane: PrefPane, NSComboBoxDelegate, NSControlTextEditingDelegate {

  override var displayName: String {
    return "Appearance"
  }
  
  override var pinToContainer: Bool {
    return true
  }

  fileprivate var data: AppearancePrefData {
    didSet {
      self.updateViews(newData: self.data)
    }
  }

  fileprivate let fontManager = NSFontManager.shared()

  fileprivate let sizes = [9, 10, 11, 12, 13, 14, 16, 18, 24, 36, 48, 64]
  fileprivate let sizeCombo = NSComboBox(forAutoLayout: ())
  fileprivate let fontPopup = NSPopUpButton(frame: CGRect.zero, pullsDown: false)
  fileprivate let ligatureCheckbox = NSButton(forAutoLayout: ())
  fileprivate let previewArea = NSTextView(frame: CGRect.zero)

  fileprivate let exampleText =
    "abcdefghijklmnopqrstuvwxyz\n" +
    "ABCDEFGHIJKLMNOPQRSTUVWXYZ\n" +
    "0123456789\n" +
    "(){}[] +-*/= .,;:!?#&$%@|^\n" +
    "<- -> => >> << >>= =<< .. \n" +
    ":: -< >- -<< >>- ++ /= =="

  init(source: Observable<Any>, initialData: AppearancePrefData) {
    self.data = initialData
    super.init(source: source)

    self.updateViews(newData: initialData)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  fileprivate func set(data: AppearancePrefData) {
    self.data = data
    self.publish(event: data)
  }

  override func subscription(source: Observable<Any>) -> Disposable {
    return source
      .filter { $0 is PrefData }
      .map { ($0 as! PrefData).appearance }
      .filter { [unowned self] data in data != self.data }
      .subscribe(onNext: { [unowned self] data in
        self.data = data
    })
  }

  override func addViews() {
    let paneTitle = self.paneTitleTextField(title: "Appearance")

    let fontTitle = self.titleTextField(title: "Default Font:")

    let fontPopup = self.fontPopup
    fontPopup.translatesAutoresizingMaskIntoConstraints = false
    fontPopup.target = self
    fontPopup.action = #selector(AppearancePrefPane.fontPopupAction)
    fontPopup.addItems(withTitles: self.fontManager.availableFontNames(with: .fixedPitchFontMask)!)

    let sizeCombo = self.sizeCombo
    sizeCombo.delegate = self
    sizeCombo.target = self
    sizeCombo.action = #selector(AppearancePrefPane.sizeComboBoxDidEnter(_:))
    self.sizes.forEach { string in
      sizeCombo.addItem(withObjectValue: string)
    }

    let ligatureCheckbox = self.ligatureCheckbox
    self.configureCheckbox(button: ligatureCheckbox,
                           title: "Use Ligatures",
                           action: #selector(AppearancePrefPane.usesLigaturesAction(_:)))

    let previewArea = self.previewArea
    previewArea.isEditable = true
    previewArea.maxSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
    previewArea.isVerticallyResizable = true
    previewArea.isHorizontallyResizable = true
    previewArea.textContainer?.heightTracksTextView = false
    previewArea.textContainer?.widthTracksTextView = false
    previewArea.autoresizingMask = [ .viewWidthSizable, .viewHeightSizable]
    previewArea.textContainer?.containerSize = CGSize.init(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
    previewArea.layoutManager?.replaceTextStorage(NSTextStorage(string: self.exampleText))
    previewArea.isRichText = false
    previewArea.turnOffLigatures(self)

    let previewScrollView = NSScrollView(forAutoLayout: ())
    previewScrollView.hasVerticalScroller = true
    previewScrollView.hasHorizontalScroller = true
    previewScrollView.autohidesScrollers = true
    previewScrollView.borderType = .bezelBorder
    previewScrollView.documentView = previewArea

    self.addSubview(paneTitle)

    self.addSubview(fontTitle)
    self.addSubview(fontPopup)
    self.addSubview(sizeCombo)
    self.addSubview(ligatureCheckbox)
    self.addSubview(previewScrollView)

    paneTitle.autoPinEdge(toSuperviewEdge: .top, withInset: 18)
    paneTitle.autoPinEdge(toSuperviewEdge: .left, withInset: 18)

    fontTitle.autoPinEdge(.left, to: .left, of: paneTitle)
    fontTitle.autoAlignAxis(.baseline, toSameAxisOf: fontPopup)

    fontPopup.autoPinEdge(.top, to: .bottom, of: paneTitle, withOffset: 18)
    fontPopup.autoPinEdge(.left, to: .right, of: fontTitle, withOffset: 5)
    fontPopup.autoSetDimension(.width, toSize: 240)

    sizeCombo.autoSetDimension(.width, toSize: 60)
    // If we use .Baseline the combo box is placed one pixel off...
    sizeCombo.autoAlignAxis(.horizontal, toSameAxisOf: fontPopup)
    sizeCombo.autoPinEdge(.left, to: .right, of: fontPopup, withOffset: 5)

    ligatureCheckbox.autoPinEdge(.top, to: .bottom, of: sizeCombo, withOffset: 18)
    ligatureCheckbox.autoPinEdge(.left, to: .right, of: fontTitle, withOffset: 5)

    previewScrollView.autoSetDimension(.height, toSize: 200, relation: .greaterThanOrEqual)
    previewScrollView.autoPinEdge(.top, to: .bottom, of: ligatureCheckbox, withOffset: 18)
    previewScrollView.autoPinEdge(toSuperviewEdge: .right, withInset: 18)
    previewScrollView.autoPinEdge(toSuperviewEdge: .bottom, withInset: 18)
    previewScrollView.autoPinEdge(toSuperviewEdge: .left, withInset: 18)

    self.fontPopup.selectItem(withTitle: self.data.editorFont.fontName)
    self.sizeCombo.stringValue = String(Int(self.data.editorFont.pointSize))
    self.ligatureCheckbox.state = self.data.editorUsesLigatures ? NSOnState : NSOffState
    self.previewArea.font = self.data.editorFont
    if self.data.editorUsesLigatures {
      self.previewArea.useAllLigatures(self)
    } else {
      self.previewArea.turnOffLigatures(self)
    }
  }

  fileprivate func updateViews(newData: AppearancePrefData) {
    let newFont = newData.editorFont

    self.fontPopup.selectItem(withTitle: newFont.fontName)
    self.sizeCombo.stringValue = String(Int(newFont.pointSize))
    self.ligatureCheckbox.boolState = newData.editorUsesLigatures
    self.previewArea.font = newData.editorFont

    if newData.editorUsesLigatures {
      self.previewArea.useAllLigatures(self)
    } else {
      self.previewArea.turnOffLigatures(self)
    }
  }
}

// MARK: - Actions
extension AppearancePrefPane {
  
  func usesLigaturesAction(_ sender: NSButton) {
    self.set(data: AppearancePrefData(editorFont: self.data.editorFont, editorUsesLigatures: sender.boolState))
  }

  func fontPopupAction(_ sender: NSPopUpButton) {
    guard let selectedItem = self.fontPopup.selectedItem else {
      return
    }

    guard selectedItem.title != self.data.editorFont.fontName else {
      return
    }

    guard let newFont = NSFont(name: selectedItem.title, size: self.data.editorFont.pointSize) else {
      return
    }

    self.set(data: AppearancePrefData(editorFont: newFont, editorUsesLigatures: self.data.editorUsesLigatures))
  }

  func comboBoxSelectionDidChange(_ notification: Notification) {
    guard (notification.object as! NSComboBox) === self.sizeCombo else {
      return
    }

    let newFontSize = self.cappedFontSize(Int(self.sizes[self.sizeCombo.indexOfSelectedItem]))
    let newFont = self.fontManager.convert(self.data.editorFont, toSize: newFontSize)

    self.set(data: AppearancePrefData(editorFont: newFont, editorUsesLigatures: self.data.editorUsesLigatures))
  }

  func sizeComboBoxDidEnter(_ sender: AnyObject!) {
    let newFontSize = self.cappedFontSize(self.sizeCombo.integerValue)
    let newFont = self.fontManager.convert(self.data.editorFont, toSize: newFontSize)

    self.set(data: AppearancePrefData(editorFont: newFont, editorUsesLigatures: self.data.editorUsesLigatures))
  }

  fileprivate func cappedFontSize(_ size: Int) -> CGFloat {
    guard size >= 4 else {
      return 13
    }

    guard size <= 128 else {
      return 128
    }

    return CGFloat(size)
  }
}
