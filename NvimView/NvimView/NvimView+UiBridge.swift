/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import NvimMsgPack
import RxSwift

extension NvimView {

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

      let putPosition = self.grid.position
      let region = Region(top: putPosition.row,
                          bottom: putPosition.row,
                          left: putPosition.column,
                          right: self.grid.region.right)
      self.markForRender(region: region)
    }
  }

  public func modeChange(_ mode: CursorModeShape) {
    gui.async {
      self.bridgeLogger.debug(self.cursorModeShapeName(mode))
      self.mode = mode
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
      self.eventsSubject.onNext(.scroll)
    }
  }

  public func unmarkRow(_ row: Int, column: Int) {
    gui.async {
      self.bridgeLogger.debug("\(row):\(column)")

      let position = Position(row: row, column: column)

      self.grid.unmarkCell(position)
      self.markForRender(position: position)
    }
  }

  public func flush(_ renderData: [Data]) {
    gui.async {
      self.bridgeLogger.hr()

      renderData.forEach { data in
        data.withUnsafeBytes { (pointer: UnsafePointer<RenderDataType>) in
          let sizeOfType = MemoryLayout<RenderDataType>.size
          let rawPointer = UnsafeRawPointer(pointer).advanced(by: sizeOfType);
          let renderType = pointer[0]

          switch renderType {

          case .put:
            guard let str = String(data: Data(bytes: rawPointer, count: data.count - sizeOfType),
                                   encoding: .utf8)
              else {
              break
            }

            self.doPut(string: str)

          case .putMarked:
            guard let str = String(data: Data(bytes: rawPointer, count: data.count - sizeOfType),
                                   encoding: .utf8)
              else {
              break
            }

            self.doPutMarked(markedText: str)

          case .highlight:
            let attr = rawPointer.load(as: CellAttributes.self)
            self.doHighlightSet(attr)

          case .goto:
            let values = rawPointer.bindMemory(to: Int.self, capacity: 4)
            self.doGotoPosition(Position(row: values[0], column: values[1]),
                                textPosition: Position(row: values[2], column: values[3]))

          }
        }
      }

      self.shouldDrawCursor = true

      if self.usesLigatures {
        self.markForRender(region: self.grid.regionOfWord(at: self.grid.position))
      } else {
        self.markForRender(cellPosition: self.grid.position)
      }
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
    self.bridgeLogger.debug(title)

    self.eventsSubject.onNext(.setTitle(title))
  }

  public func stop() {
    self.bridgeLogger.hr()
    self.nvim.disconnect()
    self.uiClient.quit()

    gui.async {
      self.waitForNeoVimToQuit()
      self.eventsSubject.onNext(.neoVimStopped)
      self.eventsSubject.onCompleted()
    }
  }

  public func autoCommandEvent(_ event: NvimAutoCommandEvent, bufferHandle: Int) {
    self.bridgeLogger.debug("\(nvimAutoCommandEventName(event)) -> \(bufferHandle)")

    if event == .BUFWINENTER || event == .BUFWINLEAVE {
      self.bufferListChanged()
    }

    if event == .TABENTER {
      self.eventsSubject.onNext(.tabChanged)
    }

    if event == .BUFWRITEPOST {
      self.bufferWritten(bufferHandle)
    }

    if event == .BUFENTER {
      self.newCurrentBuffer(bufferHandle)
    }
  }

  public func ipcBecameInvalid(_ reason: String) {
    gui.async {
      self.bridgeLogger.debug(reason)

      if self.uiClient.neoVimIsQuitting || self.uiClient.neoVimHasQuit {
        return
      }

      self.eventsSubject.onNext(.ipcBecameInvalid(reason))
      self.eventsSubject.onCompleted()

      self.bridgeLogger.error("Force-closing due to IPC error.")
      self.nvim.disconnect()
      self.uiClient.forceQuit()
    }
  }

  private func doPut(string: String) {
    let curPos = self.grid.position
//      self.bridgeLogger.debug("\(curPos) -> \(string)")

    self.grid.put(string.precomposedStringWithCanonicalMapping)

    if self.usesLigatures {
      if string == " " {
        self.markForRender(cellPosition: curPos)
      } else {
        self.markForRender(region: self.grid.regionOfWord(at: curPos))
      }
    } else {
      self.markForRender(cellPosition: curPos)
    }
  }

  private func doPutMarked(markedText: String) {
    let curPos = self.grid.position
//      self.bridgeLogger.debug("\(curPos) -> '\(markedText)'")

    self.grid.putMarkedText(markedText)

    self.markForRender(position: curPos)
    // When the cursor is in the command line, then we need this...
    self.markForRender(cellPosition: self.grid.nextCellPosition(curPos))
    if markedText.count == 0 {
      self.markForRender(position: self.grid.previousCellPosition(curPos))
    }
  }

  private func doHighlightSet(_ attrs: CellAttributes) {
    self.bridgeLogger.debug(attrs)
    self.grid.attrs = attrs
  }

  private func doGotoPosition(_ position: Position, textPosition: Position) {
    self.bridgeLogger.debug(position)

    self.markForRender(cellPosition: self.grid.position)
    self.grid.goto(position)

    self.eventsSubject.onNext(.cursor(textPosition))
  }
}

