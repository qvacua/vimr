/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import PureLayout
import RxSwift

class OpenQuicklyWindowComponent: WindowComponent, NSWindowDelegate, NSTableViewDelegate, NSTableViewDataSource {
  
  private let searchField = NSTextField(forAutoLayout: ())

  init(source: Observable<Any>) {
    super.init(source: source, nibName: "OpenQuicklyWindow")

    self.window.delegate = self
  }

  override func addViews() {
    self.window.contentView?.addSubview(searchField)
    self.searchField.autoPinEdgesToSuperviewEdgesWithInsets(NSEdgeInsets(top: 18, left: 18, bottom: 18, right: 18))

    self.searchField.becomeFirstResponder()
  }

  override func subscription(source source: Observable<Any>) -> Disposable {
    return NopDisposable.instance
  }
  
  override func show() {
    super.show()
    
    self.searchField.becomeFirstResponder()
  }
}
