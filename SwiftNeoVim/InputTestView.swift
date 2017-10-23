/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa

public class InputTestView: NSView, NSTextInputClient {

  var markedText: String?
  var text = ""

  var handledBySelector = false

  /* The receiver inserts aString replacing the content specified by replacementRange. aString can be either an NSString or NSAttributedString instance.
   */
  public func insertText(aString: AnyObject, replacementRange: NSRange) {
    Swift.print("\(#function): \(aString), \(replacementRange)")
    self.markedText = nil
  }

  /* The receiver invokes the action specified by aSelector.
   */
  public override func doCommandBySelector(aSelector: Selector) {
    Swift.print("\(#function): \(aSelector)")
    if aSelector == NSSelectorFromString("noop:") {
      self.handledBySelector = false
      return
    }
  }

  /* The receiver inserts aString replacing the content specified by replacementRange. aString can be either an NSString or NSAttributedString instance. selectedRange specifies the selection inside the string being inserted; hence, the location is relative to the beginning of aString. When aString is an NSString, the receiver is expected to render the marked text with distinguishing appearance (i.e. NSTextView renders with -markedTextAttributes).
   */
  public func setMarkedText(aString: AnyObject, selectedRange: NSRange, replacementRange: NSRange) {
    Swift.print("\(#function): \(aString), \(selectedRange), \(replacementRange)")
    self.markedText = String(aString)
  }

  /* The receiver unmarks the marked text. If no marked text, the invocation of this method has no effect.
   */
  public func unmarkText() {
    Swift.print("\(#function): ")
  }

  /// Return the current selection (or the position of the cursor with empty-length range). For example when you enter
  /// "Cmd-Ctrl-Return" you'll get the Emoji-popup at the rect by firstRectForCharacterRange(actualRange:) where the
  /// first range is the result of this method.
  public func selectedRange() -> NSRange {
    let result = NSRange(location: 1, length: 0)
    Swift.print("\(#function): returning \(result)")
    return result
  }

  /* Returns the marked range. Returns {NSNotFound, 0} if no marked range.
   */
  public func markedRange() -> NSRange {
    if let markedText = self.markedText {
      Swift.print("\(#function): returning \(NSRange(location: 0, length: 1))")
      return NSRange(location: 0, length: 1)
    }

    Swift.print("\(#function): returning \(NSRange(location: NSNotFound, length: 0))")
    return NSRange(location: NSNotFound, length: 0)
  }

  /* Returns whether or not the receiver has marked text.
   */
  public func hasMarkedText() -> Bool {
    let result = self.markedText != nil
    Swift.print("\(#function): returning \(result)")
    return result
  }

  /* Returns attributed string specified by aRange. It may return nil. If non-nil return value and actualRange is non-NULL, it contains the actual range for the return value. The range can be adjusted from various reasons (i.e. adjust to grapheme cluster boundary, performance optimization, etc).
   */
  public func attributedSubstringForProposedRange(aRange: NSRange, actualRange: NSRangePointer) -> NSAttributedString? {
    Swift.print("\(#function): \(aRange), \(actualRange[0])")
    return NSAttributedString(string: "하")
  }

  /* Returns an array of attribute names recognized by the receiver.
   */
  public func validAttributesForMarkedText() -> [String] {
//    Swift.print("\(#function): ")
    return []
  }

  /* Returns the first logical rectangular area for aRange. The return value is in the screen coordinate. The size value can be negative if the text flows to the left. If non-NULL, actuallRange contains the character range corresponding to the returned area.
   */
  public func firstRectForCharacterRange(aRange: NSRange, actualRange: NSRangePointer) -> NSRect {
    if actualRange != nil {
//      Swift.print("\(#function): \(aRange), \(actualRange[0])")
    } else {
//      Swift.print("\(#function): \(aRange), nil")
    }
    Swift.print("\(#function): \(aRange), \(actualRange[0])")

    let resultInSelf = NSRect(x: 0, y: 0, width: 10, height: 10)
    let result = self.window?.convertRectToScreen(self.convertRect(resultInSelf, toView: nil))

    return result!
  }

  /* Returns the index for character that is nearest to aPoint. aPoint is in the screen coordinate system.
   */
  public func characterIndexForPoint(aPoint: NSPoint) -> Int {
    Swift.print("\(#function): \(aPoint)")
    return 1
  }

  override public func performKeyEquivalent(theEvent: NSEvent) -> Bool {
    if self.window!.firstResponder != self {
      return false
    }

    if theEvent.modifierFlags.contains(.CommandKeyMask) {
      if NSApp.mainMenu!.performKeyEquivalent(theEvent) {
        return true
      }
    }

    self.keyDown(theEvent)
    return true
  }

  public override func keyDown(theEvent: NSEvent) {
    Swift.print("\(#function): \(theEvent)")
    let modifierFlags = theEvent.modifierFlags

    let capslock = modifierFlags.contains(.AlphaShiftKeyMask)
    let shift = modifierFlags.contains(.ShiftKeyMask)
    let control = modifierFlags.contains(.ControlKeyMask)
    let option = modifierFlags.contains(.AlternateKeyMask)
    let command = modifierFlags.contains(.CommandKeyMask)
//    let chars = theEvent.characters!
    let charsIgnoringModifiers = shift || capslock ? theEvent.charactersIgnoringModifiers!.lowercaseString
                                                   : theEvent.charactersIgnoringModifiers!

//    Swift.print("characters: \(chars)")// = " + String(format:"%x", theEvent.characters!.unicodeScalars.first!.value))
//    Swift.print("characters ign: \(charsIgnoringModifiers)")// = " + String(format:"%x", theEvent.charactersIgnoringModifiers!.unicodeScalars.first!.value))
//    Swift.print(String(format: "keycode: %x", theEvent.keyCode))
//    Swift.print("shift: \(shift), command: \(command), control: \(control), option: \(option)")

    let inputContext = NSTextInputContext.currentInputContext()!
    let handled = inputContext.handleEvent(theEvent)
    if handled {
//      Swift.print("Cocoa handled it")
    }

//    self.text += theEvent.charactersIgnoringModifiers!
//    Swift.print("\(#function): after: \(self.text)")
  }

  public override func drawRect(dirtyRect: NSRect) {
    NSColor.yellowColor().set()
    dirtyRect.fill()
  }

  private func vimInput(string: String) {
//    Swift.print("### vim input: \(string)")
  }
}
