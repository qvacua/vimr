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

  required init(source: Observable<StateType>, emitter: ActionEmitter, state: StateType) {
    self.webview.configureForAutoLayout()

    super.init(frame: .zero)
    self.configureForAutoLayout()

    self.webview.navigationDelegate = self
    self.webview.loadHTMLString("", baseURL: nil)

    self.addViews()

    source
      .map { $0.preview }
      .mapOmittingNil { $0.server }
      .subscribe(onNext: { [unowned self] serverUrl in
        let urlReq = URLRequest(url: serverUrl)
        self.webview.load(urlReq)
      })
      .addDisposableTo(self.disposeBag)
  }

  fileprivate func addViews() {
    self.addSubview(self.webview)
    self.webview.autoPinEdgesToSuperviewEdges()
  }

  func webView(_: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
    NSLog("ERROR preview component's webview: \(error)")
  }

  fileprivate let webview = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
  fileprivate let disposeBag = DisposeBag()
  fileprivate var isOpen = false

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
