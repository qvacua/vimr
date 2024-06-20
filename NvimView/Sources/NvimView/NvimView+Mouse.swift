/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import MessagePack
import RxNeovim
import RxSwift

public extension NvimView {
  override func mouseDown(with event: NSEvent) {
    self.mouse(event: event, vimName: "LeftMouse")
  }

  override func mouseUp(with event: NSEvent) {
    self.mouse(event: event, vimName: "LeftRelease")
  }

  override func mouseDragged(with event: NSEvent) {
    self.mouse(event: event, vimName: "LeftDrag")
  }

  override func rightMouseDown(with event: NSEvent) {
    self.mouse(event: event, vimName: "RightMouse")
  }

  override func rightMouseUp(with event: NSEvent) {
    self.mouse(event: event, vimName: "RightRelease")
  }

  override func rightMouseDragged(with event: NSEvent) {
    self.mouse(event: event, vimName: "RightDrag")
  }

  override func otherMouseUp(with event: NSEvent) {
    self.mouse(event: event, vimName: "MiddleMouse")
  }

  override func otherMouseDown(with event: NSEvent) {
    self.mouse(event: event, vimName: "MiddleRelease")
  }

  override func otherMouseDragged(with event: NSEvent) {
    self.mouse(event: event, vimName: "MiddleDrag")
  }

  override func scrollWheel(with event: NSEvent) {
    let (deltaX, deltaY) = self.scrollDelta(forEvent: event)

    if deltaX == 0, deltaY == 0 { return }

    let vimInput = self.vimScrollInput(forEvent: event)

    let mousescroll: String
    if event.hasPreciseScrollingDeltas { // trackpad
      let (absDeltaX, absDeltaY) = (abs(deltaX), abs(deltaY))
      mousescroll = "ver:\(absDeltaY),hor:\(absDeltaX)"
    } else {
      mousescroll = ""
    }

    return self.api.nvimExecLua(code: """
    local arg = {...}

    if vim.g.vimr_save_mousescroll == nil then
        vim.g.vimr_save_mousescroll = vim.o.mousescroll
    end

    if arg[1] ~= "" then
      vim.o.mousescroll = arg[1]
    end

    vim.api.nvim_input(arg[2])

    -- nvim_input() only queues input, schedule resetting
    -- mousescroll to after the input hase been processed
    vim.schedule(function()
      vim.o.mousescroll = vim.g.vimr_save_mousescroll
      vim.g.vimr_save_mousescroll = nil
    end)
    """, args: [MessagePackValue(mousescroll), MessagePackValue(vimInput)])
      .subscribe(onFailure: { [weak self] error in
        self?.log.error("Error in \(#function): \(error)")
      })
      .disposed(by: self.disposeBag)
  }

  internal func scrollDelta(forEvent event: NSEvent) -> (Int, Int) {
    let isTrackpad = event.hasPreciseScrollingDeltas

    if !isTrackpad {
      return (Int(event.scrollingDeltaX), Int(event.scrollingDeltaY))
    }

    if event.phase == .began {
      self.trackpadScrollDeltaX = 0
      self.trackpadScrollDeltaY = 0
    }

    self.trackpadScrollDeltaX += event.scrollingDeltaX
    self.trackpadScrollDeltaY += event.scrollingDeltaY

    let (deltaCellX, deltaCellY) = (
      (self.trackpadScrollDeltaX / self.cellSize.width).rounded(.toNearestOrEven),
      (self.trackpadScrollDeltaY / self.cellSize.height).rounded(.toNearestOrEven)
    )

    self.trackpadScrollDeltaX.formRemainder(dividingBy: self.cellSize.width)
    self.trackpadScrollDeltaY.formRemainder(dividingBy: self.cellSize.height)

    let (deltaX, deltaY) = (
      min(Int(deltaCellX), maxScrollDeltaX),
      min(Int(deltaCellY), maxScrollDeltaY)
    )

    return (deltaX, deltaY)
  }

