/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa

extension NeoVimView: NeoVimUiBridgeProtocol {

  public func neoVimUiIsReady() {
    DispatchUtils.gui {
      self.resizeNeoVimUiTo(size: self.frame.size)
    }
  }

  public func resizeToWidth(width: Int32, height: Int32) {
    DispatchUtils.gui {
//      NSLog("\(#function): \(width):\(height)")
      self.grid.resize(Size(width: Int(width), height: Int(height)))
      self.needsDisplay = true
    }
  }
  
  public func clear() {
    DispatchUtils.gui {
      self.grid.clear()
      self.needsDisplay = true
    }
  }
  
  public func eolClear() {
    DispatchUtils.gui {
      self.grid.eolClear()

      let origin = self.pointInViewFor(position: self.grid.putPosition)
      let size = CGSize(
        width: CGFloat(self.grid.region.right - self.grid.putPosition.column + 1) * self.cellSize.width,
        height: self.cellSize.height
      )
      let rect = CGRect(origin: origin, size: size)
      self.setNeedsDisplayInRect(rect)
    }
  }
  
  public func gotoPosition(position: Position, screenCursor: Position) {
    DispatchUtils.gui {
//      NSLog("\(#function): \(position), \(screenCursor)")

      self.setNeedsDisplay(cellPosition: self.grid.screenCursor) // redraw where the cursor was till now
      self.setNeedsDisplay(screenCursor: screenCursor) // draw the new cursor

      self.grid.goto(position)
      self.grid.moveCursor(screenCursor)
    }
  }
  
  public func updateMenu() {
  }
  
  public func busyStart() {
  }
  
  public func busyStop() {
  }
  
  public func mouseOn() {
  }
  
  public func mouseOff() {
  }
  
  public func modeChange(mode: Int32) {
  }
  
  public func setScrollRegionToTop(top: Int32, bottom: Int32, left: Int32, right: Int32) {
    DispatchUtils.gui {
      let region = Region(top: Int(top), bottom: Int(bottom), left: Int(left), right: Int(right))
      self.grid.setScrollRegion(region)
      self.setNeedsDisplay(region: region)
    }
  }
  
  public func scroll(count: Int32) {
    DispatchUtils.gui {
      self.grid.scroll(Int(count))
      self.setNeedsDisplay(region: self.grid.region)
    }
  }

  public func highlightSet(attrs: CellAttributes) {
    DispatchUtils.gui {
      self.grid.attrs = attrs
    }
  }
  
  public func put(string: String) {
    DispatchUtils.gui {
      let curPos = self.grid.putPosition
//      NSLog("\(#function): \(curPos) -> \(string)")
      self.grid.put(string)
      self.setNeedsDisplay(cellPosition: curPos)
      
      self.setNeedsDisplay(screenCursor: self.grid.screenCursor)
    }
  }

  public func putMarkedText(markedText: String) {
    DispatchUtils.gui {
      NSLog("\(#function): '\(markedText)'")
      let curPos = self.grid.putPosition
      self.grid.putMarkedText(markedText)

      self.setNeedsDisplay(position: curPos)
      if markedText.characters.count == 0 {
        self.setNeedsDisplay(position: self.grid.previousCellPosition(curPos))
      }
      self.setNeedsDisplay(screenCursor: self.grid.screenCursor)
    }
  }

  public func unmarkRow(row: Int32, column: Int32) {
    DispatchUtils.gui {
      let position = Position(row: Int(row), column: Int(column))

      NSLog("\(#function): \(position)")

      self.grid.unmarkCell(position)
      self.setNeedsDisplay(position: position)
      
      self.setNeedsDisplay(screenCursor: self.grid.screenCursor)
    }
  }

  public func bell() {
    DispatchUtils.gui {
      NSBeep()
    }
  }
  
  public func visualBell() {
  }
  
  public func flush() {
//    Swift.print("\(self.grid)")
  }
  
  public func updateForeground(fg: Int32) {
    DispatchUtils.gui {
      self.grid.foreground = UInt32(bitPattern: fg)
    }
  }
  
  public func updateBackground(bg: Int32) {
    DispatchUtils.gui {
      self.grid.background = UInt32(bitPattern: bg)
      self.layer?.backgroundColor = ColorUtils.colorIgnoringAlpha(self.grid.background).CGColor
    }
  }
  
  public func updateSpecial(sp: Int32) {
    DispatchUtils.gui {
      self.grid.special = UInt32(bitPattern: sp)
    }
  }
  
  public func suspend() {
  }
  
  public func setTitle(title: String) {
    self.delegate?.setTitle(title)
  }
  
  public func setIcon(icon: String) {
  }
  
  public func stop() {
  }
  
  private func setNeedsDisplay(region region: Region) {
    self.setNeedsDisplayInRect(self.regionRectFor(region: region))
  }
  
  private func setNeedsDisplay(cellPosition position: Position) {
    self.setNeedsDisplay(position: position)
    
    if self.grid.isCellEmpty(position) {
      self.setNeedsDisplay(position: self.grid.previousCellPosition(position))
    }
    
    if self.grid.isNextCellEmpty(position) {
      self.setNeedsDisplay(position: self.grid.nextCellPosition(position))
    }
  }

  private func setNeedsDisplay(position position: Position) {
    self.setNeedsDisplay(row: position.row, column: position.column)
  }

  private func setNeedsDisplay(row row: Int, column: Int) {
//    Swift.print("\(#function): \(row):\(column)")
    self.setNeedsDisplayInRect(self.cellRectFor(row: row, column: column))
  }

  private func setNeedsDisplay(screenCursor position: Position) {
    self.setNeedsDisplay(position: position)
    if self.grid.isNextCellEmpty(position) {
      self.setNeedsDisplay(position: self.grid.nextCellPosition(position))
    }
  }
}
