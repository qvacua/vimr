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

  public func insertText(aString: AnyObject, replacementRange: NSRange) {
    NSLog("\(#function): \(replacementRange): '\(aString)'")

    switch aString {
    case let string as String:
      self.xpc.vimInput(self.vimPlainString(string))
    case let attributedString as NSAttributedString:
      self.xpc.vimInput(self.vimPlainString(attributedString.string))
    default:
      break;
    }

    // unmarkText()
    self.markedText = nil
    self.markedPosition = Position.null
    // TODO: necessary?
    self.setNeedsDisplayInRect(self.cellRect(row: self.grid.putPosition.row, column: self.grid.putPosition.column))
    self.keyDownDone = true
  }

  public override func doCommandBySelector(aSelector: Selector) {
//    NSLog("\(#function): "\(aSelector)")

    // FIXME: handle when ㅎ -> delete

    if self.respondsToSelector(aSelector) {
      Swift.print("\(#function): calling \(aSelector)")
      self.performSelector(aSelector, withObject: self)
      self.keyDownDone = true
      return
    }

//    NSLog("\(#function): "\(aSelector) not implemented, forwarding input to vim")
    self.keyDownDone = false
  }

  public func setMarkedText(aString: AnyObject, selectedRange: NSRange, replacementRange: NSRange) {

    if self.markedText == nil {
      self.markedPosition = self.grid.putPosition
    }

    switch aString {
    case let string as String:
      self.markedText = string
    case let attributedString as NSAttributedString:
      self.markedText = attributedString.string
    default:
      self.markedText = String(aString) // should not occur
    }
    
    NSLog("\(#function): \(self.markedText), \(selectedRange), \(replacementRange)")

    self.xpc.vimInputMarkedText(self.markedText!)
    self.keyDownDone = true
  }

  public func unmarkText() {
    NSLog("\(#function): ")
    self.markedText = nil
    self.markedPosition = Position.null
    // TODO: necessary?
    self.setNeedsDisplayInRect(self.cellRect(row: self.grid.putPosition.row, column: self.grid.putPosition.column))
    self.keyDownDone = true
  }

  /// Return the current selection (or the position of the cursor with empty-length range). For example when you enter
  /// "Cmd-Ctrl-Return" you'll get the Emoji-popup at the rect by firstRectForCharacterRange(actualRange:) where the
  /// first range is the result of this method.
  public func selectedRange() -> NSRange {
//    if self.markedText == nil {
//      let result = NSRange(location: self.grid.singleIndexFrom(self.grid.position), length: 0)
//      NSLog("\(#function): \(result)")
//      return result
//    }
    
    // FIXME: do we have to handle positions at the column borders?
    if self.grid.isPreviousCellEmpty(self.grid.putPosition) {
      let result = NSRange(
        location: self.grid.singleIndexFrom(
          Position(row: self.grid.putPosition.row, column: self.grid.putPosition.column - 1)
        ),
        length: 0
      )
//      NSLog("\(#function): \(result)")
      return result
    }

    let result = NSRange(location: self.grid.singleIndexFrom(self.grid.putPosition), length: 0)
//    NSLog("\(#function): \(result)")
    return result
  }

  public func markedRange() -> NSRange {
    // FIXME: do we have to handle positions at the column borders?
    if let markedText = self.markedText {
      let result = NSRange(location: self.grid.singleIndexFrom(self.markedPosition),
                           length: markedText.characters.count)
//      NSLog("\(#function): \(result)")
      return result
    }

//    NSLog("\(#function): returning empty range")
    return NSRange(location: NSNotFound, length: 0)
  }

  public func hasMarkedText() -> Bool {
    let result = self.markedText != nil
//    NSLog("\(#function): "returning \(result)")
    return result
  }

  // FIXME: REFACTOR and take into account the "return nil"-case
  public func attributedSubstringForProposedRange(aRange: NSRange, actualRange: NSRangePointer) -> NSAttributedString? {
//    NSLog("\(#function): \(aRange), \(actualRange[0])")
    
    // first check whether the first cell is empty and if so, jump one character backward
    var length = aRange.length
    var location = aRange.location
    var position = self.grid.positionFromSingleIndex(aRange.location)
    if self.grid.isCellEmpty(position) {
      length += 1
      location -= 1
      position = self.grid.positionFromSingleIndex(location)
    }
    
    // check whether the range extend to multiple lines
    let multipleLines = position.column + length >= self.grid.size.width
    
    if !multipleLines {
      // FIXME: do we have to handle position.column + aRange.length >= self.grid.width?
      let string = self.grid.cells[position.row][position.column...(position.column + length)].reduce("") {
        $0 + $1.string
      }
      actualRange[0].length = string.characters.count
//      NSLog("\(#function): \(aRange), \(actualRange[0]): \(string)")
      return NSAttributedString(string: string)
    }
    
    // FIXME: maybe make Grid a Indexable or similar
    var string = ""
    for i in location...(location + length) {
      string += self.grid.cellForSingleIndex(i).string
    }
//    NSLog("\(#function): \(aRange), \(actualRange[0]): \(string)")
    return NSAttributedString(string: string)
  }

  public func validAttributesForMarkedText() -> [String] {
    return []
  }

  public func firstRectForCharacterRange(aRange: NSRange, actualRange: NSRangePointer) -> NSRect {
    let position = self.grid.positionFromSingleIndex(aRange.location)
    
    NSLog("\(#function): \(aRange),\(actualRange[0]) -> \(position.row):\(position.column)")

    let resultInSelf = self.cellRect(row: position.row, column: position.column)
    let result = self.window?.convertRectToScreen(self.convertRect(resultInSelf, toView: nil))

    return result!
  }

  public func characterIndexForPoint(aPoint: NSPoint) -> Int {
    NSLog("\(#function): \(aPoint)")
    return 1
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
