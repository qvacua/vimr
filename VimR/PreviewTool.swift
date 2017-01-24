/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import RxSwift
import PureLayout
import WebKit
import Swifter

class PreviewTool: NSView, UiComponent, WKNavigationDelegate {

//  enum Action {
//
//    case automaticRefresh(url: URL)
//    case reverseSearch(to: Position)
//    case scroll(to: Position)
//  }

  typealias StateType = MainWindow.State

  static let basePath = "tools/previews"

  required init(source: Observable<StateType>, emitter: ActionEmitter, state: StateType) {
    self.webview.configureForAutoLayout()

    super.init(frame: .zero)
    self.configureForAutoLayout()

    self.webview.navigationDelegate = self
    self.webview.loadHTMLString("", baseURL: nil)

    self.addViews()
  }

  fileprivate func addViews() {
    self.addSubview(self.webview)
    self.webview.autoPinEdgesToSuperviewEdges()
  }

  func webView(_: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
    NSLog("ERROR preview component's webview: \(error)")
  }

  fileprivate let webview = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
  fileprivate var isOpen = false

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
