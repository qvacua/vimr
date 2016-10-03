/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import RxSwift

class OpenQuicklyWindowManager: StandardFlow {

  fileprivate let openQuicklyWindow: OpenQuicklyWindowComponent
  fileprivate let fileItemService: FileItemService

  init(source: Observable<Any>, fileItemService: FileItemService) {
    self.fileItemService = fileItemService
    self.openQuicklyWindow = OpenQuicklyWindowComponent(source: source, fileItemService: fileItemService)

    super.init(source: source)
  }

  func open(forMainWindow mainWindow: MainWindowComponent) {
    self.openQuicklyWindow.show(forMainWindow: mainWindow)
  }

  override func subscription(source: Observable<Any>) -> Disposable {
    return source
      .filter { $0 is MainWindowAction }
      .map { $0 as! MainWindowAction }
      .subscribe(onNext: { [unowned self] event in
        switch event {
        case let .openQuickly(mainWindow: mainWindow):
          self.open(forMainWindow: mainWindow)
        default:
          return
        }
        })
  }
}
