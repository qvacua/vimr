/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa

extension NeoVimView {

  public func resize(toWidth width: Int, height: Int) {
    gui.async {
      self.bridgeLogger.debug("\(width) x \(height)")

      self.grid.resize(Size(width: width, height: height))
      self.markForRenderWholeView()
    }
  }

  public func clear() {
    gui.async {
      self.bridgeLogger.mark()

      self.grid.clear()
      self.markForRenderWholeView()
    }
  }

  public func eolClear() {
    gui.async {
      self.bridgeLogger.mark()

      self.grid.eolClear()

      let putPosition = self.grid.putPosition
      let region = Region(top: putPosition.row,
                          bottom: putPosition.row,
                          left: putPosition.column,
                          right: self.grid.region.right)
      self.markForRender(region: region)
    }
  }

  public func gotoPosition(_ position: Position,
                           screenCursor: Position,
                           currentPosition: Position) {

    gui.async {
      self.bridgeLogger.debug("pos: \(position), screen: \(screenCursor), " +
                        "current-pos: \(currentPosition)")

      self.currentPosition = currentPosition
      let curScreenCursor = self.grid.screenCursor

      // Because neovim fills blank space with "Space" and when we enter "Space"
      // we don't get the puts, thus we have to redraw the put position.
      if self.usesLigatures {
        self.markForRender(region: self.grid.regionOfWord(at: self.grid.putPosition))
        self.markForRender(region: self.grid.regionOfWord(at: curScreenCursor))
        self.markForRender(region: self.grid.regionOfWord(at: position))
        self.markForRender(region: self.grid.regionOfWord(at: screenCursor))
      } else {
        self.markForRender(cellPosition: self.grid.putPosition)
        // Redraw where the cursor has been till now, ie remove the current cursor.
        self.markForRender(cellPosition: curScreenCursor)
        if self.grid.isPreviousCellEmpty(curScreenCursor) {
          self.markForRender(cellPosition: self.grid.previousCellPosition(curScreenCursor))
        }
        if self.grid.isNextCellEmpty(curScreenCursor) {
          self.markForRender(cellPosition: self.grid.nextCellPosition(curScreenCursor))
        }
        self.markForRender(cellPosition: position)
        self.markForRender(cellPosition: screenCursor)
      }

      self.grid.goto(position)
      self.grid.moveCursor(screenCursor)
    }
    gui.async {
      self.delegate?.cursor(to: currentPosition)
    }
  }

  public func modeChange(_ mode: CursorModeShape) {
    gui.async {
      self.bridgeLogger.debug(cursorModeShapeName(mode))
      self.mode = mode
      self.updateCursorWhenPutting(currentPosition: .zero, screenCursor: .zero)
    }
  }

  public func setScrollRegionToTop(_ top: Int, bottom: Int, left: Int, right: Int) {
    gui.async {
      self.bridgeLogger.debug("\(top):\(bottom):\(left):\(right)")

      let region = Region(top: top, bottom: bottom, left: left, right: right)
      self.grid.setScrollRegion(region)
    }
  }

  public func scroll(_ count: Int) {
    gui.async {
      self.bridgeLogger.debug(count)

      self.grid.scroll(count)
      self.markForRender(region: self.grid.region)
      // Do not send msgs to agent -> neovim in the delegate method. It causes spinning
      // when you're opening a file with existing swap file.
      self.delegate?.scroll()
    }
  }

  public func highlightSet(_ attrs: CellAttributes) {
    gui.async {
      self.bridgeLogger.debug(attrs)

      self.grid.attrs = attrs
    }
  }

  public func put(_ string: String, screenCursor: Position) {
    gui.async {
      let curPos = self.grid.putPosition
      self.bridgeLogger.debug("\(curPos) -> \(string) <- screen: \(screenCursor)")

      self.grid.put(string)

      if self.usesLigatures {
        if string == " " {
          self.markForRender(cellPosition: curPos)
        } else {
          self.markForRender(region: self.grid.regionOfWord(at: curPos))
        }
      } else {
        self.markForRender(cellPosition: curPos)
      }

      self.updateCursorWhenPutting(currentPosition: curPos, screenCursor: screenCursor)
    }
  }

  public func putMarkedText(_ markedText: String, screenCursor: Position) {
    gui.async {
      self.bridgeLogger.debug("'\(markedText)' <- screen: \(screenCursor)")

      let curPos = self.grid.putPosition
      self.grid.putMarkedText(markedText)

      self.markForRender(position: curPos)
      // When the cursor is in the command line, then we need this...
      self.markForRender(cellPosition: self.grid.nextCellPosition(curPos))
      if markedText.characters.count == 0 {
        self.markForRender(position: self.grid.previousCellPosition(curPos))
      }

      self.updateCursorWhenPutting(currentPosition: curPos, screenCursor: screenCursor)
    }
  }

  public func unmarkRow(_ row: Int, column: Int) {
    gui.async {
      self.bridgeLogger.debug("\(row):\(column)")

      let position = Position(row: row, column: column)

      self.grid.unmarkCell(position)
      self.markForRender(position: position)

      self.markForRender(screenCursor: self.grid.screenCursor)
    }
  }

  public func flush() {
    gui.async {
      self.bridgeLogger.debug("-----------------------------")
    }
  }

