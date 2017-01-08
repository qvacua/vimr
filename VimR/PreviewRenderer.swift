/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import RxSwift

protocol PreviewRenderer: class {

  static var identifier: String { get }
  static func prefData(from: [String: Any]) -> StandardPrefData?

  var identifier: String { get }
  var prefData: StandardPrefData? { get }
  var scrollSink: Observable<Any> { get }

  var toolbar: NSView? { get }
  var menuItems: [NSMenuItem]? { get }

  func canRender(fileExtension: String) -> Bool
}

enum PreviewRendererAction {

  case htmlString(renderer: PreviewRenderer, html: String, baseUrl: URL)
  case view(renderer: PreviewRenderer, view: NSView)

  case reverseSearch(to: Position)
  case scroll(to: Position)

  case error(renderer: PreviewRenderer)
}
