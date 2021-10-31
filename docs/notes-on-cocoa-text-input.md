# Some Notes on Cocoa's Text Input

To use Cocoa's text input system, e.g. the 2-Set Korean input, your view has to implement the [NSTextInputClient](https://developer.apple.com/reference/appkit/nstextinputclient) protocol. Apple's documentation is very scarce, so we're writing down some of our findings.

## Simple Case

For simple cases like `ü`, which can be entered by `Opt-u` + `u`, it's quite straightforward:

1. Enter `Opt-u`.
1. `hasMarkedText()` is called to check whether we already have marked text.
1. `setMarkedText("¨", selectedRange NSRange(1, 0), replacementRange: NSRange(NSNotFound, 0))` is called. In this case the first argument is an `NSString`, `selectedRange` tells us where to put the cursor relative to the string: in this case after `¨`. The range `replacemenRange` tells us whether the string should replace some of the existing text. In this case no replacement is required.
1. Enter `u`.
1. `hasMarkedText()` is called again.
1. `insertText("ü", replacementRange: NSRange(NSNotFound, 0))` is called to finalize the input. It seems that for the replacement range `(NSNotFound, 0)` we should replace the previously marked text with the final string. So in this case we must first delete `¨` and insert `ü`.

## Korean (Hangul, 한글)

Let's move to a bit more complicated case: Korean. In this case more methods are involved:

* `selectedRange()`: all other additional methods seem to rely on this method. Ideally we should return `NSRange(CursorPosition, 0)` when nothing is selected or `NSRange(SelectionBegin, SelectionLength)` when there's a selection.
* `attributedSubstringForProposedRange(_:actualRange:)`: for entering only Hangul, this method can be ignored.

Let's assume we want to enter `하태원`: (`hasMarkedText()` is called here and there...)

1. `selectedRange()` is called multiple times when changing the input method from US to Korean. This is also the case when starting the app with Korean input selected.
1. Enter `ㅎ`.
1. `setMarkedText("ㅎ", selectedRange: NSRange(1, 0) replacementRange:NSRange(NotFound, 0))` is called.
1. Enter `ㅏ`.
1. `attributedSubstringForProposedRange(_:actualRange:)` and `selectedRange()` are called multiple times: again, for only Hangul, ignorable.
1. `setMarkedText("하", selectedRange: NSRange(1, 0), replacementRange: NSRange(NotFound, 0))` is called: delete `ㅎ` and insert `하`; not yet finalized.
1. Enter `ㅌ`
1. `attributedSubstringForProposedRange(_:actualRange:)` and `selectedRange()` are called multiple times: ignore.
1. `setMarkedText("핱", selectedRange: NSRange(1, 0), replacementRange: NSRange(NotFound, 0))` is called: delete `하` and insert `핱`; not yet finalized.
1. Enter `ㅐ`
1. `attributedSubstringForProposedRange(_:actualRange:)` and `selectedRange()` are called multiple times: ignore.
1. `setMarkedText("하", selectedRange: NSRange(1, 0), replacementRange: NSRange(NotFound, 0))` is called: delete `핱` and insert `하`; not yet finalized.
1. `insertText("하", replacementRange: NSRange(NotFound, 0))` is called to finalize the input of `하`.
1. `attributedSubstringForProposedRange(_:actualRange:)` and `selectedRange()` are called multiple times: ignore.
1. `setMarkedText("태", selectedRange: NSRange(1, 0), replacementRange: NSRange(NotFound, 0))` is called: Since the replacement range is `NotFound`, append the marked text `태` to the freshly finalized `하`.
1. ...

## Hanja (한자)

Let's consider the even more complicated case: Hanja in Korean. In this case the `selectedRange()` and `attributedSubstringForProposedRange(_:actualRange:)` play a vital role and also

* `firstRectForCharacterRange(_:actualRange)`: this method is used to determine where to show the Hanja popup. The character range is determined by `selectedRange()`.

Let's assume we want to enter `河`: (again `hasMarkedText()` is called here and there...)

1. Enter `ㅎ`.
1. `setMarkedText("ㅎ", selectedRange: NSRange(1, 0) replacementRange:NSRange(NotFound, 0))` is called.
1. Enter `ㅏ`.
1. `attributedSubstringForProposedRange(_:actualRange:)`, `selectedRange()` and `hasMarkedText()` are called multiple times: again, for only Hangul, ignorable.
1. `setMarkedText("하", selectedRange: NSRange(1, 0), replacementRange: NSRange(NotFound, 0))` is called: delete `ㅎ` and insert `하`; not yet finalized.
1. Enter `Opt-Return`.
1. `setMarkedText("하", selectedRange: NSRange(1, 0), replacementRange: NSRange(NotFound, 0))` is called again.
1. `selectedRange()` is called: here we should return a range which can be consistently used by `attributedSubstringForProposedRange(_:actualRange)` and `firstRectForCharacterRange(_:actualRange)`.
1. `insertText("하", replacementRange: NSRange(NotFound, 0))` is called even we are not done yet... So our view thinks we finalized the input of `하`.
1. `attributedSubstringForProposedRange(_:actualRange)` is called multiple times to get the Hangul syllable to replace with Hanja. The proposed range can be very different in each call.
1. Only if the range from `selectedRange()` could be somehow consistently used in `attributedSubstringForProposedRange(_:actualRange)`, then the Hanja popup is displayed. Otherwise we get the selector `insertNewlineIgnoringFieldEditor` in `doCommandBySelector()`.
1. `setMarkedText("下" , selectedRange: NSRange(1, 0), replacementRange: NSRange(1, 1))` is called: the replacement range is not `NotFound` which means that we first have to delete the text in the given range, in this case the finalized `하` and then append the marked text.
1. Selecting different Hanja calls the usual `setMarkedText(_:selectedRange:actualRange)` and `Return` finalizes the input of `河`.

## Chinese Pinyin

suppose we want to enter 中国

1. we should enter the pinyin `zhongguo`, then `<Space>` to confirm it.
2. each char input triggers: setMarkedText, markedRange, firstRect, attributedSubstringForProposedRange
3. finally setMarkedText("zhong guo", selectedRange: NSRange(10, 0), replacementRange: NSRange(NotFound, 0)) iscalled:
4. then after `<Space>` enter, insertText("中国", replacementRange: NSRange(NotFound, 0)) is called
5. many selectedRange and attributedSubstring(forProposedRange:actualRange:) calls.

this seems right simple. but when in markedtext state(before confirming it),
1. we can use number to select other candidates
2. we can use `=`, `-`, `<UP>`, `<DOWN>`, `<Left>`, `<Right>` to choose candidate, and vim shouldn't handle it.
3. we can use `<Left>`, `<Right>` to move in marked text, and insert char in middle of markedText. even complicate, the move is not by char, but by word.

each marked text or marked cursor changes, setMarkedText will called, with selectedRange point to the marked cursor position(may be middle, not the text end)

so these key shouldn't be handle by vim directly when in marked text state.

and finally we confirmed all markedtext, then a `insertText` will be called

## Other Writing System

Not a clue, since I only know Latin alphabet and Korean (+Hanja)...
