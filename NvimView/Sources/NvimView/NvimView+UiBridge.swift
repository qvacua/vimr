/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Carbon
import Cocoa
import Foundation
import MessagePack
import NvimServerTypes
import os
import RxPack
import RxSwift

extension NvimView {
  final func initVimError() {
    self.eventsSubject.onNext(.initVimError)
  }

  final func optionSet(_ value: MessagePackValue) {
    guard let options = value.dictionaryValue else {
      self.bridgeLogger.error("Could not convert \(value)")
      return
    }

    self.handleRemoteOptions(options)
  }

  final func resize(_ value: MessagePackValue) {
    guard let array = MessagePackUtils.array(
      from: value, ofSize: 2, conversion: { $0.intValue }
    ) else {
      self.bridgeLogger.error("Could not convert \(value)")
      return
    }

    self.bridgeLogger.debug(array)
    gui.async {
      self.ugrid.resize(Size(width: array[0], height: array[1]))
      self.markForRenderWholeView()
    }
  }

  final func clear() {
    self.bridgeLogger.debug()

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
      }
    ) else {
      self.bridgeLogger.error("Could not convert \(value)")
      return
    }

    self.lastMode = self.currentMode
    self.currentMode = self.name(ofCursorMode: mode)

    self.bridgeLogger.info("\(self.lastMode) -> \(self.currentMode)")
    // self.bridgeLogger.debug(self.name(ofCursorMode: mode))

    gui.async {
      self.mode = mode
      self.markForRender(
        region: self.cursorRegion(for: self.ugrid.cursorPosition)
      )

      self.activateIm()
    }
  }

  final func modeInfoSet(_ value: MessagePackValue) {
    // value[0] = cursorStyleEnabled: Bool
    // value[1] = modeInfoList: [ModeInfo]]
    self.bridgeLogger.trace("modeInfoSet: \(value)")
    if let mainTuple = value.arrayValue,
       mainTuple.count == 2,
       let modeInfoList = mainTuple[1].arrayValue?.map(ModeInfo.init(withMsgPackDict:))
    {
      self.modeInfoList = modeInfoList
    }
  }

  final func flush(_ renderData: [MessagePackValue]) {
    self.bridgeLogger.trace("# of render data: \(renderData.count)")

    gui.async { [self] in
      var (recompute, rowStart) = (false, Int.max)
      renderData.forEach { value in
        guard let renderEntry = value.arrayValue else { return }
        guard renderEntry.count == 2 else { return }

        guard let rawType = renderEntry[0].intValue,
              let innerArray = renderEntry[1].arrayValue,
              let type = RenderDataType(rawValue: rawType)
        else {
          self.bridgeLogger.error("Could not convert \(value)")
          return
        }

        switch type {
        case .rawLine:
          let possibleNewRowStart = self.doRawLine(data: innerArray)
          rowStart = min(rowStart, possibleNewRowStart)
          recompute = true

        case .goto:
          guard let row = innerArray[0].uint64Value,
                let col = innerArray[1].uint64Value,
                let textPositionRow = innerArray[2].uint64Value,
                let textPositionCol = innerArray[3].uint64Value else { return }

          if let possibleNewRowStart = self.doGoto(
            position: Position(row: Int(row), column: Int(col)),
            textPosition: Position(row: Int(textPositionRow), column: Int(textPositionCol))
          ) {
            rowStart = min(rowStart, possibleNewRowStart)
            recompute = true
          }

        case .scroll:
          let values = innerArray.compactMap(\.intValue)
          guard values.count == 6 else {
            self.bridgeLogger.error("Could not convert \(values)")
            return
          }

          let possibleNewRowStart = self.doScroll(values)
          rowStart = min(possibleNewRowStart, rowStart)
          recompute = true

        @unknown default:
          self.log.error("Unknown flush data type")
        }
      }

      guard recompute else { return }
      self.ugrid.recomputeFlatIndices(rowStart: rowStart)
    }
  }

  final func setTitle(with value: MessagePackValue) {
    guard let title = value.stringValue else {
      self.bridgeLogger.error("Could not convert \(value)")
      return
    }

    self.bridgeLogger.debug(title)
    self.eventsSubject.onNext(.setTitle(title))
  }

  final func stop() {
    self.bridgeLogger.debug()
    self.api
      .stop()
      .andThen(Completable.create { completable in
        self.eventsSubject.onNext(.neoVimStopped)
        self.eventsSubject.onCompleted()

        completable(.completed)
        return Disposables.create()
      })
      .andThen(self.bridge.quit())
      .subscribe(onCompleted: { [weak self] in
        self?.bridgeLogger.info("Successfully stopped the bridge.")
        self?.nvimExitedCondition.broadcast()
      }, onError: {
        self.bridgeLogger.fault("There was an error stopping the bridge: \($0)")
      })
      .disposed(by: self.disposeBag)
  }

  final func autoCommandEvent(_ value: MessagePackValue) {
    guard let array = MessagePackUtils.array(
      from: value, ofSize: 2, conversion: { $0.intValue }
    ),
      let event = NvimAutoCommandEvent(rawValue: array[0])
    else {
      self.bridgeLogger.error("Could not convert \(value)")
      return
    }

    self.bridgeLogger.debug("\(event): \(array)")

    let bufferHandle = array[1]

    if event == .vimenter {
      Completable
        .empty()
        .observe(on: SerialDispatchQueueScheduler(qos: .userInitiated))
        .andThen(
          Completable.create { completable in
            self.rpcEventSubscriptionCondition.wait(for: 5)
            self.bridgeLogger.debug("RPC events subscription done.")

            completable(.completed)
            return Disposables.create()
          }
        )
        .andThen(
          {
            let ginitPath = URL(fileURLWithPath: NSHomeDirectory())
              .appendingPathComponent(".config/nvim/ginit.vim").path
            let loadGinit = FileManager.default.fileExists(atPath: ginitPath)
            if loadGinit {
              self.bridgeLogger.debug("Source'ing ginit.vim")
              return self.api.command(command: "source \(ginitPath)")
            } else {
              return .empty()
            }
          }()
        )
        .andThen(self.bridge.notifyReadinessForRpcEvents())
        .subscribe(onCompleted: { [weak self] in
          self?.log.debug("Notified the NvimServer to fire GUIEnter")
        })
        .disposed(by: self.disposeBag)

      return
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

  final func ipcBecameInvalid(_ error: Swift.Error) {
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
        self?.bridgeLogger.fault(
          "There was an error force-closing" +
            " the bridge: \($0)"
        )
      })
  }

  private func doRawLine(data: [MessagePackValue]) -> Int {
    guard data.count == 7 else {
      self.bridgeLogger.error("Could not convert; wrong count: \(data)")
      return Int.max
    }

    guard let row = data[0].intValue,
          let startCol = data[1].intValue,
          let endCol = data[2].intValue, // past last index, but can be 0
          let clearCol = data[3].intValue, // past last index (can be 0?)
          let clearAttr = data[4].intValue,
          let chunk = data[5].arrayValue?.compactMap(\.stringValue),
          let attrIds = data[6].arrayValue?.compactMap(\.intValue)
    else {
      self.bridgeLogger.error("Could not convert \(data)")
      return Int.max
    }

    #if TRACE
      self.bridgeLogger.debug(
        "row: \(row), startCol: \(startCol), endCol: \(endCol), " +
          "clearCol: \(clearCol), clearAttr: \(clearAttr), " +
          "chunk: \(chunk), attrIds: \(attrIds)"
      )
    #endif

    let count = endCol - startCol
    guard chunk.count == count, attrIds.count == count else {
      self.bridgeLogger.error("The count of chunks and attrIds do not match.")
      return Int.max
    }
    self.ugrid.update(
      row: row,
      startCol: startCol,
      endCol: endCol,
      clearCol: clearCol,
      clearAttr: clearAttr,
      chunk: chunk,
      attrIds: attrIds
    )

    if count > 0 {
      if row == self.ugrid.markedInfo?.position.row  {
        self.markForRender(region: Region(
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

    return row
  }

  func regionForRow(at: Position) -> Region {
    return Region(
      top: at.row,
      bottom: at.row,
      left: at.column,
      right: ugrid.size.width
      )
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

  private func doScroll(_ array: [Int]) -> Int {
    self.bridgeLogger.trace("[top, bot, left, right, rows, cols] = \(array)")

    let (top, bottom, left, right, rows, cols)
      = (array[0], array[1] - 1, array[2], array[3] - 1, array[4], array[5])

    let scrollRegion = Region(
      top: top, bottom: bottom,
      left: left, right: right
    )

    self.ugrid.scroll(region: scrollRegion, rows: rows, cols: cols)
    self.markForRender(region: scrollRegion)
    self.eventsSubject.onNext(.scroll)

    return min(0, top)
  }

  private func activateIm() {
    if (self.asciiImSource == nil) {
      self.asciiImSource = TISCopyCurrentASCIICapableKeyboardInputSource().takeRetainedValue()
      self.bridgeLogger.info("ascii IME id: \(asciiImSource!.id), source: \(asciiImSource)")
    }

    // Exit from Insert mode, save ime used in Insert mode.
    if self.lastMode == "Insert" && self.currentMode == "Normal" {
      self.lastImSource = TISCopyCurrentKeyboardInputSource().takeRetainedValue()
      TISSelectInputSource(self.asciiImSource)
      self.bridgeLogger.info("lastImSource id: \(lastImSource!.id), source: \(lastImSource)")
    }

    // Enter into Insert mode, set ime to last used ime in Insert mode.
    // Visual -> Insert
    // Normal -> Insert
    if self.currentMode == "Insert" {
      TISSelectInputSource(self.lastImSource)
    }
  }
}

// MARK: - Simple

extension NvimView {
  final func bell() {
    self.bridgeLogger.debug()
    NSSound.beep()
  }

  final func cwdChanged(_ value: MessagePackValue) {
    guard let cwd = value.stringValue else {
      self.bridgeLogger.error("Could not convert \(value)")
      return
    }

    self.bridgeLogger.debug(cwd)
    self._cwd = URL(fileURLWithPath: cwd)
    self.eventsSubject.onNext(.cwdChanged)
  }

  final func colorSchemeChanged(_ value: MessagePackValue) {
    guard let values = MessagePackUtils.array(
      from: value, ofSize: 5, conversion: { $0.intValue }
    ) else {
      self.bridgeLogger.error("Could not convert \(value)")
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
      self.bridgeLogger.error("Could not convert \(value)")
      return
    }

    self.bridgeLogger.debug(values)

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
    guard let dirty = value.boolValue else {
      self.bridgeLogger.error("Could not convert \(value)")
      return
    }

    self.bridgeLogger.debug(dirty)
    self.eventsSubject.onNext(.setDirtyStatus(dirty))
  }

  final func rpcEventSubscribed() {
    self.rpcEventSubscriptionCondition.broadcast()
    self.eventsSubject.onNext(.rpcEventSubscribed)
  }

  final func bridgeHasFatalError(_ value: MessagePackValue?) {
    gui.async {
      let alert = NSAlert()
      alert.addButton(withTitle: "OK")
      alert.messageText = "Error launching background neovim process"
      alert.alertStyle = .critical

      if let rawCode = value?.intValue,
         let code = NvimServerFatalErrorCode(rawValue: rawCode)
      {
        switch code {
        case .localPort:
          alert.informativeText = "GUI could not connect to the background " +
            "neovim process. The window will close."

        case .remotePort:
          alert.informativeText = "The remote message port could not " +
            "connect to GUI. The window will close."

        @unknown default:
          self.log.error("Unknown fatal error from NvimServer")
        }
      } else {
        alert.informativeText = "There was an unknown error launching the " +
          "background neovim Process. " +
          "The window will close."
      }

      alert.runModal()
      self.queue.async {
        self.eventsSubject.onNext(.neoVimStopped)
        self.eventsSubject.onCompleted()
      }
    }
  }

  final func event(_ value: MessagePackValue) {
    guard let dict = value.dictionaryValue,
          let event = dict.keys.first,
          let args = dict[event]?.arrayValue
    else {
      self.bridgeLogger.error("Could not convert \(value)")
      return
    }

    switch event.stringValue {
    case "tabline_update": self.tablineUpdate(args)
    case "win_viewport": self.winViewportUpdate(args)
    default: break
    }
  }

  final func setAttr(with value: MessagePackValue) {
    guard let array = value.arrayValue else {
      self.bridgeLogger.error("Could not convert \(value)")
      return
    }
    guard array.count == 6 else {
      self.bridgeLogger.error("Could not convert; wrong count \(value)")
      return
    }

    guard let id = array[0].intValue,
          let rawTrait = array[1].uint64Value,
          let fg = array[2].intValue,
          let bg = array[3].intValue,
          let sp = array[4].intValue,
          let reverse = array[5].boolValue
    else {
      self.bridgeLogger.error(
        "Could not get highlight attributes from " +
          "\(value)"
      )
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

    self.bridgeLogger.debug("AttrId: \(id): \(attrs)")

    gui.async {
      self.cellAttributesCollection.set(attributes: attrs, for: id)
    }
  }

  final func updateMenu() {
    self.bridgeLogger.debug()
  }

  final func busyStart() {
    self.bridgeLogger.debug()
  }

  final func busyStop() {
    self.bridgeLogger.debug()
  }

  final func mouseOn() {
    self.bridgeLogger.debug()
  }

  final func mouseOff() {
    self.bridgeLogger.debug()
  }

  final func visualBell() {
    self.bridgeLogger.debug()
  }

  final func suspend() {
    self.bridgeLogger.debug()
  }
}

extension NvimView {
  final func markForRenderWholeView() {
    self.bridgeLogger.debug()
    self.needsDisplay = true
  }

  final func markForRender(region: Region) {
    self.bridgeLogger.trace(region)
    self.setNeedsDisplay(self.rect(for: region))
  }

  final func markForRender(row: Int, column: Int) {
    self.bridgeLogger.trace("\(row):\(column)")
    self.setNeedsDisplay(self.rect(forRow: row, column: column))
  }

  final func markForRender(position: Position) {
    self.bridgeLogger.trace(position)
    self.setNeedsDisplay(
      self.rect(forRow: position.row, column: position.column)
    )
  }
}

extension NvimView {
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

    gui.async { self.tabBar?.update(tabRepresentatives: self.tabEntries) }
  }

  func winViewportUpdate(_: [MessagePackValue]) {}

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
}

extension TISInputSource {
    enum Category {
        static var keyboardInputSource: String {
            return kTISCategoryKeyboardInputSource as String
        }
    }

    private func getProperty(_ key: CFString) -> AnyObject? {
        let cfType = TISGetInputSourceProperty(self, key)
        if (cfType != nil) {
            return Unmanaged<AnyObject>.fromOpaque(cfType!)
            .takeUnretainedValue()
        } else {
            return nil
        }
    }

    var id: String {
        return getProperty(kTISPropertyInputSourceID) as! String
    }

    var name: String {
        return getProperty(kTISPropertyLocalizedName) as! String
    }

    var category: String {
        return getProperty(kTISPropertyInputSourceCategory) as! String
    }

    var isSelectable: Bool {
        return getProperty(kTISPropertyInputSourceIsSelectCapable) as! Bool
    }

    var sourceLanguages: [String] {
        return getProperty(kTISPropertyInputSourceLanguages) as! [String]
    }
}


private let gui = DispatchQueue.main
