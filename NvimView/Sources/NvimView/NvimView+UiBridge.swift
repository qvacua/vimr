/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Carbon
import Cocoa
import Foundation
import MessagePack
import NvimApi
import os

extension NvimView {
  final func markForRenderWholeView() {
    dlog.debug()
    self.needsDisplay = true
  }

  final func markForRender(region: Region) {
    dlog.debug(region)
    self.setNeedsDisplay(self.rect(for: region))
  }

  final func renderData(_ renderData: [MessagePackValue]) {
    dlog.trace("# of render data: \(renderData.count)")

    Task(priority: .high) {
      var (recompute, rowStart) = (false, Int.max)
      for value in renderData {
        guard let renderEntry = value.arrayValue else { continue }
        guard renderEntry.count >= 2 else { continue }

        guard let rawType = renderEntry[0].stringValue,
              let innerArray = renderEntry[1].arrayValue
        else {
          self.logger.error("Could not convert \(value)")
          continue
        }

        switch rawType {
        case "mode_change":
          self.modeChange(renderEntry[1])

        case "grid_line":
          for index in 1..<renderEntry.count {
            guard let grid_line = renderEntry[index].arrayValue else {
              self.logger.error("Could not convert \(value)")
              continue
            }
            let possibleNewRowStart = self.doRawLineNu(data: grid_line)
            rowStart = min(rowStart, possibleNewRowStart)
          }
          recompute = true

        case "grid_resize":
          self.resize(renderEntry[1])
          rowStart = 0 // Do not persist prior rowStart as it may be OOB
          recompute = true

        case "hl_attr_define":
          for index in 1..<renderEntry.count {
            self.setAttr(with: renderEntry[index])
          }

        case "default_colors_set":
          self.defaultColors(with: renderEntry[1])

        case "grid_clear":
          self.clear()
          recompute = true

        case "win_viewport":
          // FIXME: implement
          self.winViewportUpdate(innerArray)

        case "mouse_on":
          self.mouseOn()

        case "mouse_off":
          self.mouseOff()

        case "busy_start":
          self.busyStart()

        case "busy_stop":
          self.busyStop()

        case "option_set":
          self.optionSet(renderEntry)

        case "set_title":
          await self.setTitle(with: innerArray[0])

        case "update_menu":
          self.updateMenu()

        case "bell":
          self.bell()

        case "visual_bell":
          self.visualBell()

        case "set_icon":
          // FIXME:
          break

        case "grid_cursor_goto":
          guard innerArray[0].uintValue != nil, // grid
                let row = innerArray[1].uintValue,
                let col = innerArray[2].uintValue
          else { continue }

          if let possibleNewRowStart = await self.doGoto(
            position: Position(row: Int(row), column: Int(col)),
            textPosition: Position(row: Int(row), column: Int(col))
          ) {
            rowStart = min(rowStart, possibleNewRowStart)
            recompute = true
          }

        case "mode_info_set":
          self.modeInfoSet(renderEntry[1])

        case "grid_scroll":
          let values = innerArray.compactMap(\.intValue)
          guard values.count == 7 else {
            self.logger.error("Could not convert \(values)")
            continue
          }

          let possibleNewRowStart = await self.doScrollNu(values)
          rowStart = min(possibleNewRowStart, rowStart)
          recompute = true

        case "flush":
          self.flush()

        case "tabline_update":
          self.tablineUpdate(innerArray)

        default:
          self.logger.error("Unknown flush data type \(rawType)")
        }
      }

      guard recompute else { return }
      if rowStart < Int.max {
        self.ugrid.recomputeFlatIndices(rowStart: rowStart)
      }
    }
  }

