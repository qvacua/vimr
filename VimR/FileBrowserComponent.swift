/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import RxSwift
import PureLayout

enum FileBrowserAction {

  case open(url: URL)
  case openInNewTab(url: URL)
  case openInCurrentTab(url: URL)
  case openInHorizontalSplit(url: URL)
  case openInVerticalSplit(url: URL)
  case setAsWorkingDirectory(url: URL)
  case setParentAsWorkingDirectory(url: URL)
}

class FileBrowserComponent: ViewComponent {

  fileprivate let fileView: FileOutlineView
  fileprivate let fileItemService: FileItemService

  fileprivate var cwd: URL {
    get {
      return self.fileView.cwd
    }
    set {
      self.fileView.cwd = newValue
    }
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override var isFirstResponder: Bool {
    return self.fileView.isFirstResponder
  }

  init(source: Observable<Any>, fileItemService: FileItemService) {
    self.fileItemService = fileItemService
    self.fileView = FileOutlineView(source: source, fileItemService: fileItemService)

    super.init(source: source)
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
        case let .setParentAsWorkingDirectory(fileItem):
          return FileBrowserAction.setParentAsWorkingDirectory(url: fileItem.url)
        }
      }
      .subscribe(onNext: { [unowned self] action in self.publish(event: action) })
      .addDisposableTo(self.disposeBag)

    self.fileItemService.sink
      .filter { $0 is FileItemServiceChange }
      .map { $0 as! FileItemServiceChange }
      .observeOn(MainScheduler.instance)
      .subscribe(onNext: { [unowned self] action in
        switch action {
        case let .childrenChanged(root, fileItem):
          guard root == self.cwd else {
            return
          }

          // FIXME: restore expanded states
          if fileItem?.url == self.cwd {
            self.fileView.reloadItem(nil, reloadChildren: true)
          }

          guard self.fileView.row(forItem: fileItem) > -1 else {
            return
          }

          // FIXME: restore expanded states
          self.fileView.reloadItem(fileItem, reloadChildren: true)
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
      .subscribe(onNext: { [unowned self] action in
        switch action {
        case let .changeCwd(mainWindow: _, cwd: cwd):
          self.cwd = cwd
//          NSLog("cwd changed to \(self.cwd) of \(mainWindow.uuid)")
          self.fileView.reloadData()

        default:
          break
        }
      })
  }
}
