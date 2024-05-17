/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Carbon
import Cocoa
import Foundation
import MessagePack
import os
import RxNeovim
import RxPack
import RxSwift

extension NvimView {
  final func markForRenderWholeView() {
    self.bridgeLogger.debug()
    self.needsDisplay = true
  }

  final func markForRender(region: Region) {
    self.bridgeLogger.debug(region)
    self.setNeedsDisplay(self.rect(for: region))
  }

  final func stop() {
    self.bridgeLogger.debug()
    self.quit()
      .andThen(self.api.stop())
      .andThen(Completable.create { [weak self] completable in
        self?.eventsSubject.onNext(.neoVimStopped)
        self?.eventsSubject.onCompleted()

        completable(.completed)
        return Disposables.create()
      })
      .subscribe(onCompleted: { [weak self] in
        self?.bridgeLogger.info("Successfully stopped the bridge.")
        self?.nvimExitedCondition.broadcast()
      }, onError: {
        self.bridgeLogger.fault("There was an error stopping the bridge: \($0)")
      })
      .disposed(by: self.disposeBag)
  }

  final func renderData(_ renderData: [MessagePackValue]) {
    self.bridgeLogger.trace("# of render data: \(renderData.count)")

    gui.async { [self] in
      var (recompute, rowStart) = (false, Int.max)
      renderData.forEach { value in
        guard let renderEntry = value.arrayValue else { return }
        guard renderEntry.count >= 2 else { return }

        guard let rawType = renderEntry[0].stringValue,
              let innerArray = renderEntry[1].arrayValue
        else {
          self.bridgeLogger.error("Could not convert \(value)")
          return
        }

        switch rawType {
        case "mode_change":
          self.modeChange(renderEntry[1])

        case "grid_line":
          for index in 1..<renderEntry.count {
            guard let grid_line = renderEntry[index].arrayValue else {
              self.bridgeLogger.error("Could not convert \(value)")
              return
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
          self.setTitle(with: innerArray[0])

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
          guard let _ /* grid */ = innerArray[0].uintValue,
                let row = innerArray[1].uintValue,
                let col = innerArray[2].uintValue
          else { return }

          if let possibleNewRowStart = self.doGoto(
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
            self.bridgeLogger.error("Could not convert \(values)")
            return
          }

          let possibleNewRowStart = self.doScrollNu(values)
          rowStart = min(possibleNewRowStart, rowStart)
          recompute = true

        case "flush":
          self.flush()

        case "tabline_update":
          self.tablineUpdate(innerArray)

        default:
          self.log.error("Unknown flush data type \(rawType)")
        }
      }

      guard recompute else { return }
      if rowStart < Int.max {
        self.ugrid.recomputeFlatIndices(rowStart: rowStart)
      }
    }
  }

  final func autoCommandEvent(_ array: [MessagePackValue]) {
    guard array.count > 0,
          let aucmd = array[0].stringValue?.lowercased(),
          let event = NvimAutoCommandEvent(rawValue: aucmd)
    else {
      self.bridgeLogger.error("Could not convert \(array)")
      return
    }

    self.bridgeLogger.debug("\(event): \(array)")

    // vimenter is handled in NvimView.swift

    if event == .vimleave {
      self.stop()
      return
    }

    if event == .dirchanged {
      guard array.count > 1, array[1].stringValue != nil else {
        self.bridgeLogger.error("Could not convert \(array)")
        return
      }
      self.cwdChanged(array[1])
      return
    }

    if event == .colorscheme {
      self.colorSchemeChanged(MessagePackValue(Array(array[1..<array.count])))
      return
    }

    guard array.count > 1, let bufferHandle = array[1].intValue else {
      self.bridgeLogger.error("Could not convert \(array)")
      return
    }

    if event == .bufmodifiedset {
      guard array.count > 2 else {
        self.bridgeLogger.error("Could not convert \(array)")
        return
      }
      self.setDirty(with: array[2])
    }

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
}

// MARK: Private

extension NvimView {
  private func optionSet(_ value: MessagePackValue) {
    guard let options = value.dictionaryValue else {
      self.bridgeLogger.error("Could not convert \(value)")
      return
    }

    self.handleRemoteOptions(options)
  }

  private func resize(_ value: MessagePackValue) {
    guard let array = value.arrayValue else {
      self.bridgeLogger.error("Could not convert \(value)")
      return
    }
    guard array.count == 3 else {
      self.bridgeLogger.error("Could not convert; wrong count: \(array)")
      return
    }

    guard let _ /* grid */ = array[0].intValue,
          let width = array[1].intValue,
          let height = array[2].intValue
    else {
      self.bridgeLogger.error("Could not convert; wrong count: \(array)")
      return
    }

    self.ugrid.resize(Size(width: width, height: height))
    self.markForRenderWholeView()
  }

  private func optionSet(_ values: [MessagePackValue]) {
    var options: [MessagePackValue: MessagePackValue] = [:]
    for index in 1..<values.count {
      guard let option_pair = values[index].arrayValue, option_pair.count == 2 else {
        self.bridgeLogger.error("Could not convert \(values)")
        continue
      }
      options[option_pair[0]] = option_pair[1]
    }

    self.handleRemoteOptions(options)
  }

  private func clear() {
    self.bridgeLogger.debug()

    self.ugrid.clear()
    self.markForRenderWholeView()
  }

  private func modeChange(_ value: MessagePackValue) {
    guard let mainTuple = value.arrayValue,
          mainTuple.count == 2,
          let modeName = mainTuple[0].stringValue,
          let _ /* modeIndex */ = mainTuple[1].uintValue
    else {
      self.bridgeLogger.error("Could not convert \(value)")
      return
    }

    guard let modeShape = CursorModeShape(rawValue: modeName),
          self.modeInfos[modeName] != nil
    else {
      self.bridgeLogger.error("Could not convert \(value)")
      return
    }

    self.regionsToFlush.append(self.cursorRegion(for: self.ugrid.cursorPosition))

    self.lastMode = self.mode
    self.mode = modeShape
    self.bridgeLogger.debug("\(self.lastMode) -> \(self.mode)")
    self.handleInputMethodSource()
  }

  private func modeInfoSet(_ value: MessagePackValue) {
    // value[0] = cursorStyleEnabled: Bool
    // value[1] = modeInfoList: [ModeInfo]]
    self.bridgeLogger.trace("modeInfoSet: \(value)")
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

  private func setTitle(with value: MessagePackValue) {
    guard let title = value.stringValue else {
      self.bridgeLogger.error("Could not convert \(value)")
      return
    }

    self.bridgeLogger.debug(title)
    self.eventsSubject.onNext(.setTitle(title))
  }

  private func ipcBecameInvalid(_ error: Swift.Error) {
    self.bridgeLogger.fault("Bridge became invalid: \(error)")

    self.eventsSubject.onNext(.ipcBecameInvalid(error.localizedDescription))
    self.eventsSubject.onCompleted()

    self.bridgeLogger.fault("Force-closing due to IPC error.")
    try? self.api
      .stop()
      .andThen(self.bridge.forceQuit())
      .observe(on: MainScheduler.instance)
      .wait(onCompleted: { [weak self] in
        self?.bridgeLogger.fault("Successfully force-closed the bridge.")
      }, onError: { [weak self] in
        self?.bridgeLogger.fault("There was an error force-closing the bridge: \($0)")
      })
  }

  private func flush() {
    for region in self.regionsToFlush { self.markForRender(region: region) }
    self.regionsToFlush.removeAll(keepingCapacity: true)
  }

  private func doRawLineNu(data: [MessagePackValue]) -> Int {
    guard data.count == 5 else {
      self.bridgeLogger.error("Could not convert; wrong count: \(data)")
      return Int.max
    }

    guard let _ /* grid */ = data[0].intValue,
          let row = data[1].intValue,
          let startCol = data[2].intValue,
          let chunk = data[3].arrayValue?.compactMap({ arg -> UUpdate? in
            guard let argArray = arg.arrayValue else { return nil }
            var uupdate = UUpdate(string: "", attrId: nil, repeats: nil)

            if argArray.count > 0, let str = arg[0]?.stringValue { uupdate.string = str }
            if argArray.count > 1, let attrId = arg[1]?.intValue { uupdate.attrId = attrId }
            if argArray.count > 2, let repeats = arg[2]?.intValue { uupdate.repeats = repeats }

            return uupdate
          }),
          // wrap is informational, not required for correct functionality
          let _ /* wrap */ = data[4].boolValue
    else {
      self.bridgeLogger.error("Could not convert \(data)")
      return Int.max
    }

    #if TRACE
      self.bridgeLogger.debug(
        "row: \(row), startCol: \(startCol), endCol: \(endCol), " +
          "chunk: \(chunk)"
      )
    #endif

    let endCol = self.ugrid.updateNu(row: row, startCol: startCol, chunk: chunk)
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

  private func doGoto(position: Position, textPosition: Position) -> Int? {
    self.bridgeLogger.debug(position)

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

    self.eventsSubject.onNext(.cursor(textPosition))
    return rowStart
  }

  private func doScrollNu(_ array: [Int]) -> Int {
    self.bridgeLogger.trace("[grid, top, bot, left, right, rows, cols] = \(array)")

    let (_ /* grid */, top, bottom, left, right, rows, cols)
      = (array[0], array[1], array[2] - 1, array[3], array[4] - 1, array[5], array[6])

    let scrollRegion = Region(
      top: top, bottom: bottom,
      left: left, right: right
    )

    self.ugrid.scroll(region: scrollRegion, rows: rows, cols: cols)
    self.regionsToFlush.append(scrollRegion)
    self.eventsSubject.onNext(.scroll)

    return min(0, top)
  }

  private func handleInputMethodSource() {
    // Exit from Insert mode, save ime used in Insert mode.
    if case self.lastMode = CursorModeShape.insert, case self.mode = CursorModeShape.normal {
      self.lastImSource = TISCopyCurrentKeyboardInputSource().takeRetainedValue()
      self.bridgeLogger.debug("lastImSource id: \(lastImSource.id), source: \(lastImSource)")

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
    self.bridgeLogger.debug()
    NSSound.beep()
  }

  private func cwdChanged(_ value: MessagePackValue) {
    guard let cwd = value.stringValue else {
      self.bridgeLogger.error("Could not convert \(value)")
      return
    }

    self.bridgeLogger.debug(cwd)
    self._cwd = URL(fileURLWithPath: cwd)
    self.eventsSubject.onNext(.cwdChanged)
  }

  private func colorSchemeChanged(_ value: MessagePackValue) {
    guard let values = MessagePackUtils.array(
      from: value, ofSize: 7, conversion: { $0.intValue }
    ) else {
      self.bridgeLogger.error("Could not convert \(value)")
      return
    }

    let theme = Theme(values)
    self.bridgeLogger.debug(theme)

    self.theme = theme
    self.eventsSubject.onNext(.colorschemeChanged(theme))
  }

  private func setDirty(with value: MessagePackValue) {
    guard let dirty = value.intValue else {
      self.bridgeLogger.error("Could not convert \(value)")
      return
    }

    self.bridgeLogger.debug(dirty)
    self.eventsSubject.onNext(.setDirtyStatus(dirty == 1))
  }

  private func setAttr(with value: MessagePackValue) {
    guard let array = value.arrayValue else {
      self.bridgeLogger.error("Could not convert \(value)")
      return
    }
    guard array.count == 4 else {
      self.bridgeLogger.error("Could not convert; wrong count \(value)")
      return
    }

    guard let id = array[0].intValue,
          let rgb_dict = array[1].dictionaryValue,
          let _ /* cterm_dict */ = array[2].dictionaryValue,
          let _ /* info */ = array[3].arrayValue
    else {
      self.bridgeLogger.error(
        "Could not get highlight attributes from " +
          "\(value)"
      )
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

    self.bridgeLogger.debug("AttrId: \(id): \(attrs)")

    // FIXME: seems to not work well unless not async
    self.cellAttributesCollection.set(attributes: attrs, for: id)
  }

  private func defaultColors(with value: MessagePackValue) {
    guard let array = value.arrayValue else {
      self.bridgeLogger.error("Could not convert \(value)")
      return
    }
    guard array.count == 5 else {
      self.bridgeLogger.error("Could not convert; wrong count \(value)")
      return
    }

    guard let rgb_fg = array[0].intValue,
          let rgb_bg = array[1].intValue,
          let rgb_sp = array[2].intValue,
          let _ /* cterm_fg */ = array[3].intValue,
          let _ /* cterm_bg */ = array[4].intValue
    else {
      self.bridgeLogger.error(
        "Could not get default colors from " +
          "\(value)"
      )
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
    self.layer?.backgroundColor = ColorUtils.cgColorIgnoringAlpha(
      attrs.background
    )
  }

  private func updateMenu() {
    self.bridgeLogger.debug()
  }

  private func busyStart() {
    self.bridgeLogger.debug()
  }

  private func busyStop() {
    self.bridgeLogger.debug()
  }

  private func mouseOn() {
    self.bridgeLogger.debug()
  }

  private func mouseOff() {
    self.bridgeLogger.debug()
  }

  private func visualBell() {
    self.bridgeLogger.debug()
  }

  private func suspend() {
    self.bridgeLogger.debug()
  }

  private func tablineUpdate(_ args: [MessagePackValue]) {
    guard args.count >= 2,
          let curTab = RxNeovimApi.Tabpage(args[0]),
          let tabsValue = args[1].arrayValue else { return }

    self.tabEntries = tabsValue.compactMap { dictValue in
      guard let dict = dictValue.dictionaryValue,
            let name = dict[.string("name")]?.stringValue,
            let tabpageValue = dict[.string("tab")],
            let tabpage = RxNeovimApi.Tabpage(tabpageValue) else { return nil }

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

  private func bufferWritten(_ handle: Int) {
    self
      .currentBuffer()
      .flatMap { curBuf -> Single<NvimView.Buffer> in
        self.neoVimBuffer(
          for: RxNeovimApi.Buffer(handle), currentBuffer: curBuf.apiBuffer
        )
      }
      .subscribe(onSuccess: { [weak self] in
        self?.eventsSubject.onNext(.bufferWritten($0))
        self?.updateTouchBarTab()
      }, onFailure: { [weak self] error in
        self?.bridgeLogger.error("Could not get the buffer \(handle): \(error)")
        self?.eventsSubject.onNext(
          .apiError(msg: "Could not get the buffer \(handle).", cause: error)
        )
      })
      .disposed(by: self.disposeBag)
  }

  private func newCurrentBuffer(_ handle: Int) {
    self
      .currentBuffer()
      .filter { $0.apiBuffer.handle == handle }
      .subscribe(onSuccess: { [weak self] in
        self?.eventsSubject.onNext(.newCurrentBuffer($0))
        self?.updateTouchBarTab()
      }, onError: { [weak self] error in
        self?.bridgeLogger.error("Could not get the current buffer: \(error)")
        self?.eventsSubject.onNext(
          .apiError(msg: "Could not get the current buffer.", cause: error)
        )
      })
      .disposed(by: self.disposeBag)
  }

  private func bufferListChanged() {
    self.eventsSubject.onNext(.bufferListChanged)
    self.updateTouchBarCurrentBuffer()
  }

  func focusGained(_ gained: Bool) -> Completable {
    self.api.uiSetFocus(gained: gained)
  }

  private func quit() -> Completable {
    self.bridge.quit()
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

  var id: String { self.getProperty(kTISPropertyInputSourceID) as! String }
  var name: String { self.getProperty(kTISPropertyLocalizedName) as! String }
  var category: String { self.getProperty(kTISPropertyInputSourceCategory) as! String }
  var isSelectable: Bool { self.getProperty(kTISPropertyInputSourceIsSelectCapable) as! Bool }
  var sourceLanguages: [String] { self.getProperty(kTISPropertyInputSourceLanguages) as! [String] }
}

private let gui = DispatchQueue.main
