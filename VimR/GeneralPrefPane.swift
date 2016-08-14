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

  override func addViews() {
    let paneTitle = paneTitleTextField(title: "General")

    let openUntitledWindowTitle = titleTextField(title: "Open Untitled Window:")
    let openWhenLaunching = self.checkbox(title: "On Launch",
                                          action: #selector(GeneralPrefPane.openUntitledWindowWhenLaunchingAction(_:)))
    let openOnReactivation = self.checkbox(title: "On Re-Activation",
                                           action: #selector(GeneralPrefPane.openUntitledWindowOnReactivation(_:)))

    self.addSubview(paneTitle)

    self.addSubview(openUntitledWindowTitle)
    self.addSubview(openWhenLaunching)
    self.addSubview(openOnReactivation)

    paneTitle.autoPinEdgeToSuperviewEdge(.Top, withInset: 18)
    paneTitle.autoPinEdgeToSuperviewEdge(.Left, withInset: 18)

    openUntitledWindowTitle.autoAlignAxis(.Baseline, toSameAxisOfView: openWhenLaunching, withOffset: 0)
    openUntitledWindowTitle.autoPinEdgeToSuperviewEdge(.Left, withInset: 18)

    openWhenLaunching.autoPinEdge(.Top, toEdge: .Bottom, ofView: paneTitle, withOffset: 18)
    openWhenLaunching.autoPinEdge(.Left, toEdge: .Right, ofView: openUntitledWindowTitle, withOffset: 5)

    openOnReactivation.autoPinEdge(.Top, toEdge: .Bottom, ofView: openWhenLaunching, withOffset: 5)
    openOnReactivation.autoPinEdge(.Left, toEdge: .Left, ofView: openWhenLaunching)
    openOnReactivation.autoPinEdgeToSuperviewEdge(.Bottom, withInset: 18)
  }

  override func subscription(source source: Observable<Any>) -> Disposable {
    return source
      .subscribeNext { event in

    }
  }

  private func updateViews() {

  }
}

// MARK: - Actions
extension GeneralPrefPane {

  func openUntitledWindowWhenLaunchingAction(sender: NSButton) {

  }

  func openUntitledWindowOnReactivation(sender: NSButton) {

  }
}
