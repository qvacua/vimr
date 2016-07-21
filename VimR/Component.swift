/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import RxSwift

protocol Component {
  var sink: Observable<Any> { get }
}

protocol ViewComponent: Component {
  var view: NSView { get }
}