// MARK: - Simple
extension NvimView {

  public func bell() {
    self.bridgeLogger.mark()

    NSSound.beep()
  }

  public func cwdChanged(_ cwd: String) {
    self.bridgeLogger.debug(cwd)

    self._cwd = URL(fileURLWithPath: cwd)
    self.eventsSubject.onNext(.cwdChanged)
  }
  public func colorSchemeChanged(_ values: [NSNumber]) {
    gui.async {
      let theme = Theme(values.map { $0.intValue })
      self.bridgeLogger.debug(theme)

      self.theme = theme
      self.eventsSubject.onNext(.colorschemeChanged(theme))
    }
  }

  public func setDirtyStatus(_ dirty: Bool) {
    self.bridgeLogger.debug(dirty)

    self.eventsSubject.onNext(.setDirtyStatus(dirty))
  }

  public func updateMenu() {
    self.bridgeLogger.mark()
  }

  public func busyStart() {
    self.bridgeLogger.mark()
  }

  public func busyStop() {
    self.bridgeLogger.mark()
  }

  public func mouseOn() {
    self.bridgeLogger.mark()
  }

  public func mouseOff() {
    self.bridgeLogger.mark()
  }

  public func visualBell() {
    self.bridgeLogger.mark()
  }

  public func suspend() {
    self.bridgeLogger.mark()
  }

  public func setIcon(_ icon: String) {
    self.bridgeLogger.debug(icon)
  }
}

extension NvimView {

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

extension NvimView {

  private func bufferWritten(_ handle: Int) {
    self
      .currentBuffer()
      .map { curBuf -> NvimView.Buffer in
        guard let buffer = self.neoVimBuffer(for: NvimApi.Buffer(handle), currentBuffer: curBuf.apiBuffer) else {
          throw NvimView.Error.api("Could not get buffer for buffer handle \(handle).")
        }

        return buffer
      }
      .subscribe(onSuccess: {
        self.eventsSubject.onNext(.bufferWritten($0))
        if #available(OSX 10.12.2, *) {
          self.updateTouchBarTab()
        }
      })
  }

  private func newCurrentBuffer(_ handle: Int) {
    self
      .currentBuffer()
      .filter { $0.apiBuffer.handle == handle }
      .subscribe(onSuccess: {
        self.eventsSubject.onNext(.newCurrentBuffer($0))
        if #available(OSX 10.12.2, *) {
          self.updateTouchBarTab()
        }
      })
  }

  private func bufferListChanged() {
    self.eventsSubject.onNext(.bufferListChanged)
    if #available(OSX 10.12.2, *) {
      self.updateTouchBarCurrentBuffer()
    }
  }

  private func cursorModeShapeName(_ mode: CursorModeShape) -> String {
    switch mode {
    case .normal: return "Normal"
    case .visual: return "Visual"
    case .insert: return "Insert"
    case .replace: return "Replace"
    case .cmdline: return "Cmdline"
    case .cmdlineInsert: return "CmdlineInsert"
    case .cmdlineReplace: return "CmdlineReplace"
    case .operatorPending: return "OperatorPending"
    case .visualExclusive: return "VisualExclusive"
    case .onCmdline: return "OnCmdline"
    case .onStatusLine: return "OnStatusLine"
    case .draggingStatusLine: return "DraggingStatusLine"
    case .onVerticalSepLine: return "OnVerticalSepLine"
    case .draggingVerticalSepLine: return "DraggingVerticalSepLine"
    case .more: return "More"
    case .moreLastLine: return "MoreLastLine"
    case .showingMatchingParen: return "ShowingMatchingParen"
    case .termFocus: return "TermFocus"
    case .count: return "Count"
    }
  } 
}

private let gui = DispatchQueue.main