  final func autoCommandEvent(_ array: [MessagePackValue]) async {
    guard array.count > 0,
          let aucmd = array[0].stringValue?.lowercased(),
          let event = NvimAutoCommandEvent(rawValue: aucmd)
    else {
      self.logger.error("Could not convert \(array)")
      return
    }

    dlog.debug("\(event): \(array)")

    // vimenter is handled in NvimView.swift

    if event == .vimleave {
      await self.stop()
      return
    }

    if event == .dirchanged {
      guard array.count > 1, array[1].stringValue != nil else {
        self.logger.error("Could not convert \(array)")
        return
      }
      await self.cwdChanged(array[1])
      return
    }

    if event == .colorscheme {
      await self.colorSchemeChanged(MessagePackValue(Array(array[1..<array.count])))
      return
    }

    guard array.count > 1, let bufferHandle = array[1].intValue else {
      self.logger.error("Nothing we handle here: \(array)")
      return
    }

    if event == .bufmodifiedset {
      guard array.count > 2 else {
        self.logger.error("Could not convert \(array)")
        return
      }
      await self.setDirty(with: array[2])
    }

    if event == .bufwinenter || event == .bufwinleave {
      await self.bufferListChanged()
    }

    if event == .tabenter {
      await self.delegate?.nextEvent(.tabChanged)
    }

    if event == .bufwritepost {
      await self.bufferWritten(bufferHandle)
    }

    if event == .bufenter {
      await self.newCurrentBuffer(bufferHandle)
    }
  }
}

// MARK: Private

extension NvimView {
  private func resize(_ value: MessagePackValue) {
    guard let array = value.arrayValue else {
      self.logger.error("Could not convert \(value)")
      return
    }
    guard array.count == 3 else {
      self.logger.error("Could not convert; wrong count: \(array)")
      return
    }

    guard array[0].intValue != nil, // grid
          let width = array[1].intValue,
          let height = array[2].intValue
    else {
      self.logger.error("Could not convert; wrong count: \(array)")
      return
    }

    self.ugrid.resize(Size(width: width, height: height))
    self.markForRenderWholeView()
  }

  private func optionSet(_ values: [MessagePackValue]) {
    var options: [MessagePackValue: MessagePackValue] = [:]
    for index in 1..<values.count {
      guard let option_pair = values[index].arrayValue, option_pair.count == 2 else {
        self.logger.error("Could not convert \(values)")
        continue
      }
      options[option_pair[0]] = option_pair[1]
    }

    self.handleRemoteOptions(options)
  }

  private func clear() {
    dlog.debug()

    self.ugrid.clear()
    self.markForRenderWholeView()
  }

  private func modeChange(_ value: MessagePackValue) {
    guard let mainTuple = value.arrayValue,
          mainTuple.count == 2,
          let modeName = mainTuple[0].stringValue,
          mainTuple[1].uintValue != nil // modeIndex
    else {
      self.logger.error("Could not convert \(value)")
      return
    }

    guard let modeShape = CursorModeShape(rawValue: modeName),
          self.modeInfos[modeName] != nil
    else {
      self.logger.error("Could not convert \(value)")
      return
    }

    self.regionsToFlush.append(self.cursorRegion(for: self.ugrid.cursorPosition))

    self.lastMode = self.mode
    self.mode = modeShape
    dlog.debug("\(self.lastMode) -> \(self.mode)")
    self.handleInputMethodSource()
  }

  private func modeInfoSet(_ value: MessagePackValue) {
    // value[0] = cursorStyleEnabled: Bool
    // value[1] = modeInfoList: [ModeInfo]]
    dlog.trace("modeInfoSet: \(value)")
    if let mainTuple = value.arrayValue,
       mainTuple.count == 2,
       let modeInfoArray = mainTuple[1].arrayValue?.map({
         let modeInfo = ModeInfo(withMsgPackDict: $0)
         return (modeInfo.name, modeInfo)
       })
    {
      self.modeInfos = Dictionary(
        uniqueKeysWithValues: modeInfoArray
      )
    }
  }

  private func setTitle(with value: MessagePackValue) async {
    guard let title = value.stringValue else {
      self.logger.error("Could not convert \(value)")
      return
    }

    dlog.debug(title)
    await self.delegate?.nextEvent(.setTitle(title))
  }