  override func magnify(with event: NSEvent) {
    let factor = 1 + event.magnification
    let pinchTargetScale = self.pinchTargetScale * factor
    let resultingFontSize = round(pinchTargetScale * self.font.pointSize)
    if resultingFontSize >= NvimView.minFontSize, resultingFontSize <= NvimView.maxFontSize {
      self.pinchTargetScale = pinchTargetScale
    }

    switch event.phase {
    case .began:
      let pinchImageRep = self.bitmapImageRepForCachingDisplay(in: self.bounds)!
      self.cacheDisplay(in: self.bounds, to: pinchImageRep)
      self.pinchBitmap = pinchImageRep

      self.isCurrentlyPinching = true

    case .ended, .cancelled:
      self.isCurrentlyPinching = false
      self.updateFontMetaData(NSFontManager.shared.convert(self.font, toSize: resultingFontSize))
      self.pinchTargetScale = 1

    default:
      break
    }

    self.markForRenderWholeView()
  }

  internal func position(at location: CGPoint) -> Position {
    let row = Int((self.bounds.size.height - location.y - self.offset.y) / self.cellSize.height)
    let column = Int((location.x - self.offset.x) / self.cellSize.width)

    let position = Position(
      row: min(max(0, row), self.ugrid.size.height - 1),
      column: min(max(0, column), self.ugrid.size.width - 1)
    )
    return position
  }

  private func cellPosition(forEvent event: NSEvent) -> Position {
    let location = self.convert(event.locationInWindow, from: nil)
    return self.position(at: location)
  }

  private func mouse(event: NSEvent, vimName: String) {
    let cellPosition = self.cellPosition(forEvent: event)
    guard self.shouldFireVimInputFor(event: event, newCellPosition: cellPosition) else { return }

    let vimMouseLocation = self.wrapNamedKeys("\(cellPosition.column),\(cellPosition.row)")
    let vimClickCount = self.vimClickCountFrom(event: event)

    let result: String = if let vimModifiers = self.vimModifierFlags(event.modifierFlags) {
      self.wrapNamedKeys("\(vimModifiers)\(vimClickCount)\(vimName)") + vimMouseLocation
    } else {
      self.wrapNamedKeys("\(vimClickCount)\(vimName)") + vimMouseLocation
    }

    self.api
      .nvimInput(keys: result)
      .subscribe(onFailure: { [weak self] error in
        self?.log.error("Error in \(#function): \(error)")
      })
      .disposed(by: self.disposeBag)
  }

  private func shouldFireVimInputFor(event: NSEvent, newCellPosition: Position) -> Bool {
    let type = event.type
    guard type == .leftMouseDragged
      || type == .rightMouseDragged
      || type == .otherMouseDragged
    else {
      self.lastClickedCellPosition = newCellPosition
      return true
    }

    if self.lastClickedCellPosition == newCellPosition { return false }

    self.lastClickedCellPosition = newCellPosition
    return true
  }

  private func vimClickCountFrom(event: NSEvent) -> String {
    let clickCount = event.clickCount

    guard clickCount >= 2, clickCount <= 4 else { return "" }

    switch event.type {
    case .leftMouseDown, .leftMouseUp, .rightMouseDown, .rightMouseUp: return "\(clickCount)-"
    default: return ""
    }
  }

  private func vimScrollInput(forEvent event: NSEvent) -> String {
    let cellPosition = self.cellPosition(forEvent: event)

    let vimMouseLocation = self.wrapNamedKeys("\(cellPosition.column),\(cellPosition.row)")

    let vimModifiers = self.vimModifierFlags(event.modifierFlags) ?? ""

    let (deltaX, deltaY) = (event.scrollingDeltaX, event.scrollingDeltaY)

    let resultX: String
    if deltaX == 0 {
      resultX = ""
    } else {
      let wheel = (deltaX < 0) ? "ScrollWheelRight" : "ScrollWheelLeft"
      resultX = self.wrapNamedKeys("\(vimModifiers)\(wheel)") + vimMouseLocation
    }

    let resultY: String
    if deltaY == 0 {
      resultY = ""
    } else {
      let wheel = (deltaY < 0) ? "ScrollWheelDown" : "ScrollWheelUp"
      resultY = self.wrapNamedKeys("\(vimModifiers)\(wheel)") + vimMouseLocation
    }

    return "\(resultX)\(resultY)"
  }
}

private let maxScrollDeltaX = 15
private let maxScrollDeltaY = 15
