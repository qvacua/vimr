/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa

final class CssUtils {
  // swiftlint:disable:next force_try
  static let cssOverridesTemplate: String = try! String(
    contentsOf: Resources.cssOverridesTemplateUrl
  )

  static func cssOverrides(with theme: Theme) -> String {
    self
      .cssOverridesTemplate
      .replacingOccurrences(of: "{{ nvim-color }}", with: self.htmlColor(theme.cssColor))
      .replacingOccurrences(
        of: "{{ nvim-background-color }}",
        with: self.htmlColor(theme.cssBackgroundColor)
      )
      .replacingOccurrences(of: "{{ nvim-link-color }}", with: self.htmlColor(theme.cssLinkColor))
      .replacingOccurrences(
        of: "{{ nvim-hr-color }}",
        with: self.htmlColor(theme.cssHrColor)
      )
      .replacingOccurrences(
        of: "{{ nvim-blockquote-border-color }}",
        with: self.htmlColor(theme.cssBlockquoteBorderColor)
      )
      .replacingOccurrences(
        of: "{{ nvim-blockquote-color }}",
        with: self.htmlColor(theme.cssBlockquoteColor)
      )
      .replacingOccurrences(
        of: "{{ nvim-h2-border-color }}",
        with: self.htmlColor(theme.cssH2BorderColor)
      )
      .replacingOccurrences(of: "{{ nvim-h6-color }}", with: self.htmlColor(theme.cssH6Color))
      .replacingOccurrences(
        of: "{{ nvim-code-background-color }}",
        with: self.htmlColor(theme.cssCodeBackgroundColor)
      )
      .replacingOccurrences(of: "{{ nvim-code-color }}", with: self.htmlColor(theme.cssCodeColor))
      .replacingOccurrences(of: "{{ nvim-comment-color }}", with: self.htmlColor(theme.cssCommentColor))
      .replacingOccurrences(of: "{{ nvim-string-color }}", with: self.htmlColor(theme.cssStringColor))
      .replacingOccurrences(of: "{{ nvim-boolean-color }}", with: self.htmlColor(theme.cssBooleanColor))
      .replacingOccurrences(of: "{{ nvim-number-color }}", with: self.htmlColor(theme.cssNumberColor))
      .replacingOccurrences(of: "{{ nvim-statement-color }}", with: self.htmlColor(theme.cssStatementColor))
      .replacingOccurrences(of: "{{ nvim-type-color }}", with: self.htmlColor(theme.cssTypeColor))
      .replacingOccurrences(of: "{{ nvim-constant-color }}", with: self.htmlColor(theme.cssConstantColor))
      .replacingOccurrences(of: "{{ nvim-special-color }}", with: self.htmlColor(theme.cssSpecialColor))
  }

  private static func htmlColor(_ color: NSColor) -> String { "#\(color.hex)" }
}
