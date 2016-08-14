/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import PureLayout
import RxSwift

struct GeneralPrefData {
  let openNewWindowWhenLaunching: Bool
  let openNewWindowOnReactivation: Bool
}

class GeneralPrefPane: PrefPane {

  let openNewWindowWhenLaunching: Bool
  let openNewWindowOnReactivation: Bool

  init(source: Observable<Any>, initialData: GeneralPrefData) {
    self.openNewWindowWhenLaunching = initialData.openNewWindowWhenLaunching
    self.openNewWindowOnReactivation = initialData.openNewWindowOnReactivation

    super.init(source: source)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func paneTitleTextField(title title: String) -> NSTextField {
    let field = NSTextField(forAutoLayout: ())
    field.backgroundColor = NSColor.clearColor();
    field.font = NSFont.boldSystemFontOfSize(16)
    field.editable = false;
    field.bordered = false;
    field.alignment = .Left;

    field.stringValue = title

    return field
  }

  override func addViews() {
    let paneTitle = paneTitleTextField(title: "General")

    self.addSubview(paneTitle)

    paneTitle.autoPinEdgeToSuperviewEdge(.Top, withInset: 18)
    paneTitle.autoPinEdgeToSuperviewEdge(.Left, withInset: 18)
    paneTitle.autoPinEdgeToSuperviewEdge(.Bottom, withInset: 18)
    paneTitle.autoPinEdgeToSuperviewEdge(.Right, withInset: 18)
  }

  override func subscription(source source: Observable<Any>) -> Disposable {
    return source
      .subscribeNext { event in

    }
  }
}
