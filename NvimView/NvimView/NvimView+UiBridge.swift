/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import NvimMsgPack
import RxSwift

extension NvimView {

  func resize(width: Int, height: Int) {
    self.bridgeLogger.debug("\(width) x \(height)")

    gui.async {
      self.grid.resize(Size(width: width, height: height))
      self.markForRenderWholeView()
    }
  }

  func clear() {
    self.bridgeLogger.mark()

    gui.async {
      self.grid.clear()
      self.markForRenderWholeView()
    }
  }

  func modeChange(_ mode: CursorModeShape) {
    self.bridgeLogger.debug(name(of: mode))

    gui.async {
      self.mode = mode
    }
  }

  func setScrollRegion(top: Int, bottom: Int, left: Int, right: Int) {
    self.bridgeLogger.debug("\(top):\(bottom):\(left):\(right)")

    gui.async {
      let region = Region(top: top, bottom: bottom, left: left, right: right)
      self.grid.setScrollRegion(region)
    }
  }

  func scroll(_ count: Int) {
    self.bridgeLogger.debug(count)

    gui.async {
      self.grid.scroll(count)
      self.markForRender(region: self.grid.region)
      // Do not send msgs to agent -> neovim in the delegate method. It causes spinning
      // when you're opening a file with existing swap file.
      self.eventsSubject.onNext(.scroll)
    }
  }

  func unmark(row: Int, column: Int) {
    self.bridgeLogger.debug("\(row):\(column)")

    gui.async {
      let position = Position(row: row, column: column)

      self.grid.unmarkCell(position)
      self.markForRender(position: position)
    }
  }

