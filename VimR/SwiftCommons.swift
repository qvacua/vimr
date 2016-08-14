/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

func call(@autoclosure closure: () -> Void, when condition: Bool) { if condition { closure() } }
func call(@autoclosure closure: () -> Void, whenNot condition: Bool) { if !condition { closure() } }