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

    let isTrackpad = event.hasPreciseScrollingDeltas

    let cellPosition = self.cellPositionFor(event: event)
    let (vimInputX, vimInputY) = self.vimScrollInputFor(deltaX: deltaX, deltaY: deltaY,
                                                        modifierFlags: event.modifierFlags,
                                                        cellPosition: cellPosition)

    // We patched neovim such that it scrolls only 1 line for each scroll input. The default is 3 and for mouse
    // scrolling we restore the original behavior.
    if isTrackpad == false {
      (0..<3).forEach { _ in
        self.agent.vimInput(vimInputX)
        self.agent.vimInput(vimInputY)
      }

      return
    }

    let (absDeltaX, absDeltaY) = (abs(deltaX), abs(deltaY))

    // The absolute delta values can get very very big when you use two finger scrolling on the trackpad:
    // Cap them using heuristic values...
    let numX = deltaX != 0 ? max(1, min(Int(absDeltaX / self.scrollLimiterX), self.maxScrollDeltaX)) : 0
    let numY = deltaY != 0 ? max(1, min(Int(absDeltaY / self.scrollLimiterY), self.maxScrollDeltaY)) : 0

    for i in 0..<max(numX, numY) {
      if i < numX {
        self.throttleScrollX(absDelta: absDeltaX, vimInput: vimInputX)
      }

      if i < numY {
        self.throttleScrollY(absDelta: absDeltaY, vimInput: vimInputY)
      }
    }
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
      self.updateFontMetaData(self.fontManager.convert(self.font, toSize: resultingFontSize))
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

//    NSLog("\(#function): \(result)")
    self.agent.vimInput(result)
  }

  fileprivate func shouldFireVimInputFor(event: NSEvent, newCellPosition: Position) -> Bool {
    let type = event.type
    guard type == .leftMouseDragged || type == .rightMouseDragged || type == .otherMouseDragged else {
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

  fileprivate func throttleScrollX(absDelta absDeltaX: CGFloat, vimInput: String) {
    if absDeltaX == 0 {
      self.scrollGuardCounterX = self.scrollGuardYield - 1
    } else if absDeltaX <= 2 {
      // Poor man's throttle for scroll value = 1 or 2
      if self.scrollGuardCounterX % self.scrollGuardYield == 0 {
        self.agent.vimInput(vimInput)
        self.scrollGuardCounterX = 1
      } else {
        self.scrollGuardCounterX += 1
      }
    } else {
      self.agent.vimInput(vimInput)
    }
  }

  fileprivate func throttleScrollY(absDelta absDeltaY: CGFloat, vimInput: String) {
    if absDeltaY == 0 {
      self.scrollGuardCounterY = self.scrollGuardYield - 1
    } else if absDeltaY <= 2 {
      // Poor man's throttle for scroll value = 1 or 2
      if self.scrollGuardCounterY % self.scrollGuardYield == 0 {
        self.agent.vimInput(vimInput)
        self.scrollGuardCounterY = 1
      } else {
        self.scrollGuardCounterY += 1
      }
    } else {
      self.agent.vimInput(vimInput)
    }
  }
}
