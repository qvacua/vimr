/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import PureLayout
import CocoaFontAwesome

class CustomToolBar: NSView {

  func repaint(with: Workspace.Theme) {
    // please implement
  }
}

/**
 This class is the base class for inner toolbars for workspace tools. It's got two default buttons:
 - Close button
 - Cog button: not shown when there's no menu
 */
class InnerToolBar: NSView, NSUserInterfaceValidations {

  // MARK: - API
  static let toolbarHeight = InnerToolBar.iconDimension
  static let iconDimension = CGFloat(18)
  static let itemPadding = CGFloat(4)

  static func configureToStandardIconButton(
    button: NSButton,
    iconName: FontAwesome,
    style: FontAwesomeStyle,
    color: NSColor = Workspace.Theme.default.toolbarForeground
  ) {
    let icon = NSImage.fontAwesomeIcon(
      name: iconName,
      style: .solid,
      textColor: color,
      dimension: InnerToolBar.iconDimension
    )

    button.imagePosition = .imageOnly
    button.image = icon
    button.isBordered = false

    // The following disables the square appearing when pushed.
    let cell = button.cell as? NSButtonCell
    cell?.highlightsBy = .contentsCellMask
  }

  var customMenuItems: [NSMenuItem]? {
    didSet {
      self.removeCustomUiElements()
      self.addViews()
    }
  }
  var customToolbar: CustomToolBar? {
    didSet {
      self.removeCustomUiElements()
      self.addViews()
    }
  }

  var theme: Workspace.Theme {
    return self.tool?.theme ?? Workspace.Theme.default
  }

  weak var tool: WorkspaceTool? {
    didSet {
      self.titleField.stringValue = self.tool?.title ?? ""

      let toolTitle = self.tool?.title ?? "Tool"
      self.closeButton.toolTip = "Close \(toolTitle)"
      self.cogButton.toolTip = "\(toolTitle) Settings"
    }
  }

