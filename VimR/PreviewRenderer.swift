/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa

protocol PreviewRenderer: class {

  var toolbar: NSView? { get }
  var menuItems: [NSMenuItem]? { get }

  func canRender(fileExtension: String) -> Bool
}

enum PreviewRendererAction {

  case htmlString(renderer: PreviewRenderer, html: String, baseUrl: URL)
  case view(renderer: PreviewRenderer, view: NSView)

  case scroll(to: Position)

  case error(renderer: PreviewRenderer)
}
