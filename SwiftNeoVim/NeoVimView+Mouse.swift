/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa

extension NeoVimView {

  override public func mouseDown(with event: NSEvent) {
    self.mouse(event: event, vimName: "LeftMouse")
  }

  override public func mouseUp(with event: NSEvent) {
    self.mouse(event: event, vimName: "LeftRelease")
  }

  override public func mouseDragged(with event: NSEvent) {
    self.mouse(event: event, vimName: "LeftDrag")
  }

  override public func scrollWheel(with event: NSEvent) {
    let (deltaX, deltaY) = (event.scrollingDeltaX, event.scrollingDeltaY)
    if deltaX == 0 && deltaY == 0 {
      return
    }

    let cellPosition = self.cellPositionFor(event: event)

    let isTrackpad = event.hasPreciseScrollingDeltas
    if isTrackpad == false {
      let (vimInputX, vimInputY) = self.vimScrollInputFor(deltaX: deltaX, deltaY: deltaY,
                                                          modifierFlags: event.modifierFlags,
                                                          cellPosition: cellPosition)
      self.agent.vimInput(vimInputX)
      self.agent.vimInput(vimInputY)
      return
    }

    let (absDeltaX, absDeltaY) = (min(Int(ceil(abs(deltaX) / 5.0)), maxScrollDeltaX),
                                  min(Int(ceil(abs(deltaY) / 5.0)), maxScrollDeltaY))
    let (horizSign, vertSign) = (deltaX > 0 ? 1 : -1, deltaY > 0 ? 1 : -1)
    self.agent.scrollHorizontal(horizSign * absDeltaX, vertical: vertSign * absDeltaY, at: cellPosition)
  }

  override public func magnify(with event: NSEvent) {
    let factor = 1 + event.magnification
    let pinchTargetScale = self.pinchTargetScale * factor
    let resultingFontSize = round(pinchTargetScale * self.font.pointSize)
    if resultingFontSize >= NeoVimView.minFontSize && resultingFontSize <= NeoVimView.maxFontSize {
      self.pinchTargetScale = pinchTargetScale
    }

    switch event.phase {
    case NSEventPhase.began:
      let pinchImageRep = self.bitmapImageRepForCachingDisplay(in: self.bounds)!
      self.cacheDisplay(in: self.bounds, to: pinchImageRep)
      self.pinchBitmap = pinchImageRep

      self.isCurrentlyPinching = true
      self.needsDisplay = true

    case NSEventPhase.ended, NSEventPhase.cancelled:
      self.isCurrentlyPinching = false
      self.updateFontMetaData(NSFontManager.shared().convert(self.font, toSize: resultingFontSize))
      self.pinchTargetScale = 1

    default:
      self.needsDisplay = true
    }
  }

  fileprivate func cellPositionFor(event: NSEvent) -> Position {
    let location = self.convert(event.locationInWindow, from: nil)
    let row = Int((location.x - self.xOffset) / self.cellSize.width)
    let column = Int((self.bounds.size.height - location.y - self.yOffset) / self.cellSize.height)

    let cellPosition = Position(row: min(max(0, row), self.grid.size.width - 1),
                                column: min(max(0, column), self.grid.size.height - 1))
    return cellPosition
  }

  fileprivate func mouse(event: NSEvent, vimName: String) {
    let cellPosition = self.cellPositionFor(event: event)
    guard self.shouldFireVimInputFor(event: event, newCellPosition: cellPosition) else {
      return
    }

    let vimMouseLocation = self.wrapNamedKeys("\(cellPosition.row),\(cellPosition.column)")
    let vimClickCount = self.vimClickCountFrom(event: event)

    let result: String
    if let vimModifiers = self.vimModifierFlags(event.modifierFlags) {
      result = self.wrapNamedKeys("\(vimModifiers)\(vimClickCount)\(vimName)") + vimMouseLocation
    } else {
      result = self.wrapNamedKeys("\(vimClickCount)\(vimName)") + vimMouseLocation
    }

//    self.logger.debug("\(#function): \(result)")
    self.agent.vimInput(result)
  }

  fileprivate func shouldFireVimInputFor(event: NSEvent, newCellPosition: Position) -> Bool {
    let type = event.type
    guard type == .leftMouseDragged
          || type == .rightMouseDragged
          || type == .otherMouseDragged else {

      self.lastClickedCellPosition = newCellPosition
      return true
    }

    if self.lastClickedCellPosition == newCellPosition {
      return false
    }

    self.lastClickedCellPosition = newCellPosition
    return true
  }

  fileprivate func vimClickCountFrom(event: NSEvent) -> String {
    let clickCount = event.clickCount

    guard 2 <= clickCount && clickCount <= 4 else {
      return ""
    }

    switch event.type {
    case .leftMouseDown, .leftMouseUp, .rightMouseDown, .rightMouseUp:
      return "\(clickCount)-"
    default:
      return ""
    }
  }

  fileprivate func vimScrollEventNamesFor(deltaX: CGFloat, deltaY: CGFloat) -> (String, String) {
    let typeY: String
    if deltaY > 0 {
      typeY = "ScrollWheelUp"
    } else {
      typeY = "ScrollWheelDown"
    }

    let typeX: String
    if deltaX < 0 {
      typeX = "ScrollWheelRight"
    } else {
      typeX = "ScrollWheelLeft"
    }

    return (typeX, typeY)
  }

  fileprivate func vimScrollInputFor(deltaX: CGFloat, deltaY: CGFloat,
                                     modifierFlags: NSEventModifierFlags,
                                     cellPosition: Position) -> (String, String) {

    let vimMouseLocation = self.wrapNamedKeys("\(cellPosition.row),\(cellPosition.column)")

    let (typeX, typeY) = self.vimScrollEventNamesFor(deltaX: deltaX, deltaY: deltaY)
    let resultX: String
    let resultY: String
    if let vimModifiers = self.vimModifierFlags(modifierFlags) {
      resultX = self.wrapNamedKeys("\(vimModifiers)\(typeX)") + vimMouseLocation
      resultY = self.wrapNamedKeys("\(vimModifiers)\(typeY)") + vimMouseLocation
    } else {
      resultX = self.wrapNamedKeys("\(typeX)") + vimMouseLocation
      resultY = self.wrapNamedKeys("\(typeY)") + vimMouseLocation
    }

    return (resultX, resultY)
  }
}

fileprivate let maxScrollDeltaX = 15
fileprivate let maxScrollDeltaY = 15
