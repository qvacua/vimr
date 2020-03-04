/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

class HtmlPreviewMiddleware: MiddlewareType {

  static func selectFirstHtmlUrl(uuid: UUID) -> URL {
    FileUtils.tempDir().appendingPathComponent("\(uuid)-select-first.html")
  }

  typealias StateType = MainWindow.State
  typealias ActionType = UuidAction<MainWindow.Action>

  init() {
    self.selectFirstHtmlTemplate = try! String(contentsOf: Resources.selectFirstHtmlTemplateUrl)
  }

  func typedApply(_ reduce: @escaping TypedActionReduceFunction) -> TypedActionReduceFunction {
    { tuple in
      let result = reduce(tuple)

      if tuple.state.appearance.theme.mark != self.themeToken {
        self.updateCssOverrides(with: tuple.state.appearance.theme.payload)
        self.themeToken = tuple.state.appearance.theme.mark
      }

      self.updateCssOverrides(with: tuple.state.appearance.theme.payload)
      self.writeSelectFirstHtml(uuid: tuple.state.uuid)

      return result
    }
  }

  private func writeSelectFirstHtml(uuid: UUID) {
    let url = HtmlPreviewMiddleware.selectFirstHtmlUrl(uuid: uuid)
    try? self.selectFirstHtml.write(to: url, atomically: true, encoding: .utf8)
  }

  private func updateCssOverrides(with theme: Theme) {
    self.selectFirstHtml = self
      .selectFirstHtmlTemplate
      .replacingOccurrences(of: "{{ css-overrides }}", with: CssUtils.cssOverrides(with: theme))
  }

  private var themeToken = Token()

  private var selectFirstHtml = ""
  private let selectFirstHtmlTemplate: String
}
