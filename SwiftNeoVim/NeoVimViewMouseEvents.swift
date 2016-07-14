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

  private func mouse(event event: NSEvent, vimName: String) {
    let location = self.convertPoint(event.locationInWindow, fromView: nil)
    let cellPosition = Position(
      row: min(Int(floor(location.x / self.cellSize.width)), self.grid.size.width - 1),
      column: min(Int(floor((self.bounds.height - location.y) / self.cellSize.height)), self.grid.size.height - 1)
    )

    guard self.shouldFireVimInputFor(event: event, newCellPosition: cellPosition) else {
//      NSLog("\(#function): not firing vim input")
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
}
