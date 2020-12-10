/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import MessagePack
import RxSwift

public extension NvimView {
  override func keyDown(with event: NSEvent) {
    self.keyDownDone = false

    NSCursor.setHiddenUntilMouseMoves(true)

    let modifierFlags = event.modifierFlags
    let isMeta = (self.isLeftOptionMeta && modifierFlags.contains(.leftOption))
      || (self.isRightOptionMeta && modifierFlags.contains(.rightOption))

    if !isMeta {
      let cocoaHandledEvent = NSTextInputContext.current?.handleEvent(event) ?? false
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
    let isControlCode = KeyUtils.isControlCode(key: chars) && !isNamedKey
    let isPlain = flags.isEmpty && !isNamedKey
    let isWrapNeeded = !isControlCode && !isPlain

    let namedChars = KeyUtils.namedKey(from: charsIgnoringModifiers)
    let finalInput = isWrapNeeded ? self.wrapNamedKeys(flags + namedChars)
      : self.vimPlainString(chars)

    _ = self.api.input(keys: finalInput, errWhenBlocked: false).syncValue()

    self.keyDownDone = true
  }

  func insertText(_ object: Any, replacementRange: NSRange) {
    self.log.debug("\(object) with \(replacementRange)")

    let text: String
    switch object {
    case let string as String: text = string
    case let attributedString as NSAttributedString: text = attributedString.string
    default: return
    }

    let length = self.markedText?.count ?? 0
    try? self.bridge
      .deleteCharacters(length, andInputEscapedString: self.vimPlainString(text))
      .wait()

    if length > 0 {
      self.ugrid.unmarkCell(at: self.markedPosition)
      self.markForRender(position: self.markedPosition)
      if self.ugrid.isNextCellEmpty(self.markedPosition) {
        self.ugrid.unmarkCell(at: self.markedPosition.advancing(row: 0, column: 1))
        self.markForRender(position: self.markedPosition.advancing(row: 0, column: 1))
      }
    }

    self.lastMarkedText = self.markedText
    self.markedText = nil
    self.markedPosition = .null
    self.keyDownDone = true
  }

  override func doCommand(by aSelector: Selector) {
    if self.responds(to: aSelector) {
      self.log.debug("calling \(aSelector)")
      self.perform(aSelector, with: self)

      self.keyDownDone = true
      return
    }

    self.log.debug("\(aSelector) not implemented, forwarding input to neovim")
    self.keyDownDone = false
  }

  override func performKeyEquivalent(with event: NSEvent) -> Bool {
    if event.type != .keyDown { return false }
    let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

    // <C-Tab> & <C-S-Tab> do not trigger keyDown events.
    // Catch the key event here and pass it to keyDown.
    // By rogual in NeoVim dot app:
    // https://github.com/rogual/neovim-dot-app/pull/248/files
    if flags.contains(.control), event.keyCode == 48 {
      self.keyDown(with: event)
      return true
    }

    // Emoji menu: Cmd-Ctrl-Space
    if flags.contains([.command, .control]), event.keyCode == 49 { return false }

    // Space key (especially in combination with modifiers) can result in
    // unexpected chars (e.g. ctrl-space = \0), so catch the event early and
    // pass it to keyDown.
    if event.keyCode == 49 {
      self.keyDown(with: event)
      return true
    }

    guard let chars = event.characters else { return false }

    // Control code \0 causes rpc parsing problems.
    // So we escape as early as possible
    if chars == "\0" {
      self.api
        .input(keys: self.wrapNamedKeys("Nul"), errWhenBlocked: false)
        .subscribe(onError: { [weak self] error in
          self?.log.error("Error in \(#function): \(error)")
        })
        .disposed(by: self.disposeBag)
      return true
    }

    // For the following two conditions:
    // See special cases in vim/os_win32.c from vim sources
    // Also mentioned in MacVim's KeyBindings.plist
    if flags == .control, chars == "6" {
      self.api
        .input(keys: "\u{1e}", errWhenBlocked: false) // AKA ^^
        .subscribe(onError: { [weak self] error in
          self?.log.error("Error in \(#function): \(error)")
        })
        .disposed(by: self.disposeBag)
      return true
    }

    if flags == .control, chars == "2" {
      // <C-2> should generate \0, escaping as above
      self.api
        .input(keys: self.wrapNamedKeys("Nul"), errWhenBlocked: false)
        .subscribe(onError: { [weak self] error in
          self?.log.error("Error in \(#function): \(error)")
        })
        .disposed(by: self.disposeBag)
      return true
    }

    // NSEvent already sets \u{1f} for <C--> && <C-_>

    return false
  }

  func setMarkedText(_ object: Any, selectedRange: NSRange, replacementRange: NSRange) {
    self.log.debug(
      "object: \(object), selectedRange: \(selectedRange), replacementRange: \(replacementRange)"
    )

    defer { self.keyDownDone = true }

    if self.markedText == nil { self.markedPosition = self.ugrid.cursorPosition }

    let oldMarkedTextLength = self.markedText?.count ?? 0

    switch object {
    case let string as String: self.markedText = string
    case let attributedString as NSAttributedString: self.markedText = attributedString.string
    default: self.markedText = String(describing: object) // should not occur
    }

    if replacementRange != .notFound {
      guard let newMarkedPosition = self.ugrid.firstPosition(
        fromFlatCharIndex: replacementRange.location
      ) else { return }

      self.markedPosition = newMarkedPosition

      self.log.debug("Deleting \(replacementRange.length) and inputting \(self.markedText!)")
      try? self.bridge.deleteCharacters(
        replacementRange.length,
        andInputEscapedString: self.vimPlainString(self.markedText!)
      ).wait()
    } else {
      self.log.debug("Deleting \(oldMarkedTextLength) and inputting \(self.markedText!)")
      try? self.bridge.deleteCharacters(
        oldMarkedTextLength,
        andInputEscapedString: self.vimPlainString(self.markedText!)
      ).wait()
    }

    self.keyDownDone = true
  }

  func unmarkText() {
    let position = self.markedPosition
    self.ugrid.unmarkCell(at: position)
    self.markForRender(position: position)
    if self.ugrid.isNextCellEmpty(position) {
      self.ugrid.unmarkCell(at: position.advancing(row: 0, column: 1))
      self.markForRender(position: position.advancing(row: 0, column: 1))
    }

    self.markedText = nil
    self.markedPosition = .null
    self.keyDownDone = true
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
      self.log.debug("No data in UGrid!")
      return .notFound
    }

    let result: NSRange
    result = NSRange(
      location: self.ugrid.flatCharIndex(forPosition: self.ugrid.cursorPosition),
      length: 0
    )

    self.log.debug("Returning \(result)")
    return result
  }

