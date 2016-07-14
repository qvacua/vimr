/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa

extension NeoVimView {

  override public func mouseDown(event: NSEvent) {
    self.mouse(event: event, vimName:"LeftMouse")
  }

  override public func mouseUp(event: NSEvent) {
    self.mouse(event: event, vimName:"LeftRelease")
  }

  override public func mouseDragged(event: NSEvent) {
    self.mouse(event: event, vimName:"LeftDrag")
  }

  override public func scrollWheel(event: NSEvent) {
    let (deltaX, deltaY) = (event.scrollingDeltaX, event.scrollingDeltaY)
    if deltaX == 0 && deltaY == 0 {
      return
    }
    
    let cellPosition = self.cellPositionFor(event: event)
    let (vimInputX, vimInputY) = self.vimScrollInputFor(deltaX: deltaX, deltaY: deltaY,
                                                    modifierFlags: event.modifierFlags,
                                                    cellPosition: cellPosition)
    
    let (absDeltaX, absDeltaY) = (abs(deltaX), abs(deltaY))
    
    // The absolute delta values can get very very big when you use two finger scrolling on the trackpad:
    // Cap them using heuristic values...
    let numX = deltaX != 0 ? max(1, min(Int(absDeltaX / 20), 25)) : 0
    let numY = deltaY != 0 ? max(1, min(Int(absDeltaY / 20), 25)) : 0

    for i in 0..<max(numX, numY) {
      if i < numX {
        self.throttleScrollX(absDelta: absDeltaX, vimInput: vimInputX)
      }
      
      if i < numY {
        self.throttleScrollY(absDelta: absDeltaY, vimInput: vimInputY)
      }
    }
  }

  private func cellPositionFor(event event: NSEvent) -> Position {
    let location = self.convertPoint(event.locationInWindow, fromView: nil)
    let cellPosition = Position(
      row: min(Int(floor(location.x / self.cellSize.width)), self.grid.size.width - 1),
      column: min(Int(floor((self.bounds.height - location.y) / self.cellSize.height)), self.grid.size.height - 1)
    )

    return cellPosition
  }

  private func mouse(event event: NSEvent, vimName: String) {
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

  private func shouldFireVimInputFor(event event:NSEvent, newCellPosition: Position) -> Bool {
    let type = event.type
    guard type == .LeftMouseDragged || type == .RightMouseDragged || type == .OtherMouseDragged  else {
      self.lastClickedCellPosition = newCellPosition
      return true
    }

    if self.lastClickedCellPosition == newCellPosition {
      return false
    }

    self.lastClickedCellPosition = newCellPosition
    return true
  }

  private func vimClickCountFrom(event event: NSEvent) -> String {
    let clickCount = event.clickCount

    guard 2 <= clickCount && clickCount <= 4 else {
      return ""
    }

    switch event.type {
    case .LeftMouseDown, .LeftMouseUp, .RightMouseDown, .RightMouseUp:
      return "\(clickCount)-"
    default:
      return ""
    }
  }
  
  private func vimScrollEventNamesFor(deltaX deltaX: CGFloat, deltaY: CGFloat) -> (String, String) {
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
  
  private func vimScrollInputFor(deltaX deltaX: CGFloat, deltaY: CGFloat,
                                        modifierFlags: NSEventModifierFlags,
                                        cellPosition: Position) -> (String, String)
  {
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
  
  private func throttleScrollX(absDelta absDeltaX: CGFloat, vimInput: String) {
    if absDeltaX == 0 {
      self.scrollGuardCounterX = self.scrollGuardYield - 1
    } else if absDeltaX <= 2 {
      // Poor man's throttle for scroll value = 1 or 2
      if self.scrollGuardCounterX % self.scrollGuardYield == 0  {
        self.agent.vimInput(vimInput)
        self.scrollGuardCounterX = 1
      } else {
        self.scrollGuardCounterX += 1
      }
    } else {
      self.agent.vimInput(vimInput)
    }
  }
  
  private func throttleScrollY(absDelta absDeltaY: CGFloat, vimInput: String) {
    if absDeltaY == 0 {
      self.scrollGuardCounterY = self.scrollGuardYield - 1
    } else if absDeltaY <= 2 {
      // Poor man's throttle for scroll value = 1 or 2
      if self.scrollGuardCounterY % self.scrollGuardYield == 0  {
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
