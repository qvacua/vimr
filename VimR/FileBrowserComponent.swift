/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import RxSwift
import PureLayout
import CocoaFontAwesome

enum FileBrowserAction {

  case open(url: URL)
  case openInNewTab(url: URL)
  case openInCurrentTab(url: URL)
  case openInHorizontalSplit(url: URL)
  case openInVerticalSplit(url: URL)
  case setAsWorkingDirectory(url: URL)
  case scrollToSource(cwd: URL)
}

struct FileBrowserData: StandardPrefData {

  fileprivate static let isShowHidden = "is-show-hidden"

  static let `default` = FileBrowserData(isShowHidden: false)

  var isShowHidden: Bool

  init(isShowHidden: Bool) {
    self.isShowHidden = isShowHidden
  }

  init?(dict: [String: Any]) {
    guard let isShowHidden = PrefUtils.bool(from: dict, for: FileBrowserData.isShowHidden) else {
      return nil
    }

    self.init(isShowHidden: isShowHidden)
  }

  func dict() -> [String: Any] {
    return [
      FileBrowserData.isShowHidden: self.isShowHidden
    ]
  }
}

class FileBrowserComponent: StandardViewComponent, ToolDataHolder {

  fileprivate let fileView: FileOutlineView
  fileprivate let fileItemService: FileItemService

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

  class InnerCustomToolbar: NSView {

    fileprivate weak var fileBrowser: FileBrowserComponent? {
      didSet {
        self.goToParentButton.target = self.fileBrowser
        self.scrollToSourceButton.target = self.fileBrowser
      }
    }

    required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }

    let goToParentButton = NSButton(forAutoLayout:())
    let scrollToSourceButton = NSButton(forAutoLayout:())

    init() {
      super.init(frame: .zero)
      self.configureForAutoLayout()

      self.addViews()
    }

    fileprivate func addViews() {
      let goToParentIcon = NSImage.fontAwesomeIcon(name: .levelUp,
                                                   textColor: InnerToolBar.iconColor,
                                                   dimension: InnerToolBar.iconDimension)

      let goToParent = self.goToParentButton
      goToParent.toolTip = "Set parent as working directory"
      InnerToolBar.configureToStandardIconButton(button: goToParent, image: goToParentIcon)
      goToParent.action = #selector(FileBrowserComponent.goToParentAction)

      let scrollToSourceIcon = NSImage.fontAwesomeIcon(name: .bullseye,
                                                       textColor: InnerToolBar.iconColor,
                                                       dimension: InnerToolBar.iconDimension)
      let scrollToSource = self.scrollToSourceButton
      scrollToSource.toolTip = "Navigate to the current buffer"
      InnerToolBar.configureToStandardIconButton(button: scrollToSource, image: scrollToSourceIcon)
      scrollToSource.action = #selector(FileBrowserComponent.scrollToSourceAction)

      self.addSubview(goToParent)
      self.addSubview(scrollToSource)

      goToParent.autoPinEdge(toSuperviewEdge: .top)
      goToParent.autoPinEdge(toSuperviewEdge: .right)
      scrollToSource.autoPinEdge(toSuperviewEdge: .top)
      scrollToSource.autoPinEdge(.right, to: .left, of: goToParent)
    }
  }

  override var isFirstResponder: Bool {
    return self.fileView.isFirstResponder
  }

  var toolData: StandardPrefData {
    return FileBrowserData(isShowHidden: self.isShowHidden)
  }

  let innerCustomToolbar = InnerCustomToolbar()
  let menuItems: [NSMenuItem]

  init(source: Observable<Any>, fileItemService: FileItemService, initialData: FileBrowserData) {
    self.fileItemService = fileItemService
    self.fileView = FileOutlineView(source: source, fileItemService: fileItemService)
    self.fileView.isShowHidden = initialData.isShowHidden

    let showHiddenMenuItem = NSMenuItem(title: "Show Hidden Files",
                                        action: #selector(FileBrowserComponent.showHiddenAction),
                                        keyEquivalent: "")
    showHiddenMenuItem.state = initialData.isShowHidden ? NSOnState : NSOffState
    self.menuItems = [
      showHiddenMenuItem,
    ]

    super.init(source: source)

    self.innerCustomToolbar.fileBrowser = self
    showHiddenMenuItem.target = self

    self.addReactions()
  }

  override func beFirstResponder() {
    self.window?.makeFirstResponder(self.fileView)
  }

  fileprivate func addReactions() {
    self.fileView.sink
      .filter { $0 is FileOutlineViewAction }
      .map { $0 as! FileOutlineViewAction }
      .map {
        switch $0 {
        case let .open(fileItem): return FileBrowserAction.open(url: fileItem.url)
        case let .openFileInNewTab(fileItem): return FileBrowserAction.openInNewTab(url: fileItem.url)
        case let .openFileInCurrentTab(fileItem): return FileBrowserAction.openInCurrentTab(url: fileItem.url)
        case let .openFileInHorizontalSplit(fileItem): return FileBrowserAction.openInHorizontalSplit(url: fileItem.url)
        case let .openFileInVerticalSplit(fileItem): return FileBrowserAction.openInVerticalSplit(url: fileItem.url)
        case let .setAsWorkingDirectory(fileItem): return FileBrowserAction.setAsWorkingDirectory(url: fileItem.url)
        }
      }
      .subscribe(onNext: { [weak self] action in self?.publish(event: action) })
      .addDisposableTo(self.disposeBag)

    self.fileItemService.sink
        .filter { $0 is FileItemServiceChange }
        .map { $0 as! FileItemServiceChange }
        .observeOn(MainScheduler.instance)
        .subscribe(onNext: { [weak self] action in
          switch action {
          case let .childrenChanged(root, fileItem):
            guard root == self?.cwd else {
              return
            }

            self?.fileView.update(fileItem)
          }
        })
        .addDisposableTo(self.disposeBag)
  }

  override func addViews() {
    let scrollView = NSScrollView.standardScrollView()
    scrollView.borderType = .noBorder
    scrollView.documentView = self.fileView

    self.addSubview(scrollView)
    scrollView.autoPinEdgesToSuperviewEdges()
  }

  override func subscription(source: Observable<Any>) -> Disposable {
    return source
      .filter { $0 is MainWindowAction }
      .map { $0 as! MainWindowAction }
      .observeOn(MainScheduler.instance)
      .subscribe(onNext: { [weak self] action in
        switch action {
        case let .changeCwd(mainWindow: _, cwd: cwd):
          self?.cwd = cwd
//          NSLog("cwd changed to \(self.cwd) of \(mainWindow.uuid)")
          self?.fileView.reloadData()

        case let .changeFileBrowserSelection(mainWindow: _, url: url):
          DispatchUtils.gui { self?.beFirstResponder() } // TODO: Why do we need DispatchUtils.gui here?
          self?.fileView.select(url)

        default:
          break
        }
      })
  }
}

// MARK: - Actions
extension FileBrowserComponent {

  func showHiddenAction(_ sender: Any?) {
    self.isShowHidden = !self.isShowHidden
    if let menuItem = sender as? NSMenuItem {
      menuItem.state = self.isShowHidden ? NSOnState : NSOffState
    }
  }

  func goToParentAction(_ sender: Any?) {
    self.publish(event: FileBrowserAction.setAsWorkingDirectory(url: self.cwd.parent))
  }

  func scrollToSourceAction(_ sender: Any?) {
    self.publish(event: FileBrowserAction.scrollToSource(cwd: self.cwd))
  }
}
