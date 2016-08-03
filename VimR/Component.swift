/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import RxSwift

protocol Flow {
  var sink: Observable<Any> { get }
}

protocol Store: Flow {}

protocol Component: Flow {}

protocol ViewComponent: Component {
  var view: NSView { get }
}
