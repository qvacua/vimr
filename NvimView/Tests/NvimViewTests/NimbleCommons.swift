/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import Nimble

// I don't know why the font returned by Typesetter is not equal to the font
// it should be equal to. This is a workaround.
func equalFont(_ expectedValue: NSFont?) -> Predicate<NSFont> {
  Predicate { actualExpression in
    let msg = ExpectationMessage.expectedActualValueTo(
      "equal <\(String(describing: expectedValue))>"
    )
    if let actualValue = try actualExpression.evaluate() {
      return PredicateResult(
        bool: NSFont(
          name: actualValue.fontName,
          size: actualValue.pointSize
        ) == expectedValue!,
        message: msg
      )
    } else {
      return PredicateResult(
        status: .fail,
        message: msg.appendedBeNilHint()
      )
    }
  }
}
