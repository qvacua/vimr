/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import MaterialIcons

struct TabPosition: OptionSet {
  static let first = TabPosition(rawValue: 1 << 0)
  static let last = TabPosition(rawValue: 1 << 1)

  let rawValue: Int
}

class Tab<Rep: TabRepresentative>: NSView {
  var title: String { self.tabRepresentative.title }

  var tabRepresentative: Rep {
    willSet {
      if self.isSelected == newValue.isSelected { return }
      self.adjustToSelectionChange(newValue.isSelected)
    }
    didSet {
      if self.titleView.stringValue == self.title { return }
      self.titleView.stringValue = self.title
      self.adjustWidth()
    }
  }

  init(withTabRepresentative tabRepresentative: Rep, in tabBar: TabBar<Rep>) {
    self.tabBar = tabBar
    self.tabRepresentative = tabRepresentative

    super.init(frame: .zero)

    self.configureForAutoLayout()
    self.wantsLayer = true

    self.autoSetDimension(.height, toSize: self.theme.tabHeight)

    self.titleView.stringValue = tabRepresentative.title
    self.addViews()

    self.adjustToSelectionChange(self.tabRepresentative.isSelected)
    self.adjustWidth()
  }

  override func mouseUp(with _: NSEvent) { self.tabBar?.select(tab: self) }

  override func draw(_: NSRect) {
    self.drawSeparators()
    self.drawSelectionIndicator()
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) { fatalError("init(coder:) has not been implemented") }

  var position: TabPosition = [] {
    willSet { self.needsDisplay = self.position != newValue }
  }

  private weak var tabBar: TabBar<Rep>?

  private let closeButton = NSButton(forAutoLayout: ())
  private let titleView = NSTextField(forAutoLayout: ())

  private var widthConstraint: NSLayoutConstraint?
}

// MARK: - Private

extension Tab {
  private var isSelected: Bool { self.tabRepresentative.isSelected }
  private var theme: Theme {
    // We set tabBar in init, it's weak only because we want to avoid retain cycle.
    self.tabBar!.theme
  }

  // We need the arg since we are calling this function also in willSet.
  private func adjustToSelectionChange(_ newIsSelected: Bool) {
    if newIsSelected {
      self.layer?.backgroundColor = self.theme.selectedBackgroundColor.cgColor
      self.titleView.textColor = self.theme.selectedForegroundColor
      self.titleView.font = self.theme.selectedTitleFont
      self.closeButton.image = self.theme.selectedCloseButtonImage
    } else {
      self.layer?.backgroundColor = self.theme.backgroundColor.cgColor
      self.titleView.textColor = self.theme.foregroundColor
      self.titleView.font = self.theme.titleFont
      self.closeButton.image = self.theme.closeButtonImage
    }

    self.adjustWidth()
    self.needsDisplay = true
  }

  private func adjustWidth() {
    let idealWidth = 4 * self.theme.tabHorizontalPadding + 2 * self.theme.iconDimension.width
      + self.titleView.intrinsicContentSize.width
    let targetWidth = min(max(self.theme.tabMinWidth, idealWidth), self.theme.tabMaxWidth)
    if let c = self.widthConstraint { self.removeConstraint(c) }
    self.widthConstraint = self.autoSetDimension(.width, toSize: targetWidth)
  }

  private func addViews() {
    let close = self.closeButton
    let title = self.titleView

    self.addSubview(close)
    self.addSubview(title)

    close.imagePosition = .imageOnly
    close.image = self.theme.closeButtonImage
    close.isBordered = false
    (close.cell as? NSButtonCell)?.highlightsBy = .contentsCellMask

    title.drawsBackground = false
    title.font = self.theme.titleFont
    title.textColor = self.theme.foregroundColor
    title.isEditable = false
    title.isBordered = false
    title.isSelectable = false
    title.usesSingleLineMode = true
    title.lineBreakMode = .byTruncatingTail

    close.autoSetDimensions(to: self.theme.iconDimension)
    close.autoPinEdge(toSuperviewEdge: .left, withInset: self.theme.tabHorizontalPadding)
    close.autoAlignAxis(toSuperviewAxis: .horizontal)

    title.autoPinEdge(.left, to: .right, of: close, withOffset: self.theme.tabHorizontalPadding)
    title.autoPinEdge(toSuperviewEdge: .right, withInset: self.theme.tabHorizontalPadding)
    title.autoAlignAxis(toSuperviewAxis: .horizontal)
  }

  private func drawSeparators() {
    let b = self.bounds
    let left = CGRect(x: 0, y: 0, width: self.theme.separatorThickness, height: b.height)
    let right = CGRect(x: b.maxX - 1, y: 0, width: self.theme.separatorThickness, height: b.height)
    let bottom = CGRect(
      x: 0,
      y: 0,
      width: b.width,
      height: self.theme.separatorThickness
    )

    guard let context = NSGraphicsContext.current?.cgContext else { return }
    context.saveGState()
    defer { context.restoreGState() }
    self.theme.separatorColor.set()

    if self.position.isEmpty {
      left.fill()
      right.fill()
    }

    if self.position == .first { right.fill() }
    if self.position == .last { left.fill() }

    bottom.fill()
  }

  private func drawSelectionIndicator() {
    guard self.isSelected else { return }

    let b = self.bounds
    let rect = CGRect(
      x: self.theme.separatorThickness,
      y: 0,
      width: b.width,
      height: self.theme.tabSelectionIndicatorThickness
    )

    guard let context = NSGraphicsContext.current?.cgContext else { return }
    context.saveGState()
    defer { context.restoreGState() }
    self.theme.tabSelectedIndicatorColor.set()

    rect.fill()
  }
}
