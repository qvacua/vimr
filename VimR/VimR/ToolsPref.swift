/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import PureLayout
import RxSwift

class ToolsPref: PrefPane, UiComponent {
  typealias StateType = AppState

  enum Action {
    case setActiveTools([MainWindow.Tools: Bool])
  }

  override var displayName: String {
    "Tools"
  }

  override var pinToContainer: Bool {
    true
  }

  required init(source: Observable<StateType>, emitter: ActionEmitter, state: StateType) {
    self.emit = emitter.typedEmit()

    self.tools = state.mainWindowTemplate.activeTools

    super.init(frame: .zero)

    self.addViews()
    self.updateViews()

    source
      .observeOn(MainScheduler.instance)
      .subscribe(onNext: { _ in

        self.updateViews()
      })
      .disposed(by: self.disposeBag)
  }

  private let emit: (Action) -> Void
  private let disposeBag = DisposeBag()

  private var tools: [MainWindow.Tools: Bool]

  private let fileBrowserCheckbox = NSButton(forAutoLayout: ())
  private let openedFilesListCheckbox = NSButton(forAutoLayout: ())
  private let previewCheckbox = NSButton(forAutoLayout: ())
  private let htmlCheckbox = NSButton(forAutoLayout: ())

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func updateViews() {
    self.fileBrowserCheckbox.boolState = self.tools[.fileBrowser] ?? true
    self.openedFilesListCheckbox.boolState = self.tools[.buffersList] ?? true
    self.previewCheckbox.boolState = self.tools[.preview] ?? true
    self.htmlCheckbox.boolState = self.tools[.htmlPreview] ?? true
  }

  private func addViews() {
    let paneTitle = self.paneTitleTextField(title: "Tools")

    let fileBrowser = self.fileBrowserCheckbox
    fileBrowser.target = self
    self.configureCheckbox(
      button: fileBrowser,
      title: "File Browser",
      action: #selector(ToolsPref.fileBrowserAction(_:))
    )
    let openedFilesList = self.openedFilesListCheckbox
    openedFilesList.target = self
    self.configureCheckbox(
      button: openedFilesList,
      title: "Buffers",
      action: #selector(ToolsPref.openedFilesListAction(_:))
    )
    let preview = self.previewCheckbox
    preview.target = self
    self.configureCheckbox(
      button: preview,
      title: "Markdown Preview",
      action: #selector(ToolsPref.previewAction(_:))
    )
    let html = self.htmlCheckbox
    html.target = self
    self.configureCheckbox(
      button: html,
      title: "HTML Preview",
      action: #selector(ToolsPref.htmlPreviewAction(_:))
    )

    let info = self.infoTextField(
      markdown: "You can turn off tools you don't need. The effect takes place when new windows are opened."
    )

    self.addSubview(paneTitle)

    self.addSubview(fileBrowser)
    self.addSubview(openedFilesList)
    self.addSubview(preview)
    self.addSubview(html)

    self.addSubview(info)

    paneTitle.autoPinEdge(toSuperviewEdge: .top, withInset: 18)
    paneTitle.autoPinEdge(toSuperviewEdge: .left, withInset: 18)
    paneTitle.autoPinEdge(toSuperviewEdge: .right, withInset: 18, relation: .greaterThanOrEqual)

    fileBrowser.autoPinEdge(.top, to: .bottom, of: paneTitle, withOffset: 18)
    fileBrowser.autoPinEdge(toSuperviewEdge: .left, withInset: 18)

    openedFilesList.autoPinEdge(.top, to: .bottom, of: fileBrowser, withOffset: 5)
    openedFilesList.autoPinEdge(toSuperviewEdge: .left, withInset: 18)

    preview.autoPinEdge(.top, to: .bottom, of: openedFilesList, withOffset: 5)
    preview.autoPinEdge(toSuperviewEdge: .left, withInset: 18)

    html.autoPinEdge(.top, to: .bottom, of: preview, withOffset: 5)
    html.autoPinEdge(toSuperviewEdge: .left, withInset: 18)

    info.autoPinEdge(.top, to: .bottom, of: html, withOffset: 18)
    info.autoPinEdge(toSuperviewEdge: .left, withInset: 18)
  }
}

// MARK: - Actions

extension ToolsPref {
  @IBAction func fileBrowserAction(_: Any?) {
    self.tools[.fileBrowser] = self.fileBrowserCheckbox.boolState
    self.emit(.setActiveTools(self.tools))
  }

  @IBAction func openedFilesListAction(_: Any?) {
    self.tools[.buffersList] = self.openedFilesListCheckbox.boolState
    self.emit(.setActiveTools(self.tools))
  }

  @IBAction func previewAction(_: Any?) {
    self.tools[.preview] = self.previewCheckbox.boolState
    self.emit(.setActiveTools(self.tools))
  }

  @IBAction func htmlPreviewAction(_: Any?) {
    self.tools[.htmlPreview] = self.htmlCheckbox.boolState
    self.emit(.setActiveTools(self.tools))
  }
}
