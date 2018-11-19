/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import RxNeovimApi
import RxSwift
import MessagePack

extension NvimView {

  final func resize(_ value: MessagePackValue) {
    guard let array = MessagePackUtils.array(
      from: value, ofSize: 2, conversion: { $0.intValue }
    ) else {
      return
    }

    self.bridgeLogger.debug("\(array[0]) x \(array[1])")
    gui.async {
      self.ugrid.resize(Size(width: array[0], height: array[1]))
      self.markForRenderWholeView()
    }
  }

  final func clear() {
    self.bridgeLogger.mark()

    gui.async {
      self.ugrid.clear()
      self.markForRenderWholeView()
    }
  }

  final func modeChange(_ value: MessagePackValue) {
    guard let mode = MessagePackUtils.value(
      from: value, conversion: { v -> CursorModeShape? in

      guard let rawValue = v.intValue else { return nil }
      return CursorModeShape(rawValue: UInt(rawValue))

    }) else {
      return
    }

    self.bridgeLogger.debug(self.name(ofCursorMode: mode))
    gui.async {
      self.mode = mode
      self.markForRender(
        region: self.cursorRegion(for: self.ugrid.cursorPosition)
      )
    }
  }

  final func flush(_ renderData: [MessagePackValue]) {
    self.bridgeLogger.debug("# of render data: \(renderData.count)")

    gui.async {
      var (recompute, rowStart) = (false, Int.max)
      renderData.forEach { value in
        guard let renderEntry = value.arrayValue else { return }
        guard renderEntry.count == 2 else { return }

        guard let rawType = renderEntry[0].intValue,
              let innerArray = renderEntry[1].arrayValue,
              let type = RenderDataType(rawValue: rawType) else { return }

        switch type {

        case .rawLine:
          let (r, s) = self.doRawLine(data: innerArray)
          recompute = recompute ? true : r
          rowStart = r ? min(rowStart, s) : rowStart

        case .goto:
          guard let row = innerArray[0].unsignedIntegerValue,
                let col = innerArray[1].unsignedIntegerValue else { return }

          self.doGoto(position: Position(row: Int(row), column: Int(col)))

        case .scroll:
          let values = innerArray.compactMap { $0.intValue }
          guard values.count == 6 else {
            self.bridgeLogger.error("Scroll msg does not have 6 Int's!")
            return
          }

          recompute = true
          rowStart = min(self.doScroll(values), rowStart)

        }
      }

      if recompute {
        self.ugrid.recomputeFlatIndices(
          rowStart: rowStart,
          rowEndInclusive: self.ugrid.size.height - 1
        )
      }

      // The position stays at the first cell when we enter the terminal mode
      // and the cursor seems to be drawn by changing the background color of
      // the corresponding cell...
      if self.mode != .termFocus {
        self.shouldDrawCursor = true
      }
    }
  }

  final func setTitle(with value: MessagePackValue) {
    guard let title = value.stringValue else { return }

    self.bridgeLogger.debug(title)
    self.eventsSubject.onNext(.setTitle(title))
  }

  final func stop() {
    self.bridgeLogger.hr()
    try? self.api
      .stop()
      .andThen(self.bridge.quit())
      .andThen(Completable.create { completable in
        self.eventsSubject.onNext(.neoVimStopped)
        self.eventsSubject.onCompleted()

        completable(.completed)
        return Disposables.create()
      })
      .observeOn(MainScheduler.instance)
      .wait()
  }

