/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import RxSwift

class OpenQuicklyWindowService: StandardFlow {

  private let openQuicklyWindow: OpenQuicklyWindowComponent

  override init(source: Observable<Any>) {
    self.openQuicklyWindow = OpenQuicklyWindowComponent(source: source)

    super.init(source: source)
  }

  func open(forMainWindow mainWindow: MainWindowComponent) {
    self.openQuicklyWindow.show()
  }

  override func subscription(source source: Observable<Any>) -> Disposable {
    return NopDisposable.instance
  }
}
