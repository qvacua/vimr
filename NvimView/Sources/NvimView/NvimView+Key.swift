/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import MessagePack

public extension NvimView {
  private func isMeta(_ event: NSEvent) -> Bool {
    let modifierFlags = event.modifierFlags

    if (self.isLeftOptionMeta && modifierFlags.contains(.leftOption))
      || (self.isRightOptionMeta && modifierFlags.contains(.rightOption))
    {
      return true
    }

    if modifierFlags.contains(.control) || modifierFlags.contains(.command) {
      return true
    }

    if event.specialKey != nil, !self.hasMarkedText() {
      return true
    }

    return false
  }

  override func keyDown(with event: NSEvent) {
    self.keyDownDone = false

    NSCursor.setHiddenUntilMouseMoves(true)

    let modifierFlags = event.modifierFlags

    if !self.isMeta(event) {
      let cocoaHandledEvent = NSTextInputContext.current?.handleEvent(event) ?? false
      if self.hasMarkedText() {
        // mark state ignore Down,Up,Left,Right,=,- etc keys
        self.keyDownDone = true
      }
      if self.keyDownDone, cocoaHandledEvent { return }
    }

    let capslock = modifierFlags.contains(.capsLock)
    let shift = modifierFlags.contains(.shift)
    let chars = event.characters!
    let charsIgnoringModifiers = shift || capslock
      ? event.charactersIgnoringModifiers!.lowercased()
      : event.charactersIgnoringModifiers!

    let flags = self.vimModifierFlags(modifierFlags) ?? ""
    let isNamedKey = KeyUtils.isSpecial(key: charsIgnoringModifiers)
    let isControlCode = KeyUtils.isControlCode(key: chars, modifiers: modifierFlags) && !isNamedKey
    let isPlain = flags.isEmpty && !isNamedKey
    let isWrapNeeded = !isControlCode && !isPlain

    let namedChars = KeyUtils.namedKey(from: charsIgnoringModifiers)
    let finalInput = isWrapNeeded ? self.wrapNamedKeys(flags + namedChars)
      : self.vimPlainString(chars)

    self.apiSync.nvimInput(keys: finalInput, errWhenBlocked: false).cauterize()

    self.keyDownDone = true
  }

  func insertText(_ object: Any, replacementRange: NSRange) {
    dlog.debug("\(object) with \(replacementRange)")

    let text: String
    switch object {
    case let string as String: text = string
    case let attributedString as NSAttributedString: text = attributedString.string
    default: return
    }

    self.apiSync.nvimInput(keys: self.vimPlainString(text), errWhenBlocked: false).cauterize()

    if self.hasMarkedText() { self._unmarkText() }
    self.keyDownDone = true
  }

  override func doCommand(by aSelector: Selector) {
    if self.responds(to: aSelector) {
      dlog.debug("calling \(aSelector)")
      self.perform(aSelector, with: self)

      self.keyDownDone = true
      return
    }

    dlog.debug("\(aSelector) not implemented, forwarding input to neovim")
    self.keyDownDone = false
  }

  override func performKeyEquivalent(with event: NSEvent) -> Bool {
    if event.type != .keyDown { return false }

    // Cocoa first calls this method to ask whether a subview implements the key equivalent
    // in question. For example, if we have ⌘-. as shortcut for a menu item, which is the case
    // for "Tools -> Focus Neovim View" by default, at some point in the event processing chain
    // this method will be called. If we want to forward the event to Neovim because the user
    // could have set it for some action, that menu item shortcut will not work. To work around
    // this, we ask NvimViewDelegate whether the event is a shortcut of a menu item. The delegate
    // has to be implemented by the user of NvimView.
    if self.delegate?.isMenuItemKeyEquivalent(event) == true { return false }

    let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

    // Emoji menu: Cmd-Ctrl-Space
    if flags.contains([.command, .control]), event.keyCode == spaceKeyChar { return false }

    // <C-Tab> & <C-S-Tab> do not trigger keyDown events.
    // Catch the key event here and pass it to keyDown.
    // By rogual in NeoVim dot app:
    // https://github.com/rogual/neovim-dot-app/pull/248/files
    if flags.contains(.control), event.keyCode == 48 {
      self.keyDown(with: event)
      return true
    }

    // Space key (especially in combination with modifiers) can result in
    // unexpected chars (e.g. ctrl-space = \0), so catch the event early and
    // pass it to keyDown.
    if event.keyCode == spaceKeyChar {
      self.keyDown(with: event)
      return true
    }

    // <D-.> do not trigger keyDown event.
    if flags.contains(.command), event.keyCode == 47 {
      self.keyDown(with: event)
      return true
    }

    guard let chars = event.characters else { return false }

    // Control code \0 causes rpc parsing problems.
    // So we escape as early as possible
    if chars == "\0" {
      self.apiSync
        .nvimInput(keys: self.wrapNamedKeys("Nul"), errWhenBlocked: false)
        .cauterize()
      return true
    }

    // For the following two conditions:
    // See special cases in vim/os_win32.c from vim sources
    // Also mentioned in MacVim's KeyBindings.plist
    if flags == .control, chars == "6" {
      self.apiSync
        .nvimInput(keys: "\u{1e}", errWhenBlocked: false) // AKA ^^
        .cauterize()
      return true
    }

    if flags == .control, chars == "2" {
      // <C-2> should generate \0, escaping as above
      self.apiSync
        .nvimInput(keys: self.wrapNamedKeys("Nul"), errWhenBlocked: false)
        .cauterize()
      return true
    }

    // NSEvent already sets \u{1f} for <C--> && <C-_>

    return false
  }