  final func autoCommandEvent(_ value: MessagePackValue) {
    guard let array = MessagePackUtils.array(
      from: value, ofSize: 2, conversion: { $0.intValue }
    ),
          let event = NvimAutoCommandEvent(rawValue: array[0])
      else {
      return
    }
    let bufferHandle = array[1]

    #if TRACE
    self.bridgeLogger.trace("\(event) -> \(bufferHandle)")
    #endif

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

  final func ipcBecameInvalid(_ reason: String) {
    self.bridgeLogger.debug(reason)

    self.eventsSubject.onNext(.ipcBecameInvalid(reason))
    self.eventsSubject.onCompleted()

    self.bridgeLogger.error("Force-closing due to IPC error.")
    try? self.api
      .stop()
      .andThen(self.bridge.forceQuit())
      .observeOn(MainScheduler.instance)
      .wait()
  }

  private func doRawLine(data: [MessagePackValue]) -> (Bool, Int) {
    guard data.count == 7 else {
      stdoutLogger.error(
        "Data has wrong number of elements: \(data.count) instead of 7"
      )
      return (false, Int.max)
    }

    guard let row = data[0].intValue,
          let startCol = data[1].intValue,
          let endCol = data[2].intValue, // past last index, but can be 0
          let clearCol = data[3].intValue, // past last index (can be 0?)
          let clearAttr = data[4].intValue,
          let chunk = data[5].arrayValue?.compactMap({ $0.stringValue }),
          let attrIds = data[6].arrayValue?.compactMap({ $0.intValue })
      else {

      stdoutLogger.error("Values could not be read from: \(data)")
      return (false, Int.max)
    }

    #if TRACE
    self.bridgeLogger.trace(
      "row: \(row), startCol: \(startCol), endCol: \(endCol), " +
        "clearCol: \(clearCol), clearAttr: \(clearAttr), " +
        "chunk: \(chunk), attrIds: \(attrIds)"
    )
    #endif

    let count = endCol - startCol
    guard chunk.count == count && attrIds.count == count else {
      return (false, Int.max)
    }
    self.ugrid.update(row: row,
                      startCol: startCol,
                      endCol: endCol,
                      clearCol: clearCol,
                      clearAttr: clearAttr,
                      chunk: chunk,
                      attrIds: attrIds)

    if count > 0 {
      if self.usesLigatures {
        let leftBoundary = self.ugrid.leftBoundaryOfWord(
          at: Position(row: row, column: startCol)
        )
        let rightBoundary = self.ugrid.rightBoundaryOfWord(
          at: Position(row: row, column: max(0, endCol - 1))
        )
        self.markForRender(region: Region(
          top: row, bottom: row, left: leftBoundary, right: rightBoundary
        ))
      } else {
        self.markForRender(region: Region(
          top: row, bottom: row, left: startCol, right: max(0, endCol - 1)
        ))
      }
    }

    if clearCol > endCol {
      self.markForRender(region: Region(
        top: row, bottom: row, left: endCol, right: max(endCol, clearCol - 1)
      ))
    }

    if row == self.markedPosition.row
         && startCol <= self.markedPosition.column
         && self.markedPosition.column <= endCol {
      self.ugrid.markCell(at: self.markedPosition)
    }

    let oldRowContainsWideChar = self.ugrid.cells[row][startCol..<endCol]
      .first(where: { $0.string.isEmpty }) != nil
    let newRowContainsWideChar = chunk.first(where: { $0.isEmpty }) != nil

    if !oldRowContainsWideChar && !newRowContainsWideChar {
      return (false, row)
    }

    return (newRowContainsWideChar, row)
  }

  private func doGoto(position: Position) {
    self.bridgeLogger.debug(position)

    // Re-render the old cursor position.
    self.markForRender(
      region: self.cursorRegion(for: self.ugrid.cursorPosition)
    )

    self.ugrid.goto(position)
    self.markForRender(
      region: self.cursorRegion(for: self.ugrid.cursorPosition)
    )
  }

  private func doScroll(_ array: [Int]) -> Int {
    self.bridgeLogger.debug("[top, bot, left, right, rows, cols] = \(array)")

    let (top, bottom, left, right, rows, cols)
      = (array[0], array[1] - 1, array[2], array[3] - 1, array[4], array[5])

    let scrollRegion = Region(
      top: top, bottom: bottom,
      left: left, right: right
    )
//    let maxBottom = self.ugrid.size.height - 1
//    let regionToRender = Region(
//      top: min(max(0, top - rows), maxBottom),
//      bottom: max(0, min(bottom - rows, maxBottom)),
//      left: left, right: right
//    )

    self.ugrid.scroll(region: scrollRegion, rows: rows, cols: cols)
    self.markForRender(region: scrollRegion)
    self.eventsSubject.onNext(.scroll)

    return min(0, top)
  }
}

// MARK: - Simple
extension NvimView {

  final func bell() {
    self.bridgeLogger.mark()

    NSSound.beep()
  }

  final func cwdChanged(_ value: MessagePackValue) {
    guard let cwd = value.stringValue else { return }

    self.bridgeLogger.debug(cwd)
    self._cwd = URL(fileURLWithPath: cwd)
    self.eventsSubject.onNext(.cwdChanged)
  }

