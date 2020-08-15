/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import Down

class AttributedStringMarkdownStyler {

  static func new() -> Styler {
    let fonts = StaticFontCollection(
      body: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize),
      code: NSFont.userFixedPitchFont(ofSize: NSFont.smallSystemFontSize)!
    )

    let style = DownStylerConfiguration(fonts: fonts, paragraphStyles: ParagraphStyles())
    return DownStyler(configuration: style)
  }
}

private struct ParagraphStyles: ParagraphStyleCollection {

  let heading1: NSParagraphStyle
  let heading2: NSParagraphStyle
  let heading3: NSParagraphStyle
  let heading4: NSParagraphStyle
  let heading5: NSParagraphStyle
  let heading6: NSParagraphStyle
  let body: NSParagraphStyle
  let code: NSParagraphStyle

  public init() {
    let headingStyle = NSParagraphStyle()

    let bodyStyle = NSMutableParagraphStyle()
    bodyStyle.paragraphSpacingBefore = 2
    bodyStyle.paragraphSpacing = 2
    bodyStyle.lineSpacing = 2

    let codeStyle = NSMutableParagraphStyle()
    codeStyle.paragraphSpacingBefore = 2
    codeStyle.paragraphSpacing = 2

    self.heading1 = headingStyle
    self.heading2 = headingStyle
    self.heading3 = headingStyle
    self.heading4 = headingStyle
    self.heading5 = headingStyle
    self.heading6 = headingStyle
    self.body = bodyStyle
    self.code = codeStyle
  }
}
