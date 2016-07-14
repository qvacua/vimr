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

//    NSLog("\(#function): \(event)")

    let modifierFlags = event.modifierFlags
    let capslock = modifierFlags.contains(.AlphaShiftKeyMask)
    let shift = modifierFlags.contains(.ShiftKeyMask)
    let chars = event.characters!
    let charsIgnoringModifiers = shift || capslock ? event.charactersIgnoringModifiers!.lowercaseString
                                                   : event.charactersIgnoringModifiers!

    if KeyUtils.isSpecial(key: charsIgnoringModifiers) {
      if let vimModifiers = self.vimModifierFlags(modifierFlags) {
        self.agent.vimInput(self.wrapNamedKeys(vimModifiers + KeyUtils.namedKeyFrom(key: charsIgnoringModifiers)))
      } else {
        self.agent.vimInput(self.wrapNamedKeys(KeyUtils.namedKeyFrom(key: charsIgnoringModifiers)))
      }
    } else {
      if let vimModifiers = self.vimModifierFlags(modifierFlags) {
        self.agent.vimInput(self.wrapNamedKeys(vimModifiers + charsIgnoringModifiers))
      } else {
        self.agent.vimInput(self.vimPlainString(chars))
      }
    }

    self.keyDownDone = true
  }

  public func insertText(aString: AnyObject, replacementRange: NSRange) {
//    NSLog("\(#function): \(replacementRange): '\(aString)'")

    switch aString {
    case let string as String:
      self.agent.vimInput(self.vimPlainString(string))
    case let attributedString as NSAttributedString:
      self.agent.vimInput(self.vimPlainString(attributedString.string))
    default:
      break;
    }

    // unmarkText()
    self.lastMarkedText = self.markedText
    self.markedText = nil
    self.markedPosition = Position.null
    self.keyDownDone = true
  }

  public override func doCommandBySelector(aSelector: Selector) {
//    NSLog("\(#function): \(aSelector)");

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
    
    // eg 하 -> hanja popup, cf comment for self.lastMarkedText
    if replacementRange.length > 0 {
      self.agent.deleteCharacters(replacementRange.length)
    }

    switch aString {
    case let string as String:
      self.markedText = string
    case let attributedString as NSAttributedString:
      self.markedText = attributedString.string
    default:
      self.markedText = String(aString) // should not occur
    }
    
//    NSLog("\(#function): \(self.markedText), \(selectedRange), \(replacementRange)")

    self.agent.vimInputMarkedText(self.markedText!)
    self.keyDownDone = true
  }

  public func unmarkText() {
//    NSLog("\(#function): ")
    self.markedText = nil
    self.markedPosition = Position.null
    self.keyDownDone = true
    
    // TODO: necessary?
    self.setNeedsDisplayInRect(self.cellRectFor(row: self.grid.putPosition.row, column: self.grid.putPosition.column))
  }

  /// Return the current selection (or the position of the cursor with empty-length range). For example when you enter
  /// "Cmd-Ctrl-Return" you'll get the Emoji-popup at the rect by firstRectForCharacterRange(actualRange:) where the
  /// first range is the result of this method.
  public func selectedRange() -> NSRange {
    // When the app starts and the Hangul input method is selected, this method gets called very early...
    guard self.grid.hasData else {
//      NSLog("\(#function): not found")
      return NSRange(location: NSNotFound, length: 0)
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

    NSLog("\(#function): returning empty range")
    return NSRange(location: NSNotFound, length: 0)
  }

  public func hasMarkedText() -> Bool {
//    NSLog("\(#function)")
    return self.markedText != nil
  }

  // FIXME: take into account the "return nil"-case
  // FIXME: just fix me, PLEASE...
  public func attributedSubstringForProposedRange(aRange: NSRange, actualRange: NSRangePointer) -> NSAttributedString? {
//    NSLog("\(#function): \(aRange), \(actualRange[0])")
    if aRange.location == NSNotFound {
//      NSLog("\(#function): range not found: returning nil")
      return nil
    }
    
    guard let lastMarkedText = self.lastMarkedText else {
//      NSLog("\(#function): no last marked text: returning nil")
      return nil
    }
    
    // we only support last marked text, thus fill dummy characters when Cocoa asks for more characters than marked...
    let fillCount = aRange.length - lastMarkedText.characters.count
    guard fillCount >= 0 else {
      return nil
    }

    let fillChars = Array(0..<fillCount).reduce("") { (result, _) in return result + " " }
    
//    NSLog("\(#function): \(aRange), \(actualRange[0]): \(fillChars + lastMarkedText)")
    return NSAttributedString(string: fillChars + lastMarkedText)
  }

  public func validAttributesForMarkedText() -> [String] {
    return []
  }

  public func firstRectForCharacterRange(aRange: NSRange, actualRange: NSRangePointer) -> NSRect {
    let position = self.grid.positionFromSingleIndex(aRange.location)
    
//    NSLog("\(#function): \(aRange),\(actualRange[0]) -> \(position.row):\(position.column)")

    let resultInSelf = self.cellRectFor(row: position.row, column: position.column)
    let result = self.window?.convertRectToScreen(self.convertRect(resultInSelf, toView: nil))

    return result!
  }

  public func characterIndexForPoint(aPoint: NSPoint) -> Int {
//    NSLog("\(#function): \(aPoint)")
    return 1
  }
  
  func vimModifierFlags(modifierFlags: NSEventModifierFlags) -> String? {
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

    if result.characters.count > 0 {
      return result
    }

    return nil
  }
}
