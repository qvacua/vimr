/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import RxSwift
import PureLayout

class FileBrowser: NSView,
                   UiComponent {

  typealias StateType = MainWindow.State

  enum Action {

    case open(url: URL, mode: MainWindow.OpenMode)
    case setAsWorkingDirectory(URL)
  }

  let innerCustomToolbar = InnerCustomToolbar()
  let menuItems: [NSMenuItem]

  override var isFirstResponder: Bool {
    return self.fileView.isFirstResponder
  }

  required init(source: Observable<StateType>, emitter: ActionEmitter, state: StateType) {
    self.uuid = state.uuid
    self.emitter = emitter

    self.fileView = FileOutlineView(source: source, emitter: emitter, state: state)

    let showHiddenMenuItem = NSMenuItem(title: "Show Hidden Files",
                                        action: #selector(FileBrowser.showHiddenAction),
                                        keyEquivalent: "")
    showHiddenMenuItem.boolState = state.fileBrowserShowHidden
    self.menuItems = [
      showHiddenMenuItem,
    ]

    super.init(frame: .zero)

    self.addViews()

    source
      .subscribe(onNext: { [unowned self] state in
        self.currentBufferUrl = state.currentBuffer?.url
      })
      .addDisposableTo(self.disposeBag)
  }

  fileprivate let emitter: ActionEmitter
  fileprivate let disposeBag = DisposeBag()

  fileprivate let uuid: String

  fileprivate var currentBufferUrl: URL?

  fileprivate let fileView: FileOutlineView

  fileprivate var cwd: URL {
    get {
      return self.fileView.cwd
    }
    set {
      self.fileView.cwd = newValue
      self.innerCustomToolbar.goToParentButton.isEnabled = newValue.path != "/"
    }
  }

  fileprivate var isShowHidden: Bool {
    get {
      return self.fileView.isShowHidden
    }

    set {
      self.fileView.isShowHidden = newValue
    }
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  fileprivate func addViews() {
    let scrollView = NSScrollView.standardScrollView()
    scrollView.borderType = .noBorder
    scrollView.documentView = self.fileView

    self.addSubview(scrollView)
    scrollView.autoPinEdgesToSuperviewEdges()
  }
}

extension FileBrowser {

  class InnerCustomToolbar: NSView {

    fileprivate weak var fileBrowser: FileBrowser? {
      didSet {
        self.goToParentButton.target = self.fileBrowser
        self.scrollToSourceButton.target = self.fileBrowser
      }
    }

    let goToParentButton = NSButton(forAutoLayout:())
    let scrollToSourceButton = NSButton(forAutoLayout:())

    init() {
      super.init(frame: .zero)
      self.configureForAutoLayout()

      self.addViews()
    }

    fileprivate func addViews() {
      let goToParent = self.goToParentButton
      InnerToolBar.configureToStandardIconButton(button: goToParent, iconName: .levelUp)
      goToParent.toolTip = "Set parent as working directory"
      goToParent.action = #selector(FileBrowser.goToParentAction)

      let scrollToSource = self.scrollToSourceButton
      InnerToolBar.configureToStandardIconButton(button: scrollToSource, iconName: .bullseye)
      scrollToSource.toolTip = "Navigate to the current buffer"
      scrollToSource.action = #selector(FileBrowser.scrollToSourceAction)

      self.addSubview(goToParent)
      self.addSubview(scrollToSource)

      goToParent.autoPinEdge(toSuperviewEdge: .top)
      goToParent.autoPinEdge(toSuperviewEdge: .right)
      scrollToSource.autoPinEdge(toSuperviewEdge: .top)
      scrollToSource.autoPinEdge(.right, to: .left, of: goToParent)
    }

    required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }
  }
}

// MARK: - Actions
extension FileBrowser {

  func showHiddenAction(_ sender: Any?) {
    self.isShowHidden = !self.isShowHidden
    if let menuItem = sender as? NSMenuItem {
      menuItem.state = self.isShowHidden ? NSOnState : NSOffState
    }
  }

  func goToParentAction(_ sender: Any?) {
    self.emitter.emit(UuidAction(uuid: self.uuid, action: Action.setAsWorkingDirectory(self.cwd.parent)))
  }

  func scrollToSourceAction(_ sender: Any?) {
    guard let url = self.currentBufferUrl else {
      return
    }

    self.fileView.select(url)
  }
}