  public func updateForeground(_ fg: Int) {
    gui.async {
      self.bridgeLogger.debug(ColorUtils.colorIgnoringAlpha(fg))

      self.grid.foreground = fg
    }
  }

  public func updateBackground(_ bg: Int) {
    gui.async {
      self.bridgeLogger.debug(ColorUtils.colorIgnoringAlpha(bg))

      self.grid.background = bg
      self.layer?.backgroundColor = ColorUtils.colorIgnoringAlpha(self.grid.background).cgColor
    }
  }

  public func updateSpecial(_ sp: Int) {
    gui.async {
      self.bridgeLogger.debug(ColorUtils.colorIgnoringAlpha(sp))

      self.grid.special = sp
    }
  }

  public func setTitle(_ title: String) {
    gui.async {
      self.bridgeLogger.debug(title)

      self.delegate?.set(title: title)
    }
  }

  public func stop() {
    gui.async {
      self.bridgeLogger.mark()

      self.agent.quit()
      self.delegate?.neoVimStopped()
    }
  }

  public func autoCommandEvent(_ event: NeoVimAutoCommandEvent, bufferHandle: Int) {
    gui.async {
//      self.bridgeLogger.debug("\(neoVimAutoCommandEventName(event)) -> \(bufferHandle)")

      if event == .BUFWINENTER || event == .BUFWINLEAVE {
        self.bufferListChanged()
      }

      if event == .TABENTER {
        self.tabChanged()
      }

      if event == .DIRCHANGED {
        self.cwdChanged()
      }

      if event == .BUFREADPOST || event == .BUFWRITEPOST {
        self.currentBufferChanged(bufferHandle)
      }
    }
  }

  public func ipcBecameInvalid(_ reason: String) {
    gui.async {
      self.bridgeLogger.debug(reason)

      if self.agent.neoVimIsQuitting {
        return
      }

      self.delegate?.ipcBecameInvalid(reason: reason)

      self.bridgeLogger.fault("force-quitting")
      self.agent.quit()
    }
  }
}

// MARK: - Simple
extension NeoVimView {

  public func bell() {
    gui.async {
      self.bridgeLogger.mark()

      NSBeep()
    }
  }

  public func setDirtyStatus(_ dirty: Bool) {
    gui.async {
      self.bridgeLogger.debug(dirty)

      self.delegate?.set(dirtyStatus: dirty)
    }
  }

  public func updateMenu() {
    gui.async {
      self.bridgeLogger.mark()
    }
  }

  public func busyStart() {
    gui.async {
      self.bridgeLogger.mark()
    }
  }

  public func busyStop() {
    gui.async {
      self.bridgeLogger.mark()
    }
  }

  public func mouseOn() {
    gui.async {
      self.bridgeLogger.mark()
    }
  }

  public func mouseOff() {
    gui.async {
      self.bridgeLogger.mark()
    }
  }

  public func visualBell() {
    gui.async {
      self.bridgeLogger.mark()
    }
  }

  public func suspend() {
    gui.async {
      self.bridgeLogger.mark()
    }
  }

  public func setIcon(_ icon: String) {
    gui.async {
      self.bridgeLogger.debug(icon)
    }
  }
}

extension NeoVimView {

  func markForRender(cellPosition position: Position) {
    self.markForRender(position: position)

    if self.grid.isCellEmpty(position) {
      self.markForRender(position: self.grid.previousCellPosition(position))
    }

    if self.grid.isNextCellEmpty(position) {
      self.markForRender(position: self.grid.nextCellPosition(position))
    }
  }

  func markForRender(position: Position) {
    self.markForRender(row: position.row, column: position.column)
  }

  func markForRender(screenCursor position: Position) {
    self.markForRender(position: position)
    if self.grid.isNextCellEmpty(position) {
      self.markForRender(position: self.grid.nextCellPosition(position))
    }
  }

  func markForRenderWholeView() {
    self.needsDisplay = true
  }

  func markForRender(region: Region) {
    self.setNeedsDisplay(self.rect(for: region))
  }

  func markForRender(row: Int, column: Int) {
    self.setNeedsDisplay(self.rect(forRow: row, column: column))
  }
}

extension NeoVimView {

  fileprivate func currentBufferChanged(_ handle: Int) {
    guard let currentBuffer = self.currentBuffer() else {
      return
    }

    guard currentBuffer.handle == handle else {
      return
    }

    self.delegate?.currentBufferChanged(currentBuffer)
  }

  fileprivate func tabChanged() {
    self.delegate?.tabChanged()
  }

  fileprivate func cwdChanged() {
    self.delegate?.cwdChanged()
  }

  fileprivate func bufferListChanged() {
    self.delegate?.bufferListChanged()
  }

  fileprivate func updateCursorWhenPutting(currentPosition curPos: Position,
                                           screenCursor: Position) {

    if self.mode == .cmdline {
      // When the cursor is in the command line, then we need this...
      self.markForRender(cellPosition: self.grid.previousCellPosition(curPos))
      self.markForRender(cellPosition: self.grid.nextCellPosition(curPos))
      self.markForRender(screenCursor: self.grid.putPosition)
    }

    self.markForRender(screenCursor: screenCursor)
    self.markForRender(cellPosition: self.grid.screenCursor)
    self.grid.moveCursor(screenCursor)
  }
}

fileprivate let gui = DispatchQueue.main