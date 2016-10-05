/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import RxSwift

enum FileBrowserAction {

  case open(url: URL)
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
      .subscribe(onNext: { [unowned self] action in
        switch action {
        case let .openFileItem(fileItem):
          self.doubleAction(for: fileItem)
        }
      })
      .addDisposableTo(self.disposeBag)

    self.fileItemService.sink
      .filter { $0 is FileItemServiceChange }
      .map { $0 as! FileItemServiceChange }
      .subscribe(onNext: { [unowned self] action in
        switch action {
        case let .childrenChanged(root, fileItem):
          guard root == self.cwd else {
            return
          }

          // FIXME: restore expanded states
          if fileItem?.url == self.cwd {
            DispatchUtils.gui {
              self.fileView.reloadItem(nil, reloadChildren: true)
            }
          }

          guard self.fileView.row(forItem: fileItem) > -1 else {
            return
          }
          
          // FIXME: restore expanded states
          DispatchUtils.gui {
            self.fileView.reloadItem(fileItem, reloadChildren: true)
          }
        }
        })
      .addDisposableTo(self.disposeBag)
  }

  override func addViews() {
    let fileView = self.fileView
    NSOutlineView.configure(toStandard: fileView)
    fileView.doubleAction = #selector(FileBrowserComponent.fileViewDoubleAction)

    let scrollView = NSScrollView.standardScrollView()
    scrollView.borderType = .noBorder
    scrollView.documentView = fileView

    self.addSubview(scrollView)
    scrollView.autoPinEdgesToSuperviewEdges()
  }

  override func subscription(source: Observable<Any>) -> Disposable {
    return source
      .filter { $0 is MainWindowAction }
      .map { $0 as! MainWindowAction }
      .subscribe(onNext: { [unowned self] action in
        switch action {
        case let .changeCwd(mainWindow: mainWindow):
          self.cwd = mainWindow.cwd
//          NSLog("cwd changed to \(self.cwd) of \(mainWindow.uuid)")
          self.fileView.reloadData()

        default:
          break
        }
      })
  }
}

// MARK: - Actions
extension FileBrowserComponent {

  func fileViewDoubleAction() {
    guard let item = self.fileView.selectedItem as? FileItem else {
      return
    }

    self.doubleAction(for: item)
  }

  fileprivate func doubleAction(for item: FileItem) {
    if item.dir {
      self.fileView.toggle(item: item)
    } else {
      self.publish(event: FileBrowserAction.open(url: item.url))
    }
  }
}