  override var intrinsicContentSize: CGSize {
    if #available(macOS 10.11, *) {
      return CGSize(width: NSView.noIntrinsicMetric, height: InnerToolBar.height)
    } else {
      return CGSize(width: -1, height: InnerToolBar.height)
    }
  }

  init(customToolbar: CustomToolBar? = nil, customMenuItems: [NSMenuItem] = []) {
    self.customMenuItems = customMenuItems
    self.customToolbar = customToolbar

    super.init(frame: .zero)
    self.configureForAutoLayout()

    // Because other views also want layer, this view also must want layer. Otherwise the z-index ordering is not set
    // correctly: views w/ wantsLayer = false are behind views w/ wantsLayer = true even when added later.
    self.wantsLayer = true
    self.layer?.backgroundColor = self.theme.toolbarBackground.cgColor

    self.addViews()
  }

  func repaint() {
    self.layer!.backgroundColor = self.theme.toolbarBackground.cgColor

    self.titleField.textColor = self.theme.toolbarForeground
    self.cogButton.image = NSImage.fontAwesomeIcon(
      name: .cog,
      style: .solid,
      textColor: self.theme.toolbarForeground,
      dimension: InnerToolBar.iconDimension
    )
    self.closeButton.image = NSImage.fontAwesomeIcon(
      name: .timesCircle,
      style: .regular,
      textColor: self.theme.toolbarForeground,
      dimension: InnerToolBar.iconDimension
    )

    self.customToolbar?.repaint(with: self.theme)

    self.needsDisplay = true
  }

  override func draw(_ dirtyRect: NSRect) {
    self.theme.separator.set()
    let bottomSeparatorRect = self.bottomSeparatorRect()
    if dirtyRect.intersects(bottomSeparatorRect) {
      bottomSeparatorRect.fill()
    }

    self.theme.toolbarForeground.set()
    let innerSeparatorRect = self.innerSeparatorRect()
    if dirtyRect.intersects(innerSeparatorRect) {
      innerSeparatorRect.fill()
    }
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private static let separatorThickness = CGFloat(1)
  private static let height = InnerToolBar.iconDimension + 2 + 2 + InnerToolBar.separatorThickness

  private let titleField = NSTextField(forAutoLayout: ())
  private let closeButton = NSButton(forAutoLayout: ())
  private let cogButton = NSButton(forAutoLayout: ())
  private let cogMenu = NSMenu()

  private let locToSelector: [WorkspaceBarLocation: Selector] = [
    .top: #selector(InnerToolBar.moveToTopAction(_:)),
    .right: #selector(InnerToolBar.moveToRightAction(_:)),
    .bottom: #selector(InnerToolBar.moveToBottomAction(_:)),
    .left: #selector(InnerToolBar.moveToLeftAction(_:)),
  ]

  private func removeCustomUiElements() {
    self.customToolbar?.removeFromSuperview()
    [self.titleField, self.closeButton, self.cogButton].forEach { $0.removeFromSuperview() }
    self.cogButton.menu = nil
  }

  private func addViews() {
    let title = self.titleField
    let close = self.closeButton
    let cog = self.cogButton

    title.isBezeled = false
    title.drawsBackground = false
    title.isEditable = false
    title.isSelectable = false
    title.controlSize = .small

    InnerToolBar.configureToStandardIconButton(
      button: close,
      iconName: .timesCircle,
      style: .regular,
      color: self.theme.toolbarForeground
    )
    close.target = self
    close.action = #selector(InnerToolBar.closeAction)

    InnerToolBar.configureToStandardIconButton(
      button: cog,
      iconName: .cog,
      style: .solid,
      color: self.theme.toolbarForeground
    )
    cog.action = #selector(InnerToolBar.cogAction)
    cog.target = self

    let moveToMenu = NSMenu()
    let topMenuItem = NSMenuItem(title: "Top",
                                 action: #selector(InnerToolBar.moveToTopAction),
                                 keyEquivalent: "")
    topMenuItem.target = self
    let rightMenuItem = NSMenuItem(title: "Right",
                                   action: #selector(InnerToolBar.moveToRightAction),
                                   keyEquivalent: "")
    rightMenuItem.target = self
    let bottomMenuItem = NSMenuItem(title: "Bottom",
                                    action: #selector(InnerToolBar.moveToBottomAction),
                                    keyEquivalent: "")
    bottomMenuItem.target = self
    let leftMenuItem = NSMenuItem(title: "Left",
                                  action: #selector(InnerToolBar.moveToLeftAction),
                                  keyEquivalent: "")
    leftMenuItem.target = self

    moveToMenu.addItem(leftMenuItem)
    moveToMenu.addItem(rightMenuItem)
    moveToMenu.addItem(bottomMenuItem)
    moveToMenu.addItem(topMenuItem)

    let moveToMenuItem = NSMenuItem(
      title: "Move To",
      action: nil,
      keyEquivalent: ""
    )
    moveToMenuItem.submenu = moveToMenu

    if self.customMenuItems?.isEmpty == false {
      self.customMenuItems?.forEach(cogMenu.addItem)
      cogMenu.addItem(NSMenuItem.separator())
    }

    cogMenu.addItem(moveToMenuItem)

    if let customToolbar = self.customToolbar {
      customToolbar.configureForAutoLayout()
      self.addSubview(customToolbar)
    }
    self.addSubview(title)
    self.addSubview(close)
    self.addSubview(cog)

    title.autoAlignAxis(toSuperviewAxis: .horizontal)
    title.autoPinEdge(toSuperviewEdge: .left, withInset: 4)

    close.autoPinEdge(toSuperviewEdge: .top, withInset: 2)
    close.autoPinEdge(toSuperviewEdge: .right, withInset: 2)

    cog.autoPinEdge(
      .right,
      to: .left,
      of: close,
      withOffset: -InnerToolBar.itemPadding
    )
    cog.autoPinEdge(.top, to: .top, of: close)

    if let customToolbar = self.customToolbar {
      customToolbar.autoPinEdge(toSuperviewEdge: .top, withInset: 2)
      customToolbar.autoPinEdge(
        .right,
        to: .left,
        of: cog,
        withOffset: -InnerToolBar.itemPadding - InnerToolBar.separatorThickness
      )
      customToolbar.autoPinEdge(
        toSuperviewEdge: .bottom,
        withInset: 2 + InnerToolBar.separatorThickness
      )
      customToolbar.autoPinEdge(
        .left,
        to: .right,
        of: title,
        withOffset: -InnerToolBar.itemPadding
      )
    }
  }

  private func bottomSeparatorRect() -> CGRect {
    let bounds = self.bounds
    return CGRect(x: bounds.minX, y: bounds.minY, width: bounds.width, height: InnerToolBar.separatorThickness)
  }

  private func innerSeparatorRect() -> CGRect {
    let cogBounds = self.cogButton.frame
    let bounds = self.bounds
    return CGRect(x: cogBounds.minX - InnerToolBar.itemPadding,
                  y: bounds.minY + 4,
                  width: 1,
                  height: bounds.height - 4 - 4)
  }
}

// MARK: - Actions
extension InnerToolBar {

  @objc func closeAction(_ sender: Any?) {
    self.tool?.toggle()
  }

  @objc func cogAction(_ sender: NSButton) {
    guard let event = NSApp.currentEvent else { return }

    NSMenu.popUpContextMenu(self.cogMenu, with: event, for: sender)
  }

  @objc func moveToTopAction(_ sender: Any?) {
    self.move(to: .top)
  }

  @objc func moveToRightAction(_ sender: Any?) {
    self.move(to: .right)
  }

  @objc func moveToBottomAction(_ sender: Any?) {
    self.move(to: .bottom)
  }

  @objc func moveToLeftAction(_ sender: Any?) {
    self.move(to: .left)
  }

  private func move(to location: WorkspaceBarLocation) {
    guard let tool = self.tool else {
      return
    }

    tool.workspace?.move(tool: tool, to: location)
  }
}

// MARK: - NSUserInterfaceValidations
extension InnerToolBar {

  func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
    guard let loc = self.tool?.location else {
      return true
    }

    if item.action == self.locToSelector[loc] {
      return false
    }

    return true
  }
}
