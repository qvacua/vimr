/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa

extension NeoVimView: NeoVimUiBridgeProtocol {

  public func resizeToWidth(width: Int32, height: Int32) {
    DispatchUtils.gui {
      let rectSize = CGSize(
        width: CGFloat(width) * self.cellSize.width,
        height: CGFloat(height) * self.cellSize.height
      )
    
//      Swift.print("### resize to \(width):\(height)")
      self.grid.resize(Size(width: Int(width), height: Int(height)))
      self.delegate?.resizeToSize(rectSize)
      // TODO: set needs display?
    }
  }
  
  public func clear() {
    DispatchUtils.gui {
//      Swift.print("### clear")
      self.grid.clear()
      self.needsDisplay = true
    }
  }
  
  public func eolClear() {
    DispatchUtils.gui {
//      Swift.print("### eol clear")
      self.grid.eolClear()

      let origin = self.pointInView(self.grid.putPosition)
      let size = CGSize(
        width: CGFloat(self.grid.region.right - self.grid.putPosition.column + 1) * self.cellSize.width,
        height: self.cellSize.height
      )
      let rect = CGRect(origin: origin, size: size)
      self.setNeedsDisplayInRect(rect)
    }
  }
  
  public func gotoPosition(position: Position, screenCursor: Position, bufferCursor: Position) {
    DispatchUtils.gui {
//      NSLog("\(#function): \(position), \(screenCursor), \(bufferCursor)")
      
      self.setNeedsDisplay(cellPosition: self.grid.screenCursor) // redraw where the cursor was till now
      self.setNeedsDisplay(screenCursor: screenCursor) // draw the new cursor

      self.grid.goto(position)
      self.grid.moveCursor(screenCursor)
    }
  }
  
  public func updateMenu() {
    //    Swift.print("### update menu")
  }
  
  public func busyStart() {
    //    Swift.print("### busy start")
  }
  
  public func busyStop() {
    //    Swift.print("### busy stop")
  }
  
  public func mouseOn() {
    //    Swift.print("### mouse on")
  }
  
  public func mouseOff() {
    //    Swift.print("### mouse off")
  }
  
  public func modeChange(mode: Int32) {
//    Swift.print("### mode change to: \(String(format: "%04X", mode))")
  }
  
  public func setScrollRegionToTop(top: Int32, bottom: Int32, left: Int32, right: Int32) {
//    Swift.print("### set scroll region: \(top), \(bottom), \(left), \(right)")
    DispatchUtils.gui {
      let region = Region(top: Int(top), bottom: Int(bottom), left: Int(left), right: Int(right))
      self.grid.setScrollRegion(region)
      self.setNeedsDisplay(region: region)
    }
  }
  
  public func scroll(count: Int32) {
//    Swift.print("### scroll count: \(count)")

    DispatchUtils.gui {
      self.grid.scroll(Int(count))
      self.setNeedsDisplay(region: self.grid.region)
    }
  }

  public func highlightSet(attrs: CellAttributes) {
    DispatchUtils.gui {
//      Swift.print("### set highlight")
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
//      Swift.print("\(#function): \(markedText)")
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
//      Swift.print("\(#function): \(row):\(column)")
      self.grid.unmarkCell(Position(row: Int(row), column: Int(column)))
      self.setNeedsDisplay(row: Int(row), column: Int(column))
      self.setNeedsDisplay(screenCursor: self.grid.screenCursor)
    }
  }

  public func bell() {
    DispatchUtils.gui {
      NSBeep()
    }
  }
  
  public func visualBell() {
    //    Swift.print("### visual bell")
  }
  
  public func flush() {
//    DispatchUtils.gui {
//      Swift.print("### flush")
//    }
  }
  
  public func updateForeground(fg: Int32) {
//      Swift.print("### update fg: \(String(format: "%x", fg))")
    DispatchUtils.gui {
      self.grid.foreground = UInt32(bitPattern: fg)
    }
  }
  
  public func updateBackground(bg: Int32) {
//      Swift.print("### update bg: \(String(format: "%x", bg))")
    DispatchUtils.gui {
      self.grid.background = UInt32(bitPattern: bg)
    }
  }
  
  public func updateSpecial(sp: Int32) {
//      Swift.print("### update sp: \(String(format: "%x", sp)")
    DispatchUtils.gui {
      self.grid.special = UInt32(bitPattern: sp)
    }
  }
  
  public func suspend() {
    //    Swift.print("### suspend")
  }
  
  public func setTitle(title: String) {
    self.delegate?.setTitle(title)
  }
  
  public func setIcon(icon: String) {
    //    Swift.print("### set icon: \(icon)")
  }
  
  public func stop() {
//    Swift.print("### stop")
  }
  
  private func setNeedsDisplay(region region: Region) {
    self.setNeedsDisplayInRect(self.regionRect(region))
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
    self.setNeedsDisplayInRect(self.cellRect(row: row, column: column))
  }

  private func setNeedsDisplay(screenCursor position: Position) {
    self.setNeedsDisplay(position: position)
    if self.grid.isNextCellEmpty(position) {
      self.setNeedsDisplay(position: self.grid.nextCellPosition(position))
    }
  }
}