  private func ipcBecameInvalid(_ error: Swift.Error) async {
    self.logger.fault("Bridge became invalid: \(error)")

    await self.delegate?.nextEvent(.ipcBecameInvalid(error.localizedDescription))

    self.logger.fault("Force-closing due to IPC error.")
    await self.api.stop()
    self.nvimProc.forceQuit()
    self.logger.fault("Successfully force-closed the bridge.")
  }

  private func flush() {
    for region in self.regionsToFlush {
      self.markForRender(region: region)
    }
    self.regionsToFlush.removeAll(keepingCapacity: true)
  }

  private func doRawLineNu(data: [MessagePackValue]) -> Int {
    guard data.count == 5 else {
      self.logger.error("Could not convert; wrong count: \(data)")
      return Int.max
    }

    guard data[0].intValue != nil, // grid
          let row = data[1].intValue,
          let startCol = data[2].intValue,
          let chunk = data[3].arrayValue?.compactMap({ arg -> UUpdate? in
            guard let argArray = arg.arrayValue else { return nil }
            var uupdate = UUpdate(string: "", attrId: nil, repeats: nil)

            if argArray.count > 0, let str = argArray[0].stringValue {
              uupdate.string = str
              uupdate.utf16chars = Array(str.utf16)
            }
            if argArray.count > 1 { uupdate.attrId = argArray[1].intValue }
            if argArray.count > 2 { uupdate.repeats = argArray[2].intValue }

            return uupdate
          }),
          // wrap is informational, not required for correct functionality
          data[4].boolValue != nil // wrap
    else {
      self.logger.error("Could not convert \(data)")
      return Int.max
    }

    let endCol = self.ugrid.updateNu(row: row, startCol: startCol, chunk: chunk)
    dlog.trace("row: \(row), startCol: \(startCol), endCol: \(endCol), chunk: \(chunk)")

    if chunk.count > 0 {
      if row == self.ugrid.markedInfo?.position.row {
        self.regionsToFlush.append(Region(
          top: row, bottom: row,
          left: startCol, right: self.ugrid.size.width
        ))
      } else if self.usesLigatures {
        let leftBoundary = self.ugrid.leftBoundaryOfWord(
          at: Position(row: row, column: startCol)
        )
        let rightBoundary = self.ugrid.rightBoundaryOfWord(
          at: Position(row: row, column: max(0, endCol - 1))
        )
        self.regionsToFlush.append(Region(
          top: row, bottom: row, left: leftBoundary, right: rightBoundary
        ))
      } else {
        self.regionsToFlush.append(Region(
          top: row, bottom: row, left: startCol, right: max(0, endCol - 1)
        ))
      }
    }

    return row
  }

  private func doGoto(position: Position, textPosition: Position) async -> Int? {
    dlog.debug(position)

    var rowStart: Int?
    if var markedInfo = self.ugrid.popMarkedInfo() {
      rowStart = min(markedInfo.position.row, position.row)
      self.markForRender(
        region: self.regionForRow(at: self.ugrid.cursorPosition)
      )
      self.ugrid.goto(position)
      markedInfo.position = position
      self.ugrid.updateMarkedInfo(newValue: markedInfo)
      self.markForRender(
        region: self.regionForRow(at: self.ugrid.cursorPosition)
      )
    } else {
      // Re-render the old cursor position.
      self.markForRender(
        region: self.cursorRegion(for: self.ugrid.cursorPosition)
      )

      self.ugrid.goto(position)
      self.markForRender(
        region: self.cursorRegion(for: self.ugrid.cursorPosition)
      )
    }

    await self.delegate?.nextEvent(.cursor(textPosition))
    return rowStart
  }

  private func doScrollNu(_ array: [Int]) async -> Int {
    dlog.trace("[grid, top, bot, left, right, rows, cols] = \(array)")

    let (_ /* grid */, top, bottom, left, right, rows, cols)
      = (array[0], array[1], array[2] - 1, array[3], array[4] - 1, array[5], array[6])

    let scrollRegion = Region(
      top: top, bottom: bottom,
      left: left, right: right
    )

    self.ugrid.scroll(region: scrollRegion, rows: rows, cols: cols)
    self.regionsToFlush.append(scrollRegion)
    await self.delegate?.nextEvent(.scroll)

    return min(0, top)
  }

