/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import RxSwift
import PureLayout
import WebKit
import Swifter

class HtmlPreviewTool: NSView, UiComponent {

  enum Action {

    case selectHtmlFile(URL)
  }

  typealias StateType = MainWindow.State

  let innerCustomToolbar = InnerCustomToolbar()

  required init(source: Observable<StateType>, emitter: ActionEmitter, state: StateType) {
    self.emitter = emitter
    self.uuid = state.uuid

    let configuration = WKWebViewConfiguration()
    self.webview = WKWebView(frame: CGRect.zero, configuration: configuration)

    super.init(frame: .zero)
    self.configureForAutoLayout()

    self.innerCustomToolbar.htmlPreviewTool = self

    self.addViews()

    self.webview.load(URLRequest(url: URL(string: "http://apple.com")!))

    source
      .observeOn(MainScheduler.instance)
      .subscribe(onNext: { [unowned self] state in
      })
      .addDisposableTo(self.disposeBag)
  }

  fileprivate func addViews() {
    self.webview.configureForAutoLayout()

    self.addSubview(self.webview)
    self.webview.autoPinEdgesToSuperviewEdges()
  }

  fileprivate let emitter: ActionEmitter
  fileprivate let uuid: String

  fileprivate let webview: WKWebView

  fileprivate let disposeBag = DisposeBag()

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func selectHtmlFile(sender: Any?) {
    let panel = NSOpenPanel()
    panel.canChooseDirectories = false
    panel.allowsMultipleSelection = false
    panel.beginSheetModal(for: self.window!) { result in
      guard result == NSFileHandlingPanelOKButton else {
        return
      }

      let urls = panel.urls
      guard urls.count == 1 else {
        return
      }

      self.emitter.emit(UuidAction(uuid: self.uuid, action: Action.selectHtmlFile(urls[0])))
    }
  }
}

extension HtmlPreviewTool {

  class InnerCustomToolbar: NSView {

    fileprivate weak var htmlPreviewTool: HtmlPreviewTool? {
      didSet {
        self.selectHtmlFile.target = self.htmlPreviewTool
      }
    }

    let selectHtmlFile = NSButton(forAutoLayout:())

    init() {
      super.init(frame: .zero)
      self.configureForAutoLayout()

      self.addViews()
    }

    fileprivate func addViews() {
      let selectHtmlFile = self.selectHtmlFile
      InnerToolBar.configureToStandardIconButton(button: selectHtmlFile, iconName: .fileCodeO)
      selectHtmlFile.toolTip = "Select the HTML file"
      selectHtmlFile.action = #selector(HtmlPreviewTool.selectHtmlFile)

      self.addSubview(selectHtmlFile)

      selectHtmlFile.autoPinEdge(toSuperviewEdge: .top)
      selectHtmlFile.autoPinEdge(toSuperviewEdge: .right)
    }

    required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }
  }
}