  func flush(_ renderData: [Data]) {
    self.bridgeLogger.hr()

    gui.async {
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

            self.doPut(markedText: str)

          case .highlight:
            let attr = rawPointer.load(as: CellAttributes.self)
            self.doHighlightSet(attr)

          case .goto:
            let values = rawPointer.bindMemory(to: Int.self, capacity: 4)
            self.doGoto(position: Position(row: values[0], column: values[1]),
                        textPosition: Position(row: values[2], column: values[3]))

          case .eolClear:
            self.doEolClear()

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

  func update(foreground fg: Int) {
    self.bridgeLogger.debug(ColorUtils.colorIgnoringAlpha(fg))

    gui.async {
      self.grid.foreground = fg
    }
  }

  func update(background bg: Int) {
    self.bridgeLogger.debug(ColorUtils.colorIgnoringAlpha(bg))

    gui.async {
      self.grid.background = bg
      self.layer?.backgroundColor = ColorUtils.colorIgnoringAlpha(self.grid.background).cgColor
    }
  }

  func update(special sp: Int) {
    self.bridgeLogger.debug(ColorUtils.colorIgnoringAlpha(sp))

    gui.async {
      self.grid.special = sp
    }
  }

  func set(title: String) {
    self.bridgeLogger.debug(title)

    self.eventsSubject.onNext(.setTitle(title))
  }

  func stop() {
    self.bridgeLogger.hr()
    try? self.api
      .stop()
      .andThen(self.bridge.quit())
      .wait()

    gui.async {
      self.waitForNeoVimToQuit()
      self.eventsSubject.onNext(.neoVimStopped)
      self.eventsSubject.onCompleted()
    }
  }

  func autoCommandEvent(_ event: NvimAutoCommandEvent, bufferHandle: Int) {
    self.bridgeLogger.debug("\(event) -> \(bufferHandle)")

    if event == .bufwinenter || event == .bufwinleave {
      self.bufferListChanged()
    }

    if event == .tabenter {
      self.eventsSubject.onNext(.tabChanged)
    }

    if event == .bufwritepost {
      self.bufferWritten(bufferHandle)
    }

    if event == .bufenter {
      self.newCurrentBuffer(bufferHandle)
    }
  }

  func ipcBecameInvalid(_ reason: String) {
    self.bridgeLogger.debug(reason)

    gui.async {
      if self.bridge.isNvimQuitting || self.bridge.isNvimQuit {
        return
      }

      self.eventsSubject.onNext(.ipcBecameInvalid(reason))
      self.eventsSubject.onCompleted()

      self.bridgeLogger.error("Force-closing due to IPC error.")
      try? self.api
        .stop()
        .andThen(self.bridge.forceQuit())
        .wait()
    }
  }

  private func doPut(string: String) {
    let curPos = self.grid.position
//    self.bridgeLogger.debug("\(curPos) -> '\(string)'")

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

  private func doPut(markedText: String) {
    let curPos = self.grid.position
//    self.bridgeLogger.debug("\(curPos) -> '\(markedText)'")

    self.grid.putMarkedText(markedText)

    self.markForRender(position: curPos)
    // When the cursor is in the command line, then we need this...
    self.markForRender(cellPosition: self.grid.nextCellPosition(curPos))
    if markedText.count == 0 {
      self.markForRender(position: self.grid.previousCellPosition(curPos))
    }
  }

  private func doHighlightSet(_ attrs: CellAttributes) {
//    self.bridgeLogger.debug("\(self.grid.position) -> \(attrs)")
    self.grid.attrs = attrs
  }

  private func doGoto(position: Position, textPosition: Position) {
//    self.bridgeLogger.debug(position)

    self.markForRender(cellPosition: self.grid.position)
    self.grid.goto(position)

    self.eventsSubject.onNext(.cursor(textPosition))
  }

  func doEolClear() {
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

// MARK: - Simple
extension NvimView {

  func bell() {
    self.bridgeLogger.mark()

    NSSound.beep()
  }

  func cwdChanged(_ cwd: String) {
    self.bridgeLogger.debug(cwd)

    self._cwd = URL(fileURLWithPath: cwd)
    self.eventsSubject.onNext(.cwdChanged)
  }
  func colorSchemeChanged(_ values: [Int]) {
    let theme = Theme(values)
    self.bridgeLogger.debug(theme)

    gui.async {
      self.theme = theme
      self.eventsSubject.onNext(.colorschemeChanged(theme))
    }
  }

  func set(dirty: Bool) {
    self.bridgeLogger.debug(dirty)

    self.eventsSubject.onNext(.setDirtyStatus(dirty))
  }

  func updateMenu() {
    self.bridgeLogger.mark()
  }

  func busyStart() {
    self.bridgeLogger.mark()
  }

  func busyStop() {
    self.bridgeLogger.mark()
  }

  func mouseOn() {
    self.bridgeLogger.mark()
  }

  func mouseOff() {
    self.bridgeLogger.mark()
  }

  func visualBell() {
    self.bridgeLogger.mark()
  }

  func suspend() {
    self.bridgeLogger.mark()
  }

  func set(icon: String) {
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
      .flatMap { curBuf -> Single<NvimView.Buffer> in
        self.neoVimBuffer(for: NvimApi.Buffer(handle), currentBuffer: curBuf.apiBuffer)
      }
      .subscribe(onSuccess: {
        self.eventsSubject.onNext(.bufferWritten($0))
        if #available(OSX 10.12.2, *) {
          self.updateTouchBarTab()
        }
      }, onError: { error in
        self.eventsSubject.onNext(.apiError(msg: "Could not get the buffer \(handle).", cause: error))
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
      }, onError: { error in
        self.eventsSubject.onNext(.apiError(msg: "Could not get the current buffer.", cause: error))
      })
  }

  private func bufferListChanged() {
    self.eventsSubject.onNext(.bufferListChanged)
    if #available(OSX 10.12.2, *) {
      self.updateTouchBarCurrentBuffer()
    }
  }
}

private let gui = DispatchQueue.main

private func name(of mode: CursorModeShape) -> String {
  switch mode {
    // @formatter:off
    case .normal:                  return "Normal"
    case .visual:                  return "Visual"
    case .insert:                  return "Insert"
    case .replace:                 return "Replace"
    case .cmdline:                 return "Cmdline"
    case .cmdlineInsert:           return "CmdlineInsert"
    case .cmdlineReplace:          return "CmdlineReplace"
    case .operatorPending:         return "OperatorPending"
    case .visualExclusive:         return "VisualExclusive"
    case .onCmdline:               return "OnCmdline"
    case .onStatusLine:            return "OnStatusLine"
    case .draggingStatusLine:      return "DraggingStatusLine"
    case .onVerticalSepLine:       return "OnVerticalSepLine"
    case .draggingVerticalSepLine: return "DraggingVerticalSepLine"
    case .more:                    return "More"
    case .moreLastLine:            return "MoreLastLine"
    case .showingMatchingParen:    return "ShowingMatchingParen"
    case .termFocus:               return "TermFocus"
    case .count:                   return "Count"
    // @formatter:on
  }
}