  private func handleInputMethodSource() {
    // Exit from Insert mode, save ime used in Insert mode.
    if case self.lastMode = CursorModeShape.insert, case self.mode = CursorModeShape.normal {
      self.lastImSource = TISCopyCurrentKeyboardInputSource().takeRetainedValue()
      dlog.debug("lastImSource id: \(lastImSource.id), source: \(lastImSource)")

      if self.activateAsciiImInNormalMode { TISSelectInputSource(self.asciiImSource) }
      return
    }

    // Enter into Insert mode, set ime to last used ime in Insert mode.
    // Visual -> Insert
    // Normal -> Insert
    // avoid insert -> insert
    if case self.mode = CursorModeShape.insert,
       self.lastMode != self.mode,
       self.activateAsciiImInNormalMode
    { TISSelectInputSource(self.lastImSource) }
  }

  private func bell() {
    dlog.debug()
    NSSound.beep()
  }

  private func cwdChanged(_ value: MessagePackValue) async {
    guard let cwd = value.stringValue else {
      self.logger.error("Could not convert \(value)")
      return
    }

    dlog.debug(cwd)
    self._cwd = URL(fileURLWithPath: cwd)
    Task { self.tabBar?.cwd = cwd }
    await self.delegate?.nextEvent(.cwdChanged)
  }

  private func colorSchemeChanged(_ value: MessagePackValue) async {
    dlog.debug("color scheme changed before: \(value)")

    guard let values = MessagePackUtils.array(
      from: value, ofSize: 11, conversion: { $0.intValue }
    ) else {
      self.logger.error("Could not convert theme from \(value)")
      return
    }

    dlog.debug("color scheme changed: \(values)")

    let theme = Theme(values)
    dlog.debug(theme)

    self.theme = theme
    await self.delegate?.nextEvent(.colorschemeChanged(theme))
  }

  private func setDirty(with value: MessagePackValue) async {
    guard let dirty = value.intValue else {
      self.logger.error("Could not convert \(value)")
      return
    }

    dlog.debug(dirty)
    await self.delegate?.nextEvent(.setDirtyStatus(dirty == 1))
  }

  private func setAttr(with value: MessagePackValue) {
    guard let array = value.arrayValue else {
      self.logger.error("Could not convert \(value)")
      return
    }
    guard array.count == 4 else {
      self.logger.error("Could not convert; wrong count \(value)")
      return
    }

    guard let id = array[0].intValue,
          let rgb_dict = array[1].dictionaryValue,
          array[2].dictionaryValue != nil, // cterm_dict
          array[3].arrayValue != nil // info
    else {
      self.logger.error("Could not get highlight attributes from \(value)")
      return
    }

    let mapped_rgb_dict = rgb_dict.map {
      (key: MessagePackValue, value: MessagePackValue) in
      (key.stringValue!, value)
    }
    let rgb_attr = [String: MessagePackValue](
      uniqueKeysWithValues: mapped_rgb_dict
    )
    let attrs = CellAttributes(
      withDict: rgb_attr,
      with: CellAttributes(
        fontTrait: FontTrait(),
        foreground: -1,
        background: -1,
        special: -1,
        reverse: false
      )
      // self.cellAttributesCollection.defaultAttributes
    )

    dlog.debug("AttrId: \(id): \(attrs)")

    // FIXME: seems to not work well unless not async
    self.cellAttributesCollection.set(attributes: attrs, for: id)
  }

  private func defaultColors(with value: MessagePackValue) {
    guard let array = value.arrayValue else {
      self.logger.error("Could not convert \(value)")
      return
    }
    guard array.count == 5 else {
      self.logger.error("Could not convert; wrong count \(value)")
      return
    }

    guard let rgb_fg = array[0].intValue,
          let rgb_bg = array[1].intValue,
          let rgb_sp = array[2].intValue,
          array[3].intValue != nil, // cterm_fg
          array[4].intValue != nil // cterm_bg
    else {
      self.logger.error("Could not get default colors from \(value)")
      return
    }

    let attrs = CellAttributes(
      fontTrait: FontTrait(), foreground: rgb_fg, background: rgb_bg, special: rgb_sp,
      reverse: false
    )

    self.cellAttributesCollection.set(
      attributes: attrs,
      for: CellAttributesCollection.defaultAttributesId
    )
    self.updateLayerBackgroundColor()
  }