  func setMarkedText(_ object: Any, selectedRange: NSRange, replacementRange: NSRange) {
    dlog.debug(
      "object: \(object), selectedRange: \(selectedRange), replacementRange: \(replacementRange)"
    )

    defer { self.keyDownDone = true }

    switch object {
    case let string as String: self.markedText = string
    case let attributedString as NSAttributedString: self.markedText = attributedString.string
    default: self.markedText = String(describing: object) // should not occur
    }

    if replacementRange != .notFound {
      guard self.ugrid.firstPosition(fromFlatCharIndex: replacementRange.location) != nil
      else { return }
      // FIXME: here not validate location, only delete by length.
      // after delete, cusor should be the location
    }

    // FIXME: We should be careful here re. timing
    if replacementRange.length > 0 {
      let text = String(repeating: "<BS>", count: replacementRange.length)
      self.apiSync.nvimFeedkeys(keys: text, mode: "i", escape_ks: false).cauterize()
    }

    // delay to wait async gui update handled.
    // this avoid insert and then delete flicker
    // the markedPosition is not needed since marked Text should always following cursor..
    // Do we need Task { @MainActor } here?
    Task {
      guard let mt = markedText else {
        return
      }
      ugrid.updateMark(markedText: mt, selectedRange: selectedRange)
      markForRender(region: regionForRow(at: ugrid.cursorPosition))
    }
  }

  func unmarkText() {
    self._unmarkText()
    self.keyDownDone = true
  }

  func _unmarkText() {
    guard self.hasMarkedText() else { return }
    // wait inserted text gui update event, so hanji in korean get right previous string and can
    // popup candidate window
    Task {
      if let markedInfo = self.ugrid.markedInfo {
        self.ugrid.markedInfo = nil
        self.markForRender(region: regionForRow(at: markedInfo.position))
      }
    }
    self.markedText = nil
  }

  /**
   Return the current selection or the position of the cursor with empty-length
   range. For example when you enter "Cmd-Ctrl-Return" you'll get the
   Emoji-popup at the rect by firstRectForCharacterRange(actualRange:) where
   the first range is the result of this method.
   */
  func selectedRange() -> NSRange {
    // When the app starts and the Hangul input method is selected,
    // this method gets called very early...
    guard self.ugrid.hasData else {
      dlog.debug("No data in UGrid!")
      return .notFound
    }

    let result: NSRange
    result = NSRange(
      location: self.ugrid.flatCharIndex(
        forPosition: self.ugrid.cursorPositionWithMarkedInfo(allowOverflow: true)
      ),
      length: 0
    )

    dlog.debug("Returning \(result)")
    return result
  }

  func markedRange() -> NSRange {
    guard let marked = self.markedText else {
      dlog.debug("No marked text, returning not found")
      return .notFound
    }

    let result = NSRange(
      location: self.ugrid.flatCharIndex(forPosition: self.ugrid.cursorPosition),
      length: marked.count
    )

    dlog.debug("Returning \(result)")
    return result
  }

  func hasMarkedText() -> Bool { self.markedText != nil }

  func attributedSubstring(
    forProposedRange aRange: NSRange,
    actualRange _: NSRangePointer?
  ) -> NSAttributedString? {
    dlog.debug("\(aRange)")
    if aRange.location == NSNotFound { return nil }

    guard
      let position = self.ugrid.firstPosition(fromFlatCharIndex: aRange.location),
      let inclusiveEndPosition = self.ugrid.lastPosition(
        fromFlatCharIndex: aRange.location + aRange.length - 1
      )
    else { return nil }

    dlog.debug("\(position) ... \(inclusiveEndPosition)")
    let string = self.ugrid.cells[position.row...inclusiveEndPosition.row]
      .map { row in
        row.filter { cell in
          aRange.location <= cell.flatCharIndex && cell.flatCharIndex <= aRange.inclusiveEndIndex
        }
      }
      .flatMap(\.self)
      .map(\.string)
      .joined()

    let delta = aRange.length - string.utf16.count
    if delta != 0 { dlog.debug("delta = \(delta)!") }

    dlog.debug("returning '\(string)'")
    return NSAttributedString(string: string)
  }

  func validAttributesForMarkedText() -> [NSAttributedString.Key] { [] }

  func firstRect(forCharacterRange aRange: NSRange, actualRange _: NSRangePointer?) -> NSRect {
    guard let position = self.ugrid.firstPosition(fromFlatCharIndex: aRange.location) else {
      return CGRect.zero
    }

    dlog.debug("\(aRange)-> \(position.row):\(position.column)")

    let resultInSelf = self.rect(forRow: position.row, column: position.column)
    let result = self.window?.convertToScreen(self.convert(resultInSelf, to: nil))

    return result!
  }

  func characterIndex(for aPoint: NSPoint) -> Int {
    let position = self.position(at: aPoint)
    let result = self.ugrid.flatCharIndex(forPosition: position)

    dlog.debug("\(aPoint) -> \(position) -> \(result)")

    return result
  }

  internal func vimModifierFlags(_ modifierFlags: NSEvent.ModifierFlags) -> String? {
    var result = ""

    let control = modifierFlags.contains(.control)
    let option = modifierFlags.contains(.option)
    let command = modifierFlags.contains(.command)
    let shift = modifierFlags.contains(.shift)

    if control { result += "C-" }
    if option { result += "M-" }
    if command { result += "D-" }
    if shift { result += "S-" }

    if result.count > 0 { return result }

    return nil
  }

  internal func wrapNamedKeys(_ string: String) -> String { "<\(string)>" }

  internal func vimPlainString(_ string: String) -> String {
    string.replacingOccurrences(of: "<", with: self.wrapNamedKeys("lt"))
  }
}

private let spaceKeyChar = 49
