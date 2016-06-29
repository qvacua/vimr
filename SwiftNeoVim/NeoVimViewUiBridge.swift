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
    
      Swift.print("### resize to \(width):\(height)")
      self.grid.resize(Size(width: Int(width), height: Int(height)))
      self.delegate?.resizeToSize(rectSize)
    }
  }
  
  public func clear() {
    DispatchUtils.gui {
      Swift.print("### clear")
      self.grid.clear()
      self.needsDisplay = true
    }
  }
  
  public func eolClear() {
    DispatchUtils.gui {
      Swift.print("### eol clear")
      self.grid.eolClear()

      let origin = self.positionOnView(self.grid.position.row, column: self.grid.position.column)
      let size = CGSize(
        width: CGFloat(self.grid.region.right - self.grid.position.column + 1) * self.cellSize.width,
        height: self.cellSize.height
      )
      let rect = CGRect(origin: origin, size: size)
      self.setNeedsDisplayInRect(rect)
    }
  }
  
  public func cursorGotoRow(row: Int32, column: Int32) {
    DispatchUtils.gui {
      Swift.print("### goto: \(row):\(column)")
      self.setNeedsDisplayAt(position: self.grid.position)

      let newPosition = Position(row: Int(row), column: Int(column))
      self.grid.goto(newPosition)
      self.setNeedsDisplayAt(position: newPosition)
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
    Swift.print("### mode change to: \(String(format: "%04X", mode))")
  }
  
  public func setScrollRegionToTop(top: Int32, bottom: Int32, left: Int32, right: Int32) {
    Swift.print("### set scroll region: \(top), \(bottom), \(left), \(right)")
    DispatchUtils.gui {
      let region = Region(top: Int(top), bottom: Int(bottom), left: Int(left), right: Int(right))
      self.grid.setScrollRegion(region)
      self.setNeedsDisplayInRect(self.regionRect(region))
    }
  }
  
  public func scroll(count: Int32) {
    Swift.print("### scroll count: \(count)")

    DispatchUtils.gui {
      self.grid.scroll(Int(count))
      self.setNeedsDisplayInRect(self.regionRect(self.grid.region))
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
//      Swift.print("\(#function): \(string)")
      let curPos = Position(row: self.grid.position.row, column: self.grid.position.column)
      self.grid.put(string)

      self.setNeedsDisplayAt(position: curPos)
      if string.characters.count == 0 {
        self.setNeedsDisplayAt(row: curPos.row, column: max(curPos.column - 1, 0))
      }
      self.setNeedsDisplayAt(position: self.grid.position) // cursor
    }
  }

  public func putMarkedText(markedText: String) {
    DispatchUtils.gui {
//      Swift.print("\(#function): \(markedText)")
      let curPos = Position(row: self.grid.position.row, column: self.grid.position.column)
      self.grid.putMarkedText(markedText)

      self.setNeedsDisplayAt(position: curPos)
      if markedText.characters.count == 0 {
        self.setNeedsDisplayAt(row: curPos.row, column: max(curPos.column - 1, 0))
      }
      self.setNeedsDisplayAt(position: self.grid.position) // cursor
    }
  }

  public func unmarkRow(row: Int32, column: Int32) {
    DispatchUtils.gui {
//      Swift.print("\(#function): \(row):\(column)")
      self.grid.unmarkCell(Position(row: Int(row), column: Int(column)))
      self.setNeedsDisplayAt(row: Int(row), column: Int(column))
      self.setNeedsDisplayAt(position: self.grid.position) // cursor
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
    Swift.print("### stop")
  }

  private func setNeedsDisplayAt(position position: Position) {
    self.setNeedsDisplayAt(row: position.row, column: position.column)
  }

  private func setNeedsDisplayAt(row row: Int, column: Int) {
    Swift.print("\(#function): \(row):\(column)")
    self.setNeedsDisplayInRect(self.cellRect(row: row, column: column))
  }
}
