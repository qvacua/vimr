/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import RxSwift
import MessagePack

extension NvimView {

  override public func keyDown(with event: NSEvent) {
    self.keyDownDone = false

    NSCursor.setHiddenUntilMouseMoves(true)

    let modifierFlags = event.modifierFlags
    let isMeta = (self.isLeftOptionMeta && modifierFlags.contains(.leftOption))
      || (self.isRightOptionMeta && modifierFlags.contains(.rightOption))

    if !isMeta {
      let cocoaHandledEvent = NSTextInputContext.current?.handleEvent(event) ?? false
      if self.keyDownDone && cocoaHandledEvent {
        stdoutLogger.debug("returning since key down done and cocoa handled event")
        return
      }
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
    let finalInput = isWrapNeeded ? self.wrapNamedKeys(flags + namedChars) : self.vimPlainString(chars)

    try? self.bridge
      .vimInput(finalInput)
      .wait()

    self.keyDownDone = true
  }

  public func insertText(_ object: Any, replacementRange: NSRange) {
    stdoutLogger.debug("\(object) with \(replacementRange)")

    let text: String
    switch object {

    case let string as String:
      text = string

    case let attributedString as NSAttributedString:
      text = attributedString.string

    default:
      return

    }

    let length = self.markedText?.count ?? 0
    let rawResult = self
      .atomicallyDelete(charactersOfLength: length, andInput: text)
      .syncValue()
    if let result = rawResult?.arrayValue {
      if result[1] != .nil {
        stdoutLogger.error("Error while inserting text '\(text)': \(result)")
      }
    }

    if length > 0 {
      self.ugrid.unmarkCell(at: self.markedPosition)
      self.markForRender(position: self.markedPosition)
      if self.ugrid.isNextCellEmpty(self.markedPosition) {
        self.ugrid.unmarkCell(
          at: self.markedPosition.advancing(row: 0, column: 1)
        )
        self.markForRender(
          position: self.markedPosition.advancing(row: 0, column: 1)
        )
      }
    }

    self.lastMarkedText = self.markedText
    self.markedText = nil
    self.markedPosition = .null
    self.keyDownDone = true
  }

  public override func doCommand(by aSelector: Selector) {
    // FIXME: handle when ㅎ -> delete

    if self.responds(to: aSelector) {
      stdoutLogger.debug("calling \(aSelector)")
      self.perform(aSelector, with: self)
      self.keyDownDone = true
      return
    }

    stdoutLogger.debug("\(aSelector) not implemented, " +
                         "forwarding input to neovim")
    self.keyDownDone = false
  }

  override public func performKeyEquivalent(with event: NSEvent) -> Bool {
    if .keyDown != event.type { return false }
    let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

    // <C-Tab> & <C-S-Tab> do not trigger keyDown events.
    // Catch the key event here and pass it to keyDown.
    // (By rogual in NeoVim dot app: https://github.com/rogual/neovim-dot-app/pull/248/files)
    if flags.contains(.control) && 48 == event.keyCode {
      self.keyDown(with: event)
      return true
    }

    // Emoji menu: Cmd-Ctrl-Space
    if flags.contains([.command, .control]) && 49 == event.keyCode {
      return false
    }

    guard let chars = event.characters else {
      return false;
    }

    // Control code \0 causes rpc parsing problems.
    // So we escape as early as possible
    if chars == "\0" {
      self.bridge
        .vimInput(self.wrapNamedKeys("Nul"))
        .trigger()
      return true
    }

    // For the following two conditions:
    // See special cases in vim/os_win32.c from vim sources
    // Also mentioned in MacVim's KeyBindings.plist
    if .control == flags && chars == "6" {
      self.bridge
        .vimInput("\u{1e}") // AKA ^^
        .trigger()
      return true
    }

    if .control == flags && chars == "2" {
      // <C-2> should generate \0, escaping as above
      self.bridge
        .vimInput(self.wrapNamedKeys("Nul"))
        .trigger()
      return true
    }
    // NSEvent already sets \u{1f} for <C--> && <C-_>

    return false
  }

  public func setMarkedText(
    _ object: Any,
    selectedRange: NSRange,
    replacementRange: NSRange
  ) {
    stdoutLogger.debug("object: \(object), selectedRange: \(selectedRange), " +
                         "replacementRange: \(replacementRange)")

    if self.markedText == nil {
      self.markedPosition = self.ugrid.cursorPosition
    }

    stdoutLogger.debug("new marked position: \(self.markedPosition)")

    let length = self.markedText?.count ?? 0
    switch object {
    case let string as String:
      self.markedText = string
    case let attributedString as NSAttributedString:
      self.markedText = attributedString.string
    default:
      self.markedText = String(describing: object) // should not occur
    }

    let rawResult = self
      .atomicallyDelete(charactersOfLength: length, andInput: self.markedText!)
      .syncValue()
    if let result = rawResult?.arrayValue {
      if result[1] != .nil {
        stdoutLogger.error("Error while setting marked text " +
                             "'\(self.markedText!)': \(result)")
      }
    }

    self.keyDownDone = true
  }

  public func unmarkText() {
    stdoutLogger.mark()

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
  public func selectedRange() -> NSRange {
    // When the app starts and the Hangul input method is selected,
    // this method gets called very early...
    guard self.ugrid.hasData else {
      stdoutLogger.debug("No data in UGrid!")
      return .notFound
    }

    var result = NSRange(
      location: self.ugrid.flattenedCellIndex(
        forPosition: self.ugrid.cursorPosition
      ),
      length: 0
    )

    if self.markedPosition != .null {
      result.location = self.ugrid.flattenedCellIndex(forPosition: self.markedPosition)
    }

    stdoutLogger.debug("Returning \(result)")
    return result
  }

  public func markedRange() -> NSRange {
    // FIXME: do we have to handle positions at the column borders?
    if let markedText = self.markedText {
      let result = NSRange(location: self.grid.singleIndexFrom(self.markedPosition),
                           length: markedText.count)
      stdoutLogger.debug("Returning \(result)")
      return result
    }

    stdoutLogger.debug("No marked text, returning not found")
    return .notFound
  }

  public func hasMarkedText() -> Bool {
    stdoutLogger.debug("Marked text: \(String(describing: self.markedText))")
    return self.markedText != nil
  }

  // FIXME: take into account the "return nil"-case
  // FIXME: just fix me, PLEASE...
  public func attributedSubstring(forProposedRange aRange: NSRange,
                                  actualRange: NSRangePointer?) -> NSAttributedString? {

//    self.logger.debug("\(#function): \(aRange), \(actualRange[0])")
    if aRange.location == NSNotFound {
//      self.logger.debug("\(#function): range not found: returning nil")
      return nil
    }

    guard let lastMarkedText = self.lastMarkedText else {
//      self.logger.debug("\(#function): no last marked text: returning nil")
      return nil
    }

    // we only support last marked text, thus fill dummy characters when Cocoa asks for more
    // characters than marked...
    let fillCount = aRange.length - lastMarkedText.count
    guard fillCount >= 0 else {
      return nil
    }

    let fillChars = Array(0..<fillCount).reduce("") { (result, _) in return result + " " }

//    self.logger.debug("\(#function): \(aRange), \(actualRange[0]): \(fillChars + lastMarkedText)")
    return NSAttributedString(string: fillChars + lastMarkedText)
  }

  public func validAttributesForMarkedText() -> [NSAttributedString.Key] {
    return []
  }

  public func firstRect(forCharacterRange aRange: NSRange, actualRange: NSRangePointer?) -> NSRect {
    let position = self.grid.positionFromSingleIndex(aRange.location)

//    self.logger.debug("\(#function): \(aRange),\(actualRange[0]) -> " +
//                      "\(position.row):\(position.column)")

    let resultInSelf = self.rect(forRow: position.row, column: position.column)
    let result = self.window?.convertToScreen(self.convert(resultInSelf, to: nil))

    return result!
  }

  public func characterIndex(for aPoint: NSPoint) -> Int {
//    self.logger.debug("\(#function): \(aPoint)")
    return 1
  }

  func vimModifierFlags(_ modifierFlags: NSEvent.ModifierFlags) -> String? {
    var result = ""

    let control = modifierFlags.contains(.control)
    let option = modifierFlags.contains(.option)
    let command = modifierFlags.contains(.command)
    let shift = modifierFlags.contains(.shift)

    if control {
      result += "C-"
    }

    if option {
      result += "M-"
    }

    if command {
      result += "D-"
    }

    if shift {
      result += "S-"
    }

    if result.count > 0 {
      return result
    }

    return nil
  }

  func wrapNamedKeys(_ string: String) -> String {
    return "<\(string)>"
  }

  func vimPlainString(_ string: String) -> String {
    return string.replacingOccurrences(of: "<", with: self.wrapNamedKeys("lt"))
  }

  private func atomicallyDelete(
    charactersOfLength length: Int, andInput text: String
  ) -> Single<MessagePackValue> {
    var calls = [MessagePackValue]()
    if length > 0 {
      calls.append(
        contentsOf: Array(
          repeating: .array(
            [.string("nvim_input"), .array([.string("<BS>")])]
          ),
          count: length
        )
      )
    }
    calls.append(
      .array(
        [.string("nvim_input"), .array([.string(text)])]
      )
    )

    return self.api.callAtomic(calls: .array(calls))
  }
}
