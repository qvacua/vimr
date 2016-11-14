/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa

class WorkspaceToolButton: NSView, NSDraggingSource, NSPasteboardItemDataProvider {

  static fileprivate let titlePadding = CGSize(width: 8, height: 2)
  static fileprivate let dummyButton = WorkspaceToolButton(title: "Dummy")

  fileprivate let title: NSAttributedString
  fileprivate var trackingArea = NSTrackingArea()
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - API
  static let toolUti = "com.qvacua.vimr.tool"

  var location = WorkspaceBarLocation.top
  var isSelected: Bool {
    return self.tool?.isSelected ?? false
  }

  weak var tool: WorkspaceTool?

  static func dimension() -> CGFloat {
    return self.dummyButton.intrinsicContentSize.height
  }

  static func size(forLocation loc: WorkspaceBarLocation) -> CGSize {
    switch loc {
    case .top, .bottom:
      return self.dummyButton.intrinsicContentSize
    case .right, .left:
      return CGSize(width: self.dummyButton.intrinsicContentSize.height,
                    height: self.dummyButton.intrinsicContentSize.width)
    }
  }

  init(title: String) {
    self.title = NSAttributedString(string: title, attributes: [
      NSFontAttributeName: NSFont.systemFont(ofSize: 11)
    ])

    super.init(frame: CGRect.zero)
    self.configureForAutoLayout()

    self.wantsLayer = true
  }

  func highlight() {
    self.layer?.backgroundColor = NSColor.controlShadowColor.cgColor
  }

  func dehighlight() {
    self.layer?.backgroundColor = NSColor.clear.cgColor
  }
}

// MARK: - NSView
extension WorkspaceToolButton {

  override var intrinsicContentSize: NSSize {
    let titleSize = self.title.size()
    
    let padding = WorkspaceToolButton.titlePadding
    switch self.location {
    case .top, .bottom:
      return CGSize(width: titleSize.width + 2 * padding.width, height: titleSize.height + 2 * padding.height)
    case .right, .left:
      return CGSize(width: titleSize.height + 2 * padding.height, height: titleSize.width + 2 * padding.width)
    }
  }

  override func draw(_ dirtyRect: NSRect) {
    super.draw(dirtyRect)
    
    let padding = WorkspaceToolButton.titlePadding
    switch self.location {
    case .top, .bottom:
      self.title.draw(at: CGPoint(x: padding.width, y: padding.height))
    case .right:
      self.title.draw(at: CGPoint(x: padding.height, y: self.bounds.height - padding.width), angle: -CGFloat(M_PI_2))
    case .left:
      self.title.draw(at: CGPoint(x: self.bounds.width - padding.height, y: padding.width), angle: CGFloat(M_PI_2))
    }
  }

  override func updateTrackingAreas() {
    self.removeTrackingArea(self.trackingArea)

    self.trackingArea = NSTrackingArea(rect: self.bounds,
                                       options: [.mouseEnteredAndExited, .activeInActiveApp],
                                       owner: self,
                                       userInfo: nil)
    self.addTrackingArea(self.trackingArea)

    super.updateTrackingAreas()
  }

  override func mouseDown(with event: NSEvent) {
    guard let nextEvent = self.window!.nextEvent(matching: [NSLeftMouseUpMask, NSLeftMouseDraggedMask]) else {
      return
    }

    switch nextEvent.type {

    case NSLeftMouseUp:
      self.tool?.toggle()
      return

    case NSLeftMouseDragged:
      let pasteboardItem = NSPasteboardItem()
      pasteboardItem.setDataProvider(self, forTypes: [WorkspaceToolButton.toolUti])

      let draggingItem = NSDraggingItem(pasteboardWriter: pasteboardItem)
      draggingItem.setDraggingFrame(self.bounds, contents:self.snapshot())

      self.beginDraggingSession(with: [draggingItem], event: nextEvent, source: self)
      return

    default:
      return
    }
  }

  override func mouseEntered(with _: NSEvent) {
    if self.isSelected {
      return
    }

    self.highlight()
  }

  override func mouseExited(with _: NSEvent) {
    if self.isSelected {
      return
    }

    self.dehighlight()
  }

  @objc(draggingSession:sourceOperationMaskForDraggingContext:)
  func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor ctx: NSDraggingContext) -> NSDragOperation {
    return .move
  }

  // https://www.raywenderlich.com/136272/drag-and-drop-tutorial-for-macos
  fileprivate func snapshot() -> NSImage {
    let pdfData = self.dataWithPDF(inside: self.bounds)
    let image = NSImage(data: pdfData)
    return image ?? NSImage()
  }
}

// MARK: - NSPasteboardItemDataProvider
extension WorkspaceToolButton {

  func pasteboard(_ pasteboardOptional: NSPasteboard?, item: NSPasteboardItem, provideDataForType type: String) {
    guard let pasteboard = pasteboardOptional else {
      return
    }

    guard type == WorkspaceToolButton.toolUti else {
      return
    }

    pasteboard.writeObjects([self.tool!.uuid as NSString])
  }
}
