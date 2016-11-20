/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import RxSwift
import PureLayout

class BufferListComponent: ViewComponent {

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override init(source: Observable<Any>) {
    super.init(source: source)
  }

  override func addViews() {
  }

  override func subscription(source: Observable<Any>) -> Disposable {
    return Disposables.create()
  }
}
