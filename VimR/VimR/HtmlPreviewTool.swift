/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import EonilFSEvents
import MaterialIcons
import os
import PureLayout
import RxSwift
import WebKit
import Workspace

private let fileSystemEventsLatency = 1.0

class HtmlPreviewTool: NSView, UiComponent, WKNavigationDelegate {
  enum Action {
    case selectHtmlFile(URL)
  }

  typealias StateType = MainWindow.State

  let innerCustomToolbar = InnerCustomToolbar()

  required init(source: Observable<StateType>, emitter: ActionEmitter, state: StateType) {
    self.emit = emitter.typedEmit()
    self.uuid = state.uuid

    let configuration = WKWebViewConfiguration()
    configuration.processPool = Defs.webViewProcessPool
    self.webview = WKWebView(frame: CGRect.zero, configuration: configuration)

    self.queue = DispatchQueue(
      label: String(reflecting: HtmlPreviewTool.self) + "-\(self.uuid)",
      qos: .userInitiated,
      target: .global(qos: .userInitiated)
    )

    super.init(frame: .zero)
    self.configureForAutoLayout()

    self.webview.navigationDelegate = self
    self.innerCustomToolbar.htmlPreviewTool = self

    self.addViews()

    if let serverUrl = state.htmlPreview.server?.payload {
      self.webview.load(URLRequest(url: serverUrl))
    }

    source
      .observeOn(MainScheduler.instance)
      .subscribe(onNext: { state in
        if state.viewToBeFocused != nil,
           case .htmlPreview = state.viewToBeFocused! { self.beFirstResponder() }

        guard let serverUrl = state.htmlPreview.server else {
          self.monitor = nil
          return
        }

        if serverUrl.mark == self.mark { return }

        self.mark = serverUrl.mark
        self.reloadWebview(with: serverUrl.payload)

        guard let htmlFileUrl = state.htmlPreview.htmlFile else { return }

        do {
          self.monitor = try EonilFSEventStream(
            pathsToWatch: [htmlFileUrl.path],
            sinceWhen: EonilFSEventsEventID.getCurrentEventId(),
            latency: fileSystemEventsLatency,
            flags: [.fileEvents],
            handler: { [weak self] _ in
              self?.reloadWebview(with: serverUrl.payload)
            }
          )
          self.monitor?.setDispatchQueue(self.queue)
          try self.monitor?.start()
        } catch {
          self.log.error("Could not start file monitor for \(htmlFileUrl): \(error)")
        }

        self.innerCustomToolbar
          .selectHtmlFile.toolTip = (htmlFileUrl.path as NSString).abbreviatingWithTildeInPath
      })
      .disposed(by: self.disposeBag)
  }

  deinit {
    self.monitor?.stop()
    self.monitor?.invalidate()
  }

  private func reloadWebview(with url: URL) {
    DispatchQueue.main.async {
      self.webview.evaluateJavaScript("document.body.scrollTop") { result, _ in
        self.scrollTop = result as? Int ?? 0
      }
    }

    self.webview.load(URLRequest(url: url))
  }

  private func addViews() {
    self.webview.configureForAutoLayout()

    self.addSubview(self.webview)
    self.webview.autoPinEdgesToSuperviewEdges()
  }

  private let emit: (UuidAction<Action>) -> Void
  private let uuid: UUID

  private var mark = Token()
  private var scrollTop = 0

  private let webview: WKWebView
  private var monitor: EonilFSEventStream?

  private let disposeBag = DisposeBag()
  private let log = OSLog(subsystem: Defs.loggerSubsystem, category: Defs.LoggerCategory.ui)
  private let queue: DispatchQueue

  @available(*, unavailable)
  required init?(coder _: NSCoder) { fatalError("init(coder:) has not been implemented") }

  @objc func selectHtmlFile(sender _: Any?) {
    let panel = NSOpenPanel()
    panel.canChooseDirectories = false
    panel.allowsMultipleSelection = false
    panel.beginSheetModal(for: self.window!) { result in
      guard result == .OK else { return }

      let urls = panel.urls
      guard urls.count == 1 else { return }

      self.emit(UuidAction(uuid: self.uuid, action: .selectHtmlFile(urls[0])))
    }
  }

  func webView(_: WKWebView, didFinish _: WKNavigation!) {
    self.webview.evaluateJavaScript("document.body.scrollTop = \(self.scrollTop)")
  }
}

extension HtmlPreviewTool {
  class InnerCustomToolbar: CustomToolBar {
    fileprivate weak var htmlPreviewTool: HtmlPreviewTool? {
      didSet { self.selectHtmlFile.target = self.htmlPreviewTool }
    }

    let selectHtmlFile = NSButton(forAutoLayout: ())

    init() {
      super.init(frame: .zero)
      self.configureForAutoLayout()

      self.addViews()
    }

    override func repaint(with theme: Workspace.Theme) {
      self.selectHtmlFile.image = Icon.description.asImage(
        dimension: InnerToolBar.iconDimension,
        style: .outlined,
        color: theme.toolbarForeground
      )
    }

    private func addViews() {
      let selectHtmlFile = self.selectHtmlFile
      InnerToolBar.configureToStandardIconButton(
        button: selectHtmlFile,
        iconName: Icon.description,
        style: .outlined
      )
      selectHtmlFile.toolTip = "Select the HTML file"
      selectHtmlFile.action = #selector(HtmlPreviewTool.selectHtmlFile)

      self.addSubview(selectHtmlFile)

      selectHtmlFile.autoPinEdge(toSuperviewEdge: .top)
      selectHtmlFile.autoPinEdge(toSuperviewEdge: .right, withInset: InnerToolBar.itemPadding)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) { fatalError("init(coder:) has not been implemented") }
  }
}
