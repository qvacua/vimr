/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa

class CssUtils {

  static let cssOverridesTemplate: String = try! String(
    contentsOf: Resources.cssOverridesTemplateUrl
  )

  static func cssOverrides(with theme: Theme) -> String {
    self
      .cssOverridesTemplate
      .replacingOccurrences(of: "{{ nvim-color }}", with: self.htmlColor(theme.cssColor))
      .replacingOccurrences(of: "{{ nvim-background-color }}",
                            with: self.htmlColor(theme.cssBackgroundColor))
      .replacingOccurrences(of: "{{ nvim-a }}", with: self.htmlColor(theme.cssA))
      .replacingOccurrences(of: "{{ nvim-hr-background-color }}",
                            with: self.htmlColor(theme.cssHrBorderBackgroundColor))
      .replacingOccurrences(of: "{{ nvim-hr-border-bottom-color }}",
                            with: self.htmlColor(theme.cssHrBorderBottomColor))
      .replacingOccurrences(of: "{{ nvim-blockquote-border-left-color }}",
                            with: self.htmlColor(theme.cssBlockquoteBorderLeftColor))
      .replacingOccurrences(of: "{{ nvim-blockquote-color }}",
                            with: self.htmlColor(theme.cssBlockquoteColor))
      .replacingOccurrences(of: "{{ nvim-h2-border-bottom-color }}",
                            with: self.htmlColor(theme.cssH2BorderBottomColor))
      .replacingOccurrences(of: "{{ nvim-h6-color }}", with: self.htmlColor(theme.cssH6Color))
      .replacingOccurrences(of: "{{ nvim-code-background-color }}",
                            with: self.htmlColor(theme.cssCodeBackgroundColor))
      .replacingOccurrences(of: "{{ nvim-code-color }}", with: self.htmlColor(theme.cssCodeColor))
  }

  private static func htmlColor(_ color: NSColor) -> String { "#\(color.hex)" }
}
