/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

func call(@autoclosure closure: () -> Void, when condition: Bool) { if condition { closure() } }
func call(@autoclosure closure: () -> Void, whenNot condition: Bool) { if !condition { closure() } }

extension String {

  func without(prefix prefix: String) -> String {
    guard self.hasPrefix(prefix) else {
      return self
    }
    
    let idx = self.startIndex.advancedBy(prefix.characters.count)
    return self[idx..<self.endIndex]
  }
}