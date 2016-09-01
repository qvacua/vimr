/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import PureLayout
import RxSwift

class OpenQuicklyWindowComponent: WindowComponent, NSWindowDelegate, NSTableViewDelegate, NSTableViewDataSource {

  init(source: Observable<Any>) {
    super.init(source: source, nibName: "OpenQuicklyWindow")

    self.window.delegate = self
  }

  override func addViews() {
    let searchField = NSTextField(forAutoLayout: ())

    self.window.contentView?.addSubview(searchField)
    searchField.autoPinEdgesToSuperviewEdgesWithInsets(NSEdgeInsets(top: 18, left: 18, bottom: 18, right: 18))

    searchField.becomeFirstResponder()
  }

  override func subscription(source source: Observable<Any>) -> Disposable {
    return NopDisposable.instance
  }
}