  final func colorSchemeChanged(_ value: MessagePackValue) {
    guard let values = MessagePackUtils.array(
      from: value, ofSize: 5, conversion: { $0.intValue }
    ) else {
      return
    }

    let theme = Theme(values)
    self.bridgeLogger.debug(theme)

    gui.async {
      self.theme = theme
      self.eventsSubject.onNext(.colorschemeChanged(theme))
    }
  }

  final func defaultColorsChanged(_ value: MessagePackValue) {
    guard let values = MessagePackUtils.array(
      from: value, ofSize: 3, conversion: { $0.intValue }
    ) else {
      return
    }

    self.bridgeLogger.trace(values)

    let attrs = CellAttributes(
      fontTrait: [],
      foreground: values[0],
      background: values[1],
      special: values[2],
      reverse: false
    )
    gui.async {
      self.cellAttributesCollection.set(
        attributes: attrs,
        for: CellAttributesCollection.defaultAttributesId
      )
      self.layer?.backgroundColor = ColorUtils.cgColorIgnoringAlpha(
        attrs.background
      )
    }
  }

  final func setDirty(with value: MessagePackValue) {
    guard let dirty = value.boolValue else { return }

    self.bridgeLogger.debug(dirty)
    self.eventsSubject.onNext(.setDirtyStatus(dirty))
  }

  final func setAttr(with value: MessagePackValue) {
    guard let array = value.arrayValue else { return }
    guard array.count == 6 else { return }

    guard let id = array[0].intValue,
          let rawTrait = array[1].unsignedIntegerValue,
          let fg = array[2].intValue,
          let bg = array[3].intValue,
          let sp = array[4].intValue,
          let reverse = array[5].boolValue
      else {

      self.bridgeLogger.error("Could not get highlight attributes from " +
                                "\(value)")
      return
    }
    let trait = FontTrait(rawValue: UInt(rawTrait))

    let attrs = CellAttributes(
      fontTrait: trait,
      foreground: fg,
      background: bg,
      special: sp,
      reverse: reverse
    )

    self.bridgeLogger.trace("\(id) -> \(attrs)")

    gui.async {
      self.cellAttributesCollection.set(attributes: attrs, for: id)
    }
  }

  final func updateMenu() {
    self.bridgeLogger.mark()
  }

  final func busyStart() {
    self.bridgeLogger.mark()
  }

  final func busyStop() {
    self.bridgeLogger.mark()
  }

  final func mouseOn() {
    self.bridgeLogger.mark()
  }

  final func mouseOff() {
    self.bridgeLogger.mark()
  }

  final func visualBell() {
    self.bridgeLogger.mark()
  }

  final func suspend() {
    self.bridgeLogger.mark()
  }
}

extension NvimView {

  final func markForRenderWholeView() {
    self.needsDisplay = true
  }

  final func markForRender(region: Region) {
    self.setNeedsDisplay(self.rect(for: region))
  }

  final func markForRender(row: Int, column: Int) {
    self.setNeedsDisplay(self.rect(forRow: row, column: column))
  }

  final func markForRender(position: Position) {
    self.setNeedsDisplay(
      self.rect(forRow: position.row, column: position.column)
    )
  }
}

extension NvimView {

  private func bufferWritten(_ handle: Int) {
    self
      .currentBuffer()
      .flatMap { curBuf -> Single<NvimView.Buffer> in
        self.neoVimBuffer(
          for: Api.Buffer(handle), currentBuffer: curBuf.apiBuffer
        )
      }
      .value(onSuccess: {
        self.eventsSubject.onNext(.bufferWritten($0))
        if #available(OSX 10.12.2, *) {
          self.updateTouchBarTab()
        }
      }, onError: { error in
        self.eventsSubject.onNext(
          .apiError(msg: "Could not get the buffer \(handle).", cause: error)
        )
      })
  }

  private func newCurrentBuffer(_ handle: Int) {
    self
      .currentBuffer()
      .filter { $0.apiBuffer.handle == handle }
      .value(onSuccess: {
        self.eventsSubject.onNext(.newCurrentBuffer($0))
        if #available(OSX 10.12.2, *) {
          self.updateTouchBarTab()
        }
      }, onError: { error in
        self.eventsSubject.onNext(
          .apiError(msg: "Could not get the current buffer.", cause: error)
        )
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
