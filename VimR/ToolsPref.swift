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

  }

  override var displayName: String {
    return "Tools"
  }

  override var pinToContainer: Bool {
    return true
  }

  required init(source: Observable<StateType>, emitter: ActionEmitter, state: StateType) {
    self.emit = emitter.typedEmit()

    super.init(frame: .zero)

    self.addViews()
    self.updateViews()

    source
      .observeOn(MainScheduler.instance)
      .subscribe(onNext: { state in

        self.updateViews()
      })
      .disposed(by: self.disposeBag)
  }

  fileprivate let emit: (Action) -> Void
  fileprivate let disposeBag = DisposeBag()

  fileprivate let fileBrowserCheckbox = NSButton(forAutoLayout: ())
  fileprivate let openedFilesListCheckbox = NSButton(forAutoLayout: ())
  fileprivate let previewCheckbox = NSButton(forAutoLayout: ())
  fileprivate let htmlCheckbox = NSButton(forAutoLayout: ())

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  fileprivate func updateViews() {
  }

  fileprivate func addViews() {
    let paneTitle = self.paneTitleTextField(title: "Tools")

    let fileBrowser = self.fileBrowserCheckbox
    self.configureCheckbox(button: fileBrowser,
                           title: "File Browser",
                           action: #selector(ToolsPref.fileBrowserAction(_:)))
    let openedFilesList = self.openedFilesListCheckbox
    self.configureCheckbox(button: openedFilesList,
                           title: "Buffers",
                           action: #selector(ToolsPref.openedFilesListAction(_:)))
    let preview = self.previewCheckbox
    self.configureCheckbox(button: preview,
                           title: "Markdown Preview",
                           action: #selector(ToolsPref.previewAction(_:)))
    let html = self.htmlCheckbox
    self.configureCheckbox(button: html,
                           title: "HTML Preview",
                           action: #selector(ToolsPref.htmlAction(_:)))

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

  @IBAction func fileBrowserAction(_ sender: Any?) {
    
  }

  @IBAction func openedFilesListAction(_ sender: Any?) {

  }

  @IBAction func previewAction(_ sender: Any?) {

  }

  @IBAction func htmlAction(_ sender: Any?) {

  }
}
