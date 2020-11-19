/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

class Resources {
  static let resourceUrl = Bundle.main.resourceURL!
  static let previewUrl = resourceUrl.appendingPathComponent("preview")

  static let cssOverridesTemplateUrl = resourceUrl
    .appendingPathComponent("markdown/color-overrides.css")
  static let cssUrl = resourceUrl.appendingPathComponent("markdown/github-markdown.css")
  static let markdownTemplateUrl = resourceUrl.appendingPathComponent("markdown/template.html")

  static let baseCssUrl = previewUrl.appendingPathComponent("base.css")
  static let emptyHtmlTemplateUrl = previewUrl.appendingPathComponent("empty.html")
  static let errorHtmlTemplateUrl = previewUrl.appendingPathComponent("error.html")
  static let saveFirstHtmlTemplateUrl = previewUrl.appendingPathComponent("save-first.html")
  static let selectFirstHtmlTemplateUrl = previewUrl.appendingPathComponent("select-first.html")
}