  func markedRange() -> NSRange {
    guard let marked = self.markedText else {
      self.log.debug("No marked text, returning not found")
      return .notFound
    }

    let result = NSRange(
      location: self.ugrid.flatCharIndex(forPosition: self.markedPosition),
      length: marked.count
    )

    self.log.debug("Returning \(result)")
    return result
  }

  func hasMarkedText() -> Bool { self.markedText != nil }

  func attributedSubstring(
    forProposedRange aRange: NSRange,
    actualRange _: NSRangePointer?
  ) -> NSAttributedString? {
    self.log.debug("\(aRange)")
    if aRange.location == NSNotFound { return nil }

    guard
      let position = self.ugrid.firstPosition(fromFlatCharIndex: aRange.location),
      let inclusiveEndPosition = self.ugrid.lastPosition(
        fromFlatCharIndex: aRange.location + aRange.length - 1
      )
    else { return nil }

    self.log.debug("\(position) ... \(inclusiveEndPosition)")
    let string = self.ugrid.cells[position.row...inclusiveEndPosition.row]
      .map { row in
        row.filter { cell in
          aRange.location <= cell.flatCharIndex && cell.flatCharIndex <= aRange.inclusiveEndIndex
        }
      }
      .flatMap { $0 }
      .map(\.string)
      .joined()

    let delta = aRange.length - string.utf16.count
    if delta != 0 { self.log.debug("delta = \(delta)!") }

    self.log.debug("returning '\(string)'")
    return NSAttributedString(string: string)
  }

  func validAttributesForMarkedText() -> [NSAttributedString.Key] { [] }

  func firstRect(forCharacterRange aRange: NSRange, actualRange _: NSRangePointer?) -> NSRect {
    guard let position = self.ugrid.firstPosition(fromFlatCharIndex: aRange.location) else {
      return CGRect.zero
    }

    self.log.debug("\(aRange)-> \(position.row):\(position.column)")

    let resultInSelf = self.rect(forRow: position.row, column: position.column)
    let result = self.window?.convertToScreen(self.convert(resultInSelf, to: nil))

    return result!
  }

  func characterIndex(for aPoint: NSPoint) -> Int {
    let position = self.position(at: aPoint)
    let result = self.ugrid.flatCharIndex(forPosition: position)

    self.log.debug("\(aPoint) -> \(position) -> \(result)")

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
