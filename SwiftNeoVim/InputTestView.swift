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
    
    self.vimInput(String(aString))
    self.markedText = nil
  }
  
  /* The receiver invokes the action specified by aSelector.
   */
  public override func doCommandBySelector(aSelector: Selector) {
    self.handledBySelector = true
    Swift.print("\(#function): \(aSelector)")
    if aSelector == NSSelectorFromString("noop:") {
      self.handledBySelector = false
      return
    }

    /*
 
     public func moveForward(sender: AnyObject?)
     public func moveRight(sender: AnyObject?)
     public func moveBackward(sender: AnyObject?)
     public func moveLeft(sender: AnyObject?)
     public func moveUp(sender: AnyObject?)
     public func moveDown(sender: AnyObject?)
     public func moveWordForward(sender: AnyObject?)
     public func moveWordBackward(sender: AnyObject?)
     public func moveToBeginningOfLine(sender: AnyObject?)
     public func moveToEndOfLine(sender: AnyObject?)
     public func moveToBeginningOfParagraph(sender: AnyObject?)
     public func moveToEndOfParagraph(sender: AnyObject?)
     public func moveToEndOfDocument(sender: AnyObject?)
     public func moveToBeginningOfDocument(sender: AnyObject?)
     public func pageDown(sender: AnyObject?)
     public func pageUp(sender: AnyObject?)
     public func centerSelectionInVisibleArea(sender: AnyObject?)
     
     public func moveBackwardAndModifySelection(sender: AnyObject?)
     public func moveForwardAndModifySelection(sender: AnyObject?)
     public func moveWordForwardAndModifySelection(sender: AnyObject?)
     public func moveWordBackwardAndModifySelection(sender: AnyObject?)
     public func moveUpAndModifySelection(sender: AnyObject?)
     public func moveDownAndModifySelection(sender: AnyObject?)
     
     public func moveToBeginningOfLineAndModifySelection(sender: AnyObject?)
     public func moveToEndOfLineAndModifySelection(sender: AnyObject?)
     public func moveToBeginningOfParagraphAndModifySelection(sender: AnyObject?)
     public func moveToEndOfParagraphAndModifySelection(sender: AnyObject?)
     public func moveToEndOfDocumentAndModifySelection(sender: AnyObject?)
     public func moveToBeginningOfDocumentAndModifySelection(sender: AnyObject?)
     public func pageDownAndModifySelection(sender: AnyObject?)
     public func pageUpAndModifySelection(sender: AnyObject?)
     public func moveParagraphForwardAndModifySelection(sender: AnyObject?)
     public func moveParagraphBackwardAndModifySelection(sender: AnyObject?)
     
     public func moveWordRight(sender: AnyObject?)
     public func moveWordLeft(sender: AnyObject?)
     public func moveRightAndModifySelection(sender: AnyObject?)
     public func moveLeftAndModifySelection(sender: AnyObject?)
     public func moveWordRightAndModifySelection(sender: AnyObject?)
     public func moveWordLeftAndModifySelection(sender: AnyObject?)
     
     public func moveToLeftEndOfLine(sender: AnyObject?)
     public func moveToRightEndOfLine(sender: AnyObject?)
     public func moveToLeftEndOfLineAndModifySelection(sender: AnyObject?)
     public func moveToRightEndOfLineAndModifySelection(sender: AnyObject?)
     
     public func scrollPageUp(sender: AnyObject?)
     public func scrollPageDown(sender: AnyObject?)
     public func scrollLineUp(sender: AnyObject?)
     public func scrollLineDown(sender: AnyObject?)
     
     public func scrollToBeginningOfDocument(sender: AnyObject?)
     public func scrollToEndOfDocument(sender: AnyObject?)
     
     public func transpose(sender: AnyObject?)
     public func transposeWords(sender: AnyObject?)
     
     public func selectAll(sender: AnyObject?)
     public func selectParagraph(sender: AnyObject?)
     public func selectLine(sender: AnyObject?)
     public func selectWord(sender: AnyObject?)
     
     public func indent(sender: AnyObject?)
     public func insertTab(sender: AnyObject?)
     public func insertBacktab(sender: AnyObject?)
     public func insertNewline(sender: AnyObject?)
     public func insertParagraphSeparator(sender: AnyObject?)
     public func insertNewlineIgnoringFieldEditor(sender: AnyObject?)
     public func insertTabIgnoringFieldEditor(sender: AnyObject?)
     public func insertLineBreak(sender: AnyObject?)
     public func insertContainerBreak(sender: AnyObject?)
     public func insertSingleQuoteIgnoringSubstitution(sender: AnyObject?)
     public func insertDoubleQuoteIgnoringSubstitution(sender: AnyObject?)
     
     public func changeCaseOfLetter(sender: AnyObject?)
     public func uppercaseWord(sender: AnyObject?)
     public func lowercaseWord(sender: AnyObject?)
     public func capitalizeWord(sender: AnyObject?)
     
     public func deleteForward(sender: AnyObject?)
     public func deleteBackward(sender: AnyObject?)
     public func deleteBackwardByDecomposingPreviousCharacter(sender: AnyObject?)
     public func deleteWordForward(sender: AnyObject?)
     public func deleteWordBackward(sender: AnyObject?)
     public func deleteToBeginningOfLine(sender: AnyObject?)
     public func deleteToEndOfLine(sender: AnyObject?)
     public func deleteToBeginningOfParagraph(sender: AnyObject?)
     public func deleteToEndOfParagraph(sender: AnyObject?)
     
     public func yank(sender: AnyObject?)
     
     public func complete(sender: AnyObject?)
     
     public func setMark(sender: AnyObject?)
     public func deleteToMark(sender: AnyObject?)
     public func selectToMark(sender: AnyObject?)
     public func swapWithMark(sender: AnyObject?)
     
     public func cancelOperation(sender: AnyObject?)
     */
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
    let result = NSRange(location: 13, length: 0)
    Swift.print("\(#function): returning \(result)")
    return result
  }
  
  /* Returns the marked range. Returns {NSNotFound, 0} if no marked range.
   */
  public func markedRange() -> NSRange {
    Swift.print("\(#function): ")
    
    if let markedText = self.markedText {
      return NSRange(location: self.text.characters.count, length: markedText.characters.count)
    }
    
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
    Swift.print("\(#function): \(aRange), \(actualRange)")
    return NSAttributedString(string: "t")
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
      Swift.print("\(#function): \(aRange), \(actualRange[0])")
    } else {
      Swift.print("\(#function): \(aRange), nil")
    }
    
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
    let chars = theEvent.characters!
    let charsIgnoringModifiers = shift || capslock ? theEvent.charactersIgnoringModifiers!.lowercaseString
                                                   : theEvent.charactersIgnoringModifiers!
    
    Swift.print("characters: \(chars)")// = " + String(format:"%x", theEvent.characters!.unicodeScalars.first!.value))
    Swift.print("characters ign: \(charsIgnoringModifiers)")// = " + String(format:"%x", theEvent.charactersIgnoringModifiers!.unicodeScalars.first!.value))
//    Swift.print(String(format: "keycode: %x", theEvent.keyCode))
    Swift.print("shift: \(shift), command: \(command), control: \(control), option: \(option)")

    let inputContext = NSTextInputContext.currentInputContext()!
    let handled = inputContext.handleEvent(theEvent)
    if handled {
      Swift.print("Cocoa handled it")
    }

//    self.text += theEvent.charactersIgnoringModifiers!
//    Swift.print("\(#function): after: \(self.text)")
  }
  
  public override func drawRect(dirtyRect: NSRect) {
    NSColor.yellowColor().set()
    dirtyRect.fill()
  }
  
  private func vimInput(string: String) {
    Swift.print("### vim input: \(string)")
  }
}