  private func updateMenu() {
    dlog.debug()
  }

  private func busyStart() {
    dlog.debug()
  }

  private func busyStop() {
    dlog.debug()
  }

  private func mouseOn() {
    dlog.debug()
  }

  private func mouseOff() {
    dlog.debug()
  }

  private func visualBell() {
    dlog.debug()
  }

  private func suspend() {
    dlog.debug()
  }

  private func tablineUpdate(_ args: [MessagePackValue]) {
    guard args.count >= 2,
          let curTab = NvimApi.Tabpage(args[0]),
          let tabsValue = args[1].arrayValue else { return }

    self.tabEntries = tabsValue.compactMap { dictValue in
      guard let dict = dictValue.dictionaryValue,
            let name = dict[.string("name")]?.stringValue,
            let tabpageValue = dict[.string("tab")],
            let tabpage = NvimApi.Tabpage(tabpageValue) else { return nil }

      return TabEntry(title: name, isSelected: tabpage == curTab, tabpage: tabpage)
    }

    self.tabBar?.update(tabRepresentatives: self.tabEntries)
  }

  private func winViewportUpdate(_: [MessagePackValue]) {
    // FIXME:
    /*
      guard let array = value.arrayValue,
              array.count == 8
      else {
        self.bridgeLogger.error("Could not convert \(value)")
        return
      }
      guard let grid = array[0].intValue,
            let top = array[2].intValue,
            let bot = array[3].intValue,
            let curline = array[4].intValue,
            let curcol = array[5].intValue,
            let linecount = array[6].intValue,
            let scroll_delta = array[6].intValue
      else {
        self.bridgeLogger.error("Could not convert \(value)")
        return
      }
      // [top, bot, left, right, rows, cols]
      // FIXMEL self.doScroll([])
     */
  }

  private func bufferWritten(_ handle: Int) async {
    let curBuf = await self.currentBuffer()
    guard let buf = await self.neoVimBuffer(for: .init(handle), currentBuffer: curBuf?.apiBuffer)
    else { return }
    await self.delegate?.nextEvent(.bufferWritten(buf))
    await self.updateTouchBarTab()
  }

  private func newCurrentBuffer(_ handle: Int) async {
    guard let curBuf = await self.currentBuffer(),
          curBuf.apiBuffer.handle == handle else { return }

    await self.updateTouchBarTab()
    await self.delegate?.nextEvent(.newCurrentBuffer(curBuf))
  }

  private func bufferListChanged() async {
    await self.delegate?.nextEvent(.bufferListChanged)
    await self.updateTouchBarCurrentBuffer()
  }

  func focusGained(_ gained: Bool) async {
    await self.api.nvimUiSetFocus(gained: gained).cauterize()
  }
}

extension TISInputSource {
  enum Category {
    static var keyboardInputSource: String { kTISCategoryKeyboardInputSource as String }
  }

  private func getProperty(_ key: CFString) -> AnyObject? {
    let cfType = TISGetInputSourceProperty(self, key)
    if cfType != nil {
      return Unmanaged<AnyObject>.fromOpaque(cfType!).takeUnretainedValue()
    } else {
      return nil
    }
  }

  // swiftlint:disable force_cast
  var id: String { self.getProperty(kTISPropertyInputSourceID) as! String }
  var name: String { self.getProperty(kTISPropertyLocalizedName) as! String }
  var category: String { self.getProperty(kTISPropertyInputSourceCategory) as! String }
  var isSelectable: Bool { self.getProperty(kTISPropertyInputSourceIsSelectCapable) as! Bool }
  var sourceLanguages: [String] { self.getProperty(kTISPropertyInputSourceLanguages) as! [String] }
  // swiftlint:enable force_cast
}

private let gui = DispatchQueue.main
