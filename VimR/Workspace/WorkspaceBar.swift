/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import PureLayout

class WorkspaceBar: NSView, WorkspaceToolDelegate {

  static private let separatorColor = NSColor.controlShadowColor()
  static private let separatorThickness = CGFloat(1)

  let location: WorkspaceBarLocation
  var isButtonVisible = true {
    didSet {
      self.relayout()
    }
  }
  var dimensionConstraint = NSLayoutConstraint()

  private var tools = [WorkspaceTool]()
  private weak var selectedTool: WorkspaceTool?

  private var isMouseDownOngoing = false
  private var dragIncrement = CGFloat(1)

  private var layoutConstraints = [NSLayoutConstraint]()

  init(location: WorkspaceBarLocation) {
    self.location = location

    super.init(frame: CGRect.zero)
    super.translatesAutoresizingMaskIntoConstraints = false

    self.wantsLayer = true
    self.layer!.backgroundColor = NSColor.windowBackgroundColor().CGColor
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func drawRect(dirtyRect: NSRect) {
    super.drawRect(dirtyRect)

    if self.isButtonVisible {
      self.drawInnerSeparator(dirtyRect)
    }

    if self.isOpen() {
      self.drawOuterSeparator(dirtyRect)
    }
  }

  private func drawInnerSeparator(dirtyRect: NSRect) {
    WorkspaceBar.separatorColor.set()

    let innerLineRect = self.innerSeparatorRect()
    if dirtyRect.intersects(innerLineRect) {
      NSRectFill(innerLineRect)
    }
  }

  private func drawOuterSeparator(dirtyRect: NSRect) {
    WorkspaceBar.separatorColor.set()

    let outerLineRect = self.outerSeparatorRect()
    if dirtyRect.intersects(outerLineRect) {
      NSRectFill(outerLineRect)
    }
  }

  private func buttonSize() -> CGSize {
    if self.isEmpty() {
      return CGSize.zero
    }

    return self.tools.first!.button.intrinsicContentSize
  }

  private func innerSeparatorRect() -> CGRect {
    let bounds = self.bounds
    let thickness = WorkspaceBar.separatorThickness
    let bar = self.buttonSize()

    switch self.location {
    case .top:
      return CGRect(x: 0, y: bounds.height - bar.height - thickness, width: bounds.width, height: thickness)
    case .right:
      return CGRect(x: bounds.width - bar.width - thickness, y: 0, width: thickness, height: bounds.height)
    case .bottom:
      return CGRect(x: 0, y: bar.height, width: bounds.width, height: thickness)
    case .left:
      return CGRect(x: bar.width, y: 0, width: thickness, height: bounds.height)
    }
  }

  override func mouseDown(event: NSEvent) {
    guard self.isOpen() else {
      return
    }

    if self.isMouseDownOngoing {
      return
    }

    let initialMouseLoc = self.convertPoint(event.locationInWindow, fromView: nil)
    let mouseInResizeRect = NSMouseInRect(initialMouseLoc, self.resizeRect(), self.flipped)

    guard mouseInResizeRect && event.type == .LeftMouseDown else {
      super.mouseDown(event)
      return
    }

    self.isMouseDownOngoing = true

    var dragged = false
    var curEvent = event
    let nextEventMask: NSEventMask = [
      NSEventMask.LeftMouseDraggedMask,
      NSEventMask.LeftMouseDownMask,
      NSEventMask.LeftMouseUpMask
    ]
    while curEvent.type != .LeftMouseUp {
      let nextEvent = NSApp.nextEventMatchingMask(Int(nextEventMask.rawValue),
                                                  untilDate: NSDate.distantFuture(),
                                                  inMode: NSEventTrackingRunLoopMode,
                                                  dequeue: true)
      guard nextEvent != nil else {
        break
      }

      curEvent = nextEvent!

      guard curEvent.type == .LeftMouseDragged else {
        break
      }

      let curMouseLoc = self.convertPoint(curEvent.locationInWindow, fromView: nil)
      let distance = sq(initialMouseLoc.x - curMouseLoc.x) + sq(initialMouseLoc.y - curMouseLoc.y)

      guard dragged || distance >= 1 else {
        continue
      }

      let locInSuperview = self.superview!.convertPoint(curEvent.locationInWindow, fromView: nil)
      let newDimension = self.newDimension(forLocationInSuperview: locInSuperview)

      self.set(dimension: newDimension)

      self.window?.invalidateCursorRectsForView(self)

      dragged = true
    }

    self.isMouseDownOngoing = false
  }

  override func resetCursorRects() {
    guard self.isOpen() else {
      return
    }

    switch self.location {
    case .top, .bottom:
      self.addCursorRect(self.resizeRect(), cursor: NSCursor.resizeUpDownCursor())
    case .right, .left:
      self.addCursorRect(self.resizeRect(), cursor: NSCursor.resizeLeftRightCursor())
    }
  }

  private func newDimension(forLocationInSuperview locInSuperview: CGPoint) -> CGFloat {
    let dimension = self.dimension(forLocationInSuperview: locInSuperview)
    return self.dragIncrement * floor(dimension / self.dragIncrement)
  }

  private func dimension(forLocationInSuperview locInSuperview: CGPoint) -> CGFloat {
    let superviewBounds = self.superview!.bounds

    switch self.location {
    case .top:
      return superviewBounds.height - locInSuperview.y
    case .right:
      return superviewBounds.width - locInSuperview.x
    case .bottom:
      return locInSuperview.y
    case .left:
      return locInSuperview.x
    }
  }

  private func sq(number: CGFloat) -> CGFloat {
    return number * number
  }

  private func outerSeparatorRect() -> CGRect {
    let thickness = WorkspaceBar.separatorThickness

    switch self.location {
    case .top:
      return CGRect(x: 0, y: 0, width: self.bounds.width, height: thickness)
    case .right:
      return CGRect(x: 0, y: 0, width: thickness, height: self.bounds.height)
    case .bottom:
      return CGRect(x: 0, y: self.bounds.height - thickness, width: self.bounds.width, height: thickness)
    case .left:
      return CGRect(x: self.bounds.width - thickness, y: 0, width: thickness, height: self.bounds.height)
    }
  }

  private func resizeRect() -> CGRect {
    let separatorRect = self.outerSeparatorRect()
    let clickDimension = CGFloat(4)

    switch self.location {
    case .top:
      return separatorRect.offsetBy(dx: 0, dy: clickDimension).union(separatorRect)
    case .right:
      return separatorRect.offsetBy(dx: clickDimension, dy: 0).union(separatorRect)
    case .bottom:
      return separatorRect.offsetBy(dx: 0, dy: -clickDimension).union(separatorRect)
    case .left:
      return separatorRect.offsetBy(dx: -clickDimension, dy: 0).union(separatorRect)
    }
  }

  private func set(dimension dimension: CGFloat) {
    self.dimensionConstraint.constant = dimension

    let toolDimension = self.toolDimension(fromBarDimension: dimension)
    if self.isOpen() {
      self.selectedTool?.dimension = toolDimension
    }
  }

  private func isEmpty() -> Bool {
    return self.tools.isEmpty
  }

  private func hasTools() -> Bool {
    return !self.isEmpty()
  }

  private func isOpen() -> Bool {
    return self.selectedTool != nil
  }
}

// MARK: - Layout
extension WorkspaceBar {

