/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import RxSwift
import PureLayout
import WebKit

struct PreviewPrefData: StandardPrefData {

  static let `default` = PreviewPrefData()

  init() {
  }

  init?(dict: [String: Any]) {
    self.init()
  }

  func dict() -> [String: Any] {
    return [:]
  }
}

class PreviewComponent: ViewComponent {

  fileprivate let previewService = PreviewService()

  let webview = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override init(source: Observable<Any>) {
    super.init(source: source)
  }

  override func addViews() {
    let webview = self.webview
    webview.configureForAutoLayout()

    self.addSubview(webview)

    webview.autoPinEdgesToSuperviewEdges()

    webview.loadHTMLString(self.previewService.emptyPreview(), baseURL: nil)
  }

  override func subscription(source: Observable<Any>) -> Disposable {
    return Disposables.create()
  }
}
