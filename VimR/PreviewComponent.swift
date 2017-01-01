/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import RxSwift
import PureLayout
import WebKit

class PreviewComponent: NSView, ViewComponent, ToolDataHolder {

  enum Action {

    case automaticRefresh(url: URL)
    case scroll(to: Position)
  }

  struct PrefData: StandardPrefData {

    fileprivate static let rendererDatas = "renderer-datas"

    fileprivate static let rendererPrefDataFns = [
      MarkdownRenderer.identifier: MarkdownRenderer.prefData,
    ]

    fileprivate static let rendererDefaultPrefDatas = [
      MarkdownRenderer.identifier: MarkdownRenderer.PrefData.default,
    ]

    static let `default` = PrefData(rendererDatas: PrefData.rendererDefaultPrefDatas)

    var rendererDatas: [String: StandardPrefData]

    init(rendererDatas: [String: StandardPrefData]) {
      self.rendererDatas = rendererDatas
    }

    init?(dict: [String: Any]) {
      guard let rendererDataDict = dict[PrefData.rendererDatas] as? [String: [String: Any]] else {
        return nil
      }

      let storedRendererDatas: [(String, StandardPrefData)] = rendererDataDict.flatMap { (identifier, dict) in
        guard let prefDataFn = PrefData.rendererPrefDataFns[identifier] else {
          return nil
        }

        guard let prefData = prefDataFn(dict) else {
          return nil
        }

        return (identifier, prefData)
      }

      let missingRendererDatas: [(String, StandardPrefData)] = Set(PrefData.rendererDefaultPrefDatas.keys)
        .subtracting(storedRendererDatas.map { $0.0 })
        .flatMap { identifier in
          guard let data = PrefData.rendererDefaultPrefDatas[identifier] else {
            return nil
          }

          return (identifier, data)
        }

      self.init(rendererDatas: toDict([storedRendererDatas, missingRendererDatas].flatMap { $0 }))
    }

    func dict() -> [String: Any] {
      return [
        PrefData.rendererDatas: self.rendererDatas.mapToDict { (key, value) in (key, value.dict()) }
      ]
    }
  }

  fileprivate let flow: EmbeddableComponent

  fileprivate var currentUrl: URL?

  fileprivate let renderers: [PreviewRenderer]
  fileprivate var currentRenderer: PreviewRenderer? {
    didSet {
      guard oldValue !== currentRenderer else {
        return
      }

      if let toolbar = self.currentRenderer?.toolbar {
        self.workspaceTool?.customInnerToolbar = toolbar
      }
      if let menuItems = self.currentRenderer?.menuItems {
        self.workspaceTool?.customInnerMenuItems = menuItems
      }
    }
  }
  fileprivate let markdownRenderer: MarkdownRenderer

  fileprivate let baseUrl: URL
  fileprivate let webview = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
  fileprivate let previewService = PreviewService()

  fileprivate var isOpen = false
  fileprivate var currentView: NSView {
    willSet {
      self.currentView.removeFromSuperview()
    }

    didSet {
      self.addSubview(self.currentView)
      self.currentView.autoPinEdgesToSuperviewEdges()
    }
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  weak var workspaceTool: WorkspaceTool?

  var toolData: StandardPrefData {
    let rendererDatas = self.renderers.flatMap { (renderer) -> (String, StandardPrefData)? in
      guard let data = renderer.prefData else {
        return nil
      }
      return (renderer.identifier, data)
    }

    return PrefData(rendererDatas: toDict(rendererDatas))
  }

  var sink: Observable<Any> {
    return self.flow.sink
  }

  var view: NSView {
    return self
  }
  
  init(source: Observable<Any>) {
    self.flow = EmbeddableComponent(source: source)

    self.baseUrl = self.previewService.baseUrl()
    self.markdownRenderer = MarkdownRenderer(source: self.flow.sink)

    self.renderers = [
      self.markdownRenderer,
    ]

    self.webview.configureForAutoLayout()
    self.currentView = self.webview

    super.init(frame: .zero)
    self.configureForAutoLayout()

    self.flow.set(subscription: self.subscription)

    self.webview.loadHTMLString(self.previewService.emptyHtml(), baseURL: self.baseUrl)

    self.addViews()
    self.addReactions()
  }

  fileprivate func addViews() {
    self.addSubview(self.currentView)
    self.currentView.autoPinEdgesToSuperviewEdges()
  }

  fileprivate func subscription(source: Observable<Any>) -> Disposable {
    return source
      .filter { $0 is MainWindowAction }
      .map { $0 as! MainWindowAction }
      .subscribe(onNext: { [unowned self] action in
        switch action {

        case let .currentBufferChanged(_, currentBuffer):
          self.currentUrl = currentBuffer.url

          guard let url = currentBuffer.url else {
            self.currentRenderer = nil
            self.currentView = self.webview
            self.webview.loadHTMLString(self.previewService.saveFirstHtml(), baseURL: self.baseUrl)
            return
          }

          guard self.isOpen else {
            return
          }

          self.currentRenderer = self.renderers.first { $0.canRender(fileExtension: url.pathExtension) }
          self.flow.publish(event: PreviewComponent.Action.automaticRefresh(url: url))

        case let .toggleTool(tool):
          guard tool.view == self else {
            return
          }
          self.isOpen = tool.isSelected

          guard let url = self.currentUrl else {
            self.currentRenderer = nil
            self.currentView = self.webview
            self.webview.loadHTMLString(self.previewService.saveFirstHtml(), baseURL: self.baseUrl)
            return
          }

          self.currentRenderer = self.renderers.first { $0.canRender(fileExtension: url.pathExtension) }
          if self.currentRenderer != nil {
            self.flow.publish(event: PreviewComponent.Action.automaticRefresh(url: url))
          }

        default:
          return

        }
      })
  }

  fileprivate func addReactions() {
    self.markdownRenderer.sink
      .filter { $0 is PreviewRendererAction }
      .map { $0 as! PreviewRendererAction }
      .observeOn(MainScheduler.instance)
      .subscribe(onNext: { [unowned self] action in
        guard self.isOpen else {
          return
        }

        switch action {

        case let .htmlString(_, html, baseUrl):
          self.webview.loadHTMLString(html, baseURL: baseUrl)

        case let .view(_, view):
          self.currentView = view

        case let .scroll(to: position):
          self.flow.publish(event: PreviewComponent.Action.scroll(to: position))

        case .error:
          self.webview.loadHTMLString(self.previewService.errorHtml(), baseURL: self.baseUrl)

        }
      })
      .addDisposableTo(self.flow.disposeBag)
  }
}