  func relayout() {
    self.removeConstraints(self.layoutConstraints)
    self.removeAllSubviews()

    if self.isEmpty() {
      self.set(dimension: 0)
      return
    }

    if self.isButtonVisible {
      self.layoutButtons()

      if self.isOpen() {
        let curTool = self.selectedTool!

        self.layout(tool: curTool)

        let newDimension = self.barDimension(withToolDimension: curTool.dimension)
        self.set(dimension: newDimension)
      } else {
        self.set(dimension: self.barDimensionWithButtonsWithoutTool())
      }

    } else {
      if self.isOpen() {
        let curTool = self.selectedTool!

        self.layoutWithoutButtons(tool: curTool)

        let newDimension = self.barDimensionWithoutButtons(withToolDimension: curTool.dimension)
        self.set(dimension: newDimension)
      } else {
        self.set(dimension: 0)
      }
    }

    self.needsDisplay = true
  }

  private func layoutWithoutButtons(tool tool: WorkspaceTool) {
    let view = tool.view
    let thickness = WorkspaceBar.separatorThickness

    self.addSubview(view)
    switch self.location {
    case .top:
      self.layoutConstraints.appendContentsOf([
        view.autoPinEdgeToSuperviewEdge(.Top),
        view.autoPinEdgeToSuperviewEdge(.Right),
        view.autoPinEdgeToSuperviewEdge(.Bottom, withInset: thickness),
        view.autoPinEdgeToSuperviewEdge(.Left),

        view.autoSetDimension(.Height, toSize: tool.minimumDimension, relation: .GreaterThanOrEqual)
        ])
    case .right:
      self.layoutConstraints.appendContentsOf([
        view.autoPinEdgeToSuperviewEdge(.Top),
        view.autoPinEdgeToSuperviewEdge(.Right),
        view.autoPinEdgeToSuperviewEdge(.Bottom),
        view.autoPinEdgeToSuperviewEdge(.Left, withInset: thickness),

        view.autoSetDimension(.Width, toSize: tool.minimumDimension, relation: .GreaterThanOrEqual)
        ])
    case .bottom:
      self.layoutConstraints.appendContentsOf([
        view.autoPinEdgeToSuperviewEdge(.Top, withInset: thickness),
        view.autoPinEdgeToSuperviewEdge(.Right),
        view.autoPinEdgeToSuperviewEdge(.Bottom),
        view.autoPinEdgeToSuperviewEdge(.Left),

        view.autoSetDimension(.Height, toSize: tool.minimumDimension, relation: .GreaterThanOrEqual)
        ])
    case .left:
      self.layoutConstraints.appendContentsOf([
        view.autoPinEdgeToSuperviewEdge(.Top),
        view.autoPinEdgeToSuperviewEdge(.Right, withInset: thickness),
        view.autoPinEdgeToSuperviewEdge(.Bottom),
        view.autoPinEdgeToSuperviewEdge(.Left),

        view.autoSetDimension(.Width, toSize: tool.minimumDimension, relation: .GreaterThanOrEqual)
        ])
    }
  }

