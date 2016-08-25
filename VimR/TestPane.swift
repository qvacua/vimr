/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import RxSwift
import PureLayout

class TestPane: PrefPane {
  
  override func addViews() {
    let title = self.paneTitleTextField(title: "Test")
    
    self.addSubview(title)
    
    title.autoPinEdgeToSuperviewEdge(.Left, withInset: 18)
    title.autoPinEdgeToSuperviewEdge(.Top, withInset: 18)
    title.autoPinEdgeToSuperviewEdge(.Bottom, withInset: 18)
    title.autoPinEdgeToSuperviewEdge(.Right, withInset: 18)
  }
  
  override func subscription(source source: Observable<Any>) -> Disposable {
    return NopDisposable.instance
  }
}
