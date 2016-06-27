/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa

extension NeoVimView: NSTextInputClient {

  override public func keyDown(event: NSEvent) {
    self.keyDownDone = false
    
    let context = NSTextInputContext.currentInputContext()!
    let cocoaHandledEvent = context.handleEvent(event)
    if self.keyDownDone && cocoaHandledEvent {
      return
    }
    
    let modifierFlags = event.modifierFlags
    let capslock = modifierFlags.contains(.AlphaShiftKeyMask)
    let shift = modifierFlags.contains(.ShiftKeyMask)
    let chars = event.characters!
    let charsIgnoringModifiers = shift || capslock ? event.charactersIgnoringModifiers!.lowercaseString
                                                   : event.charactersIgnoringModifiers!

    let vimModifiers = self.vimModifierFlags(modifierFlags)
    if vimModifiers.characters.count > 0 {
      self.xpc.vimInput(self.vimNamedKeys(vimModifiers + charsIgnoringModifiers))
    } else {
      self.xpc.vimInput(self.vimPlainString(chars))
    }

    self.keyDownDone = true
  }
  
  private func vimModifierFlags(modifierFlags: NSEventModifierFlags) -> String {
    var result = ""
    
    let control = modifierFlags.contains(.ControlKeyMask)
    let option = modifierFlags.contains(.AlternateKeyMask)
    let command = modifierFlags.contains(.CommandKeyMask)

    if control {
      result += "C-"
    }
    
    if option {
      result += "M-"
    }
    
    if command {
      result += "D-"
    }

    return result
  }

  public func insertText(aString: AnyObject, replacementRange: NSRange) {
    Swift.print("\(#function): \(aString), \(replacementRange)")

    switch aString {
    case let string as String:
      self.xpc.vimInput(self.vimPlainString(string))
    case let attributedString as NSAttributedString:
      self.xpc.vimInput(self.vimPlainString(attributedString.string))
    default:
      break;
    }

    self.markedText = nil
    self.keyDownDone = true
  }

  public override func doCommandBySelector(aSelector: Selector) {
    Swift.print("\(#function): \(aSelector)")

    // TODO: handle when ㅎ -> delete

    if self.respondsToSelector(aSelector) {
      Swift.print("\(#function): calling \(aSelector)")
      self.performSelector(aSelector, withObject: self)
      self.keyDownDone = true
      return
    }

    Swift.print("\(#function): \(aSelector) not implemented, forwarding input to vim")
    self.keyDownDone = false
  }

  public func setMarkedText(aString: AnyObject, selectedRange: NSRange, replacementRange: NSRange) {
    Swift.print("\(#function): \(aString), \(selectedRange), \(replacementRange)")

    switch aString {
    case let string as String:
      self.markedText = string
    case let attributedString as NSAttributedString:
      self.markedText = attributedString.string
    default:
      self.markedText = String(aString) // should not occur
    }

    self.xpc.vimInputMarkedText(self.markedText!)
    self.keyDownDone = true
  }

  public func unmarkText() {
    Swift.print("\(#function): ")
    self.markedText = nil
    self.setNeedsDisplayInRect(self.cellRect(self.grid.position.row, column: self.grid.position.column))
    self.keyDownDone = true
  }

  /// Return the current selection (or the position of the cursor with empty-length range). For example when you enter
  /// "Cmd-Ctrl-Return" you'll get the Emoji-popup at the rect by firstRectForCharacterRange(actualRange:) where the
  /// first range is the result of this method.
  public func selectedRange() -> NSRange {
    let result = NSRange(location: 13, length: 0)
    Swift.print("\(#function): returning \(result)")
    return result
  }

  public func markedRange() -> NSRange {
    Swift.print("\(#function): ")

    if let markedText = self.markedText {
//      return NSRange(location: self.text.characters.count, length: markedText.characters.count)
    }

    return NSRange(location: NSNotFound, length: 0)
  }

  public func hasMarkedText() -> Bool {
    let result = self.markedText != nil
//    Swift.print("\(#function): returning \(result)")
    return result
  }

  public func attributedSubstringForProposedRange(aRange: NSRange, actualRange: NSRangePointer) -> NSAttributedString? {
    Swift.print("\(#function): \(aRange), \(actualRange)")
    return NSAttributedString(string: "t")
  }

  public func validAttributesForMarkedText() -> [String] {
    //    Swift.print("\(#function): ")
    return []
  }

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

  public func characterIndexForPoint(aPoint: NSPoint) -> Int {
    Swift.print("\(#function): \(aPoint)")
    return 1
  }

  /*
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

   public func scrollLineUp(sender: AnyObject?)
   public func scrollLineDown(sender: AnyObject?)

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