  private func layout(tool tool: WorkspaceTool) {
    let view = tool.view
    let button = tool.button
    let thickness = WorkspaceBar.separatorThickness

    self.addSubview(view)

    switch self.location {
    case .top:
      self.layoutConstraints.appendContentsOf([
        view.autoPinEdge(.Top, toEdge: .Bottom, ofView: button, withOffset: thickness),
        view.autoPinEdgeToSuperviewEdge(.Right),
        view.autoPinEdgeToSuperviewEdge(.Bottom, withInset: thickness),
        view.autoPinEdgeToSuperviewEdge(.Left),

        view.autoSetDimension(.Height, toSize: tool.minimumDimension, relation: .GreaterThanOrEqual)
        ])
    case .right:
      self.layoutConstraints.appendContentsOf([
        view.autoPinEdgeToSuperviewEdge(.Top),
        view.autoPinEdge(.Right, toEdge: .Left, ofView: button, withOffset: -thickness),  // Offset is count l -> r,
        view.autoPinEdgeToSuperviewEdge(.Bottom),
        view.autoPinEdgeToSuperviewEdge(.Left, withInset: thickness),

        view.autoSetDimension(.Width, toSize: tool.minimumDimension, relation: .GreaterThanOrEqual)
        ])
    case .bottom:
      self.layoutConstraints.appendContentsOf([
        view.autoPinEdgeToSuperviewEdge(.Top, withInset: thickness),
        view.autoPinEdgeToSuperviewEdge(.Right),
        view.autoPinEdge(.Bottom, toEdge: .Top, ofView: button, withOffset: -thickness), // Offset is count t -> b,
        view.autoPinEdgeToSuperviewEdge(.Left),

        view.autoSetDimension(.Height, toSize: tool.minimumDimension, relation: .GreaterThanOrEqual)
        ])
    case .left:
      self.layoutConstraints.appendContentsOf([
        view.autoPinEdgeToSuperviewEdge(.Top),
        view.autoPinEdgeToSuperviewEdge(.Right, withInset: thickness),
        view.autoPinEdgeToSuperviewEdge(.Bottom),
        view.autoPinEdge(.Left, toEdge: .Right, ofView: button, withOffset: thickness),

        view.autoSetDimension(.Width, toSize: tool.minimumDimension, relation: .GreaterThanOrEqual)
        ])
    }
  }

