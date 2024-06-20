/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import NvimView
import PureLayout
import RxSwift

final class AppearancePref: PrefPane, NSComboBoxDelegate, NSControlTextEditingDelegate,
  NSFontChanging
{
  typealias StateType = AppState

  enum Action {
    case setUsesCustomTab(Bool)
    case setUsesColorscheme(Bool)
    case setShowsFileIcon(Bool)
    case setUsesLigatures(Bool)
    case setFont(NSFont)
    case setLinespacing(CGFloat)
    case setCharacterspacing(CGFloat)
    case setFontSmoothing(FontSmoothing)
  }

  override var displayName: String { "Appearance" }

  override var pinToContainer: Bool { true }

  override func windowWillClose() {
    self.linespacingAction()
    self.characterspacingAction()
  }

  override func paneWillAppear() {
    self.previewArea.textColor = NSColor.textColor
  }

  required init(source: Observable<StateType>, emitter: ActionEmitter, state: StateType) {
    self.emit = emitter.typedEmit()

    self.font = state.mainWindowTemplate.appearance.font
    self.linespacing = state.mainWindowTemplate.appearance.linespacing
    self.characterspacing = state.mainWindowTemplate.appearance.characterspacing
    self.usesLigatures = state.mainWindowTemplate.appearance.usesLigatures
    self.usesColorscheme = state.mainWindowTemplate.appearance.usesTheme
    self.showsFileIcon = state.mainWindowTemplate.appearance.showsFileIcon
    self.usesCustomTab = state.mainWindowTemplate.appearance.usesCustomTab
    self.fontSmoothing = state.mainWindowTemplate.appearance.fontSmoothing

    super.init(frame: .zero)

    self.addViews()
    self.updateViews()

    sharedFontManager.target = self

    source
      .observe(on: MainScheduler.instance)
      .subscribe(onNext: { state in
        let appearance = state.mainWindowTemplate.appearance

        guard self.font != appearance.font
          || self.linespacing != appearance.linespacing
          || self.characterspacing != appearance.characterspacing
          || self.fontSmoothing != appearance.fontSmoothing
          || self.usesLigatures != appearance.usesLigatures
          || self.usesColorscheme != appearance.usesTheme
          || self.showsFileIcon != appearance.showsFileIcon
        else { return }

        self.font = appearance.font
        self.linespacing = appearance.linespacing
        self.characterspacing = appearance.characterspacing
        self.fontSmoothing = appearance.fontSmoothing
        self.usesLigatures = appearance.usesLigatures
        self.usesColorscheme = appearance.usesTheme
        self.showsFileIcon = appearance.showsFileIcon

        self.updateViews()
      })
      .disposed(by: self.disposeBag)
  }

  private let emit: (Action) -> Void
  private let disposeBag = DisposeBag()

  private var font: NSFont
  private var linespacing: CGFloat
  private var characterspacing: CGFloat
  private var usesLigatures: Bool
  private var usesColorscheme: Bool
  private var showsFileIcon: Bool
  private var usesCustomTab: Bool
  private var fontSmoothing: FontSmoothing

  private let customTabCheckbox = NSButton(forAutoLayout: ())
  private let colorschemeCheckbox = NSButton(forAutoLayout: ())
  private let fileIconCheckbox = NSButton(forAutoLayout: ())
  private let fontPanelButton = NSButton(forAutoLayout: ())
  private let linespacingField = NSTextField(forAutoLayout: ())
  private let characterspacingField = NSTextField(forAutoLayout: ())
  private let fontSmoothingPopup = NSPopUpButton(forAutoLayout: ())
  private let ligatureCheckbox = NSButton(forAutoLayout: ())
  private let previewArea = NSTextView(frame: .zero)

  private let exampleText = #"""
  abcdefghijklmnopqrstuvwxyz
  ABCDEFGHIJKLMNOPQRSTUVWXYZ
  0123456789 -~ - ~
  (){}[] +-*/= .,;:!?#&$%@|^
  <- -> => >> << >>= =<< .. 
  :: -< >- -<< >>- ++ /= ==
  """#

  @available(*, unavailable)
  required init?(coder _: NSCoder) { fatalError("init(coder:) has not been implemented") }

  private func addViews() {
    let paneTitle = self.paneTitleTextField(title: "Appearance")

    let useCustomTab = self.customTabCheckbox
    self.configureCheckbox(
      button: useCustomTab,
      title: "Use custom tab implementation.",
      action: #selector(AppearancePref.usesCustomTabAction(_:))
    )

    let useColorscheme = self.colorschemeCheckbox
    self.configureCheckbox(
      button: useColorscheme,
      title: "Use Neovim's color scheme for main window and tools.",
      action: #selector(AppearancePref.usesColorschemeAction(_:))
    )

    let useColorschemeInfo = self.infoTextField(markdown: #"""
    If checked, the colors of the selected `colorscheme` will be used to render tools,\
    for example the file browser.
    """#)

    let fileIcon = self.fileIconCheckbox
    self.configureCheckbox(
      button: fileIcon,
      title: "Show file icons",
      action: #selector(AppearancePref.fileIconAction(_:))
    )

    let fileIconInfo = self.infoTextField(markdown: #"""
    In case the selected `colorscheme` does not play well with the file icons\
    in the file browser and the buffer list, you can turn them off.
    """#)

    let fontTitle = self.titleTextField(title: "Default Font:")
    let fontPanelButton = self.fontPanelButton
    fontPanelButton.bezelStyle = .rounded
    fontPanelButton.isBordered = true
    fontPanelButton.setButtonType(.momentaryPushIn)
    fontPanelButton.target = self
    fontPanelButton.action = #selector(AppearancePref.showFontPanel(_:))

    let fontInfo = self.infoTextField(markdown: #"""
    The font panel will show variable width fonts, but VimR does not support them.\
    If you select a variable width font, the rendering will be ... well ... questionable.
    """#)

    let linespacingTitle = self.titleTextField(title: "Line Spacing:")
    let linespacingField = self.linespacingField

    let characterspacingTitle = self.titleTextField(title: "Character Spacing:")
    let characterspacingField = self.characterspacingField

    let characterspacingInfo = self.infoTextField(
      markdown: "Character spacing not equal to `1` will likely break ligatures."
    )

    let ligatureCheckbox = self.ligatureCheckbox
    self.configureCheckbox(
      button: ligatureCheckbox,
      title: "Use Ligatures",
      action: #selector(AppearancePref.usesLigaturesAction(_:))
    )

    let fontSmoothingPopup = self.fontSmoothingPopup
    let fontSmoothingTitle = self.titleTextField(title: "Font Smoothing:")
    fontSmoothingPopup.target = self
    fontSmoothingPopup.action = #selector(AppearancePref.fontSmoothingAction)
    fontSmoothingPopup.addItems(withTitles: self.fontSmoothingTitles)
    let fontSmoothingInfo = self.infoTextField(markdown: #"""
    "No Font Smoothing" may result in better rendering for non-Retina displays.\
    If you're still using Monaco-9pt, choose "No Anti Aliasing" 😀 (you may want\
    to set character spacing to 1.2 then).
    """#)

    let previewArea = self.previewArea
    previewArea.isEditable = true
    previewArea.maxSize = CGSize(
      width: CGFloat.greatestFiniteMagnitude,
      height: CGFloat.greatestFiniteMagnitude
    )
    previewArea.isVerticallyResizable = true
    previewArea.isHorizontallyResizable = true
    previewArea.textContainer?.heightTracksTextView = false
    previewArea.textContainer?.widthTracksTextView = false
    previewArea.autoresizingMask = [.width, .height]
    previewArea.textContainer?.containerSize = CGSize(
      width: CGFloat.greatestFiniteMagnitude,
      height: CGFloat.greatestFiniteMagnitude
    )
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

    self.addSubview(useCustomTab)
    self.addSubview(useColorscheme)
    self.addSubview(useColorschemeInfo)
    self.addSubview(fileIcon)
    self.addSubview(fileIconInfo)
    self.addSubview(fontTitle)
    self.addSubview(fontPanelButton)
    self.addSubview(fontInfo)
    self.addSubview(linespacingTitle)
    self.addSubview(linespacingField)
    self.addSubview(characterspacingTitle)
    self.addSubview(characterspacingField)
    self.addSubview(characterspacingInfo)
    self.addSubview(ligatureCheckbox)
    self.addSubview(fontSmoothingTitle)
    self.addSubview(fontSmoothingPopup)
    self.addSubview(fontSmoothingInfo)
    self.addSubview(previewScrollView)

    paneTitle.autoPinEdge(toSuperviewEdge: .top, withInset: 18)
    paneTitle.autoPinEdge(toSuperviewEdge: .left, withInset: 18)

    useCustomTab.autoPinEdge(.left, to: .right, of: fontTitle, withOffset: 5)
    useCustomTab.autoPinEdge(.top, to: .bottom, of: paneTitle, withOffset: 18)

    useColorscheme.autoPinEdge(.left, to: .right, of: fontTitle, withOffset: 5)
    useColorscheme.autoPinEdge(.top, to: .bottom, of: useCustomTab, withOffset: 18)

    useColorschemeInfo.autoPinEdge(.top, to: .bottom, of: useColorscheme, withOffset: 5)
    useColorschemeInfo.autoPinEdge(.left, to: .left, of: useColorscheme)

    fileIcon.autoPinEdge(.left, to: .right, of: fontTitle, withOffset: 5)
    fileIcon.autoPinEdge(.top, to: .bottom, of: useColorschemeInfo, withOffset: 18)

    fileIconInfo.autoPinEdge(.top, to: .bottom, of: fileIcon, withOffset: 5)
    fileIconInfo.autoPinEdge(.left, to: .left, of: fileIcon)

    fontTitle.autoPinEdge(toSuperviewEdge: .left, withInset: 18, relation: .greaterThanOrEqual)
    fontTitle.autoAlignAxis(.baseline, toSameAxisOf: fontPanelButton)

    fontPanelButton.autoPinEdge(.top, to: .bottom, of: fileIconInfo, withOffset: 18)
    fontPanelButton.autoPinEdge(.left, to: .right, of: fontTitle, withOffset: 5)

    fontInfo.autoPinEdge(.top, to: .bottom, of: fontPanelButton, withOffset: 5)
    fontInfo.autoPinEdge(.left, to: .right, of: fontTitle, withOffset: 5)

    linespacingTitle.autoPinEdge(
      toSuperviewEdge: .left,
      withInset: 18,
      relation: .greaterThanOrEqual
    )
    linespacingTitle.autoPinEdge(.right, to: .right, of: fontTitle)
    linespacingTitle.autoAlignAxis(.baseline, toSameAxisOf: linespacingField)

    linespacingField.autoPinEdge(.top, to: .bottom, of: fontInfo, withOffset: 18)
    linespacingField.autoPinEdge(.left, to: .right, of: linespacingTitle, withOffset: 5)
    linespacingField.autoSetDimension(.width, toSize: 60)
    NotificationCenter.default.addObserver(
      forName: NSControl.textDidEndEditingNotification,
      object: linespacingField,
      queue: nil
    ) { [weak self] _ in self?.linespacingAction() }

    characterspacingTitle.autoPinEdge(
      toSuperviewEdge: .left,
      withInset: 18,
      relation: .greaterThanOrEqual
    )
    characterspacingTitle.autoPinEdge(.right, to: .right, of: linespacingTitle)
    characterspacingTitle.autoAlignAxis(.baseline, toSameAxisOf: characterspacingField)

    characterspacingField.autoPinEdge(.top, to: .bottom, of: linespacingField, withOffset: 18)
    characterspacingField.autoPinEdge(.left, to: .right, of: characterspacingTitle, withOffset: 5)
    characterspacingField.autoSetDimension(.width, toSize: 60)
    NotificationCenter.default.addObserver(
      forName: NSControl.textDidEndEditingNotification,
      object: characterspacingField,
      queue: nil
    ) { [weak self] _ in self?.characterspacingAction() }

    characterspacingInfo.autoPinEdge(.left, to: .left, of: characterspacingField)
    characterspacingInfo.autoPinEdge(.top, to: .bottom, of: characterspacingField, withOffset: 5)

    fontSmoothingTitle.autoPinEdge(.right, to: .right, of: characterspacingTitle)
    fontSmoothingTitle.autoAlignAxis(.baseline, toSameAxisOf: fontSmoothingPopup)

    fontSmoothingPopup.autoPinEdge(.top, to: .bottom, of: characterspacingInfo, withOffset: 18)
    fontSmoothingPopup.autoPinEdge(.left, to: .right, of: fontSmoothingTitle, withOffset: 5)

    fontSmoothingInfo.autoPinEdge(.left, to: .left, of: fontSmoothingPopup)
    fontSmoothingInfo.autoPinEdge(.top, to: .bottom, of: fontSmoothingPopup, withOffset: 5)

    ligatureCheckbox.autoPinEdge(.top, to: .bottom, of: fontSmoothingInfo, withOffset: 18)
    ligatureCheckbox.autoPinEdge(.left, to: .right, of: fontTitle, withOffset: 5)

    previewScrollView.autoSetDimension(.height, toSize: 120, relation: .greaterThanOrEqual)
    previewScrollView.autoPinEdge(.top, to: .bottom, of: ligatureCheckbox, withOffset: 18)
    previewScrollView.autoPinEdge(toSuperviewEdge: .right, withInset: 18)
    previewScrollView.autoPinEdge(toSuperviewEdge: .bottom, withInset: 18)
    previewScrollView.autoPinEdge(toSuperviewEdge: .left, withInset: 18)
  }

  private func updateViews() {
    sharedFontPanel.setPanelFont(self.font, isMultiple: false)
    self.fontPanelButton.title = self.font.displayName
      .map { "\($0) \(self.font.pointSize)" } ?? "Show fonts..."
    self.linespacingField.stringValue = String(format: "%.2f", self.linespacing)
    self.characterspacingField.stringValue = String(format: "%.2f", self.characterspacing)
    self.ligatureCheckbox.boolState = self.usesLigatures
    self.fontSmoothingPopup.selectItem(at: self.fontSmoothingToIndex(self.fontSmoothing))
    self.previewArea.font = self.font
    self.customTabCheckbox.boolState = self.usesCustomTab
    self.colorschemeCheckbox.boolState = self.usesColorscheme
    self.fileIconCheckbox.boolState = self.showsFileIcon

    if self.usesLigatures {
      self.previewArea.useAllLigatures(self)
    } else {
      self.previewArea.turnOffLigatures(self)
    }
  }

  // Keep the index in sync with indexToFontSmoothing() and fontSmoothingToIndex().
  private let fontSmoothingTitles = [
    "System Setting",
    "With Font Smoothing",
    "No Font Smoothing",
    "No Anti Aliasing",
  ]

  private func indexToFontSmoothing(_ index: Int) -> FontSmoothing {
    switch index {
    case 0: .systemSetting
    case 1: .withFontSmoothing
    case 2: .noFontSmoothing
    case 3: .noAntiAliasing
    default: .systemSetting
    }
  }

  private func fontSmoothingToIndex(_ fontSmoothing: FontSmoothing) -> Int {
    switch fontSmoothing {
    case .systemSetting: 0
    case .withFontSmoothing: 1
    case .noFontSmoothing: 2
    case .noAntiAliasing: 3
    }
  }
}

// MARK: - NSFontChanging

extension AppearancePref {
  func changeFont(_ sender: NSFontManager?) {
    guard let fontManager = sender else { return }
    let font = fontManager.convert(self.font)

    self.emit(.setFont(font))
  }
}

// MARK: - Actions

extension AppearancePref {
  @objc func usesCustomTabAction(_ sender: NSButton) {
    self.emit(.setUsesCustomTab(sender.boolState))
  }

  @objc func usesColorschemeAction(_ sender: NSButton) {
    self.emit(.setUsesColorscheme(sender.boolState))
  }

  @objc func fileIconAction(_ sender: NSButton) {
    self.emit(.setShowsFileIcon(sender.boolState))
  }

  @objc func usesLigaturesAction(_ sender: NSButton) {
    self.emit(.setUsesLigatures(sender.boolState))
  }

  @objc func showFontPanel(_ sender: NSButton) {
    sharedFontPanel.makeKeyAndOrderFront(sender)
  }

  func linespacingAction() {
    let newLinespacing = self.cappedLinespacing(self.linespacingField.doubleValue)
    self.emit(.setLinespacing(newLinespacing))
  }

  @objc func fontSmoothingAction(_: NSPopUpButton) {
    let index = self.fontSmoothingPopup.indexOfSelectedItem

    guard FontSmoothing.allCases.indices.contains(index) else { return }
    self.fontSmoothing = self.indexToFontSmoothing(index)
    self.emit(.setFontSmoothing(self.fontSmoothing))
  }

  private func cappedLinespacing(_ linespacing: Double) -> CGFloat {
    let cgfLinespacing = linespacing

    guard cgfLinespacing >= NvimView.minLinespacing else { return NvimView.defaultLinespacing }
    guard cgfLinespacing <= NvimView.maxLinespacing else { return NvimView.maxLinespacing }

    return cgfLinespacing
  }

  func characterspacingAction() {
    let newCharacterspacing = self.cappedCharacterspacing(self.characterspacingField.doubleValue)
    self.emit(.setCharacterspacing(newCharacterspacing))
  }

  private func cappedCharacterspacing(_ characterspacing: Double) -> Double {
    guard characterspacing >= 0.0 else { return NvimView.defaultCharacterspacing }

    return characterspacing
  }

  private func cappedFontSize(_ size: Int) -> CGFloat {
    let cgfSize = size.cgf

    guard cgfSize >= NvimView.minFontSize else { return NvimView.defaultFont.pointSize }
    guard cgfSize <= NvimView.maxFontSize else { return NvimView.maxFontSize }

    return cgfSize
  }
}

private let sharedFontManager = NSFontManager.shared
private let sharedFontPanel = NSFontPanel.shared
