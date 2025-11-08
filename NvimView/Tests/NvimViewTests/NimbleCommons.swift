/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import Nimble

// I don't know why the font returned by Typesetter is not equal to the font
// it should be equal to. This is a workaround.
func equalFont(_ expectedValue: NSFont?) -> Nimble.Matcher<NSFont> {
  Matcher { actualExpression in
    let msg = ExpectationMessage.expectedActualValueTo(
      "equal <\(String(describing: expectedValue))>"
    )
    if let actualValue = try actualExpression.evaluate() {
      return MatcherResult(
        bool: NSFont(
          name: actualValue.fontName,
          size: actualValue.pointSize
        ) == expectedValue!,
        message: msg
      )
    } else {
      return MatcherResult(
        status: .fail,
        message: msg.appendedBeNilHint()
      )
    }
  }
}