  private func layoutButtons() {
    guard let firstTool = self.tools.first else {
      return
    }

    self.tools
      .map { $0.button }
      .forEach(self.addSubview)

    let firstButton = firstTool.button
    switch self.location {
    case .top:
      self.layoutConstraints.appendContentsOf([
        firstButton.autoPinEdgeToSuperviewEdge(.Top),
        firstButton.autoPinEdgeToSuperviewEdge(.Left),
        ])
    case .right:
      self.layoutConstraints.appendContentsOf([
        firstButton.autoPinEdgeToSuperviewEdge(.Top),
        firstButton.autoPinEdgeToSuperviewEdge(.Right),
        ])
    case .bottom:
      self.layoutConstraints.appendContentsOf([
        firstButton.autoPinEdgeToSuperviewEdge(.Left),
        firstButton.autoPinEdgeToSuperviewEdge(.Bottom),
        ])
    case .left:
      self.layoutConstraints.appendContentsOf([
        firstButton.autoPinEdgeToSuperviewEdge(.Top),
        firstButton.autoPinEdgeToSuperviewEdge(.Left),
        ])
    }

    var lastButton = firstButton
    for button in self.tools[1..<self.tools.count].map({ $0.button }) {
      switch self.location {
      case .top:
        self.layoutConstraints.appendContentsOf([
          button.autoPinEdgeToSuperviewEdge(.Top),
          button.autoPinEdge(.Left, toEdge: .Right, ofView: lastButton),
          ])
      case .right:
        self.layoutConstraints.appendContentsOf([
          button.autoPinEdge(.Top, toEdge: .Bottom, ofView: lastButton),
          button.autoPinEdgeToSuperviewEdge(.Right),
          ])
      case .bottom:
        self.layoutConstraints.appendContentsOf([
          button.autoPinEdge(.Left, toEdge: .Right, ofView: lastButton),
          button.autoPinEdgeToSuperviewEdge(.Bottom),
          ])
      case .left:
        self.layoutConstraints.appendContentsOf([
          button.autoPinEdge(.Top, toEdge: .Bottom, ofView: lastButton),
          button.autoPinEdgeToSuperviewEdge(.Left),
          ])
      }

      lastButton = button
    }
  }

  private func barDimensionWithButtonsWithoutTool() -> CGFloat {
    switch self.location {
    case .top, .bottom:
      return self.buttonSize().height + WorkspaceBar.separatorThickness
    case .right, .left:
      return self.buttonSize().width + WorkspaceBar.separatorThickness
    }
  }

  private func barDimensionWithoutButtons(withToolDimension toolDimension: CGFloat) -> CGFloat {
    return toolDimension + WorkspaceBar.separatorThickness
  }

  private func barDimension(withToolDimension toolDimension: CGFloat) -> CGFloat {
    return self.barDimensionWithButtonsWithoutTool() + toolDimension + WorkspaceBar.separatorThickness
  }

  private func toolDimension(fromBarDimension barDimension: CGFloat) -> CGFloat {
    if self.isButtonVisible {
      return barDimension - WorkspaceBar.separatorThickness - barDimensionWithButtonsWithoutTool()
    }

    return barDimension - WorkspaceBar.separatorThickness
  }
}

// MARK: - API
extension WorkspaceBar {

  func append(tool tool: WorkspaceTool) {
    tool.delegate = self
    tool.location = self.location
    tools.append(tool)

    if self.isOpen() {
      self.selectedTool?.isSelected = false
      self.selectedTool = tool
    }

    self.relayout()
  }
}

// MARK: - WorkspaceToolDelegate
extension WorkspaceBar {

  func toggle(tool tool: WorkspaceTool) {
    if self.isOpen() {
      let curTool = self.selectedTool!
      if curTool === tool {
        // In this case, curTool.isSelected is already set to false in WorkspaceTool.toggle()
        self.selectedTool = nil
      } else {
        curTool.isSelected = false
        self.selectedTool = tool
      }
      
    } else {
      self.selectedTool = tool
    }
    
    self.relayout()
  }
}
