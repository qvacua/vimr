/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
@preconcurrency import EonilFSEvents
import MaterialIcons
import os
import PureLayout
import WebKit
import Workspace

private let fileSystemEventsLatency = 1.0

final class HtmlPreviewTool: NSView, UiComponent, WKNavigationDelegate {
  typealias StateType = MainWindow.State

  enum Action {
    case selectHtmlFile(URL)
  }

  let uuid = UUID()
  let innerCustomToolbar = InnerCustomToolbar()

  required init(context: ReduxContext, state: StateType) {
    self.context = context
    self.emit = context.actionEmitter.typedEmit()
    self.mainWinUuid = state.uuid

    self.webview = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())

    self.queue = DispatchQueue(
      label: String(reflecting: HtmlPreviewTool.self) + "-\(self.mainWinUuid)",
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

    context.subscribe(uuid: self.uuid) { appState in
      guard let state = appState.mainWindows[self.mainWinUuid] else { return }

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
            Task { @MainActor in
              self?.reloadWebview(with: serverUrl.payload)
            }
          }
        )
        self.monitor?.setDispatchQueue(self.queue)
        try self.monitor?.start()
      } catch {
        self.logger.error("Could not start file monitor for \(htmlFileUrl): \(error)")
      }

      self.innerCustomToolbar
        .selectHtmlFile.toolTip = (htmlFileUrl.path as NSString).abbreviatingWithTildeInPath
    }
  }

  func cleanup() {
    self.context.unsubscribe(uuid: self.uuid)

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

  private let context: ReduxContext
  private let emit: (UuidAction<Action>) -> Void
  private let mainWinUuid: UUID

  private var mark = Token()
  private var scrollTop = 0

  private let webview: WKWebView
  private var monitor: EonilFSEventStream?

  private let logger = Logger(subsystem: Defs.loggerSubsystem, category: Defs.LoggerCategory.ui)
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

      self.emit(UuidAction(uuid: self.mainWinUuid, action: .selectHtmlFile(urls[0])))
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
