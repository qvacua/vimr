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

  private var openNewWindowWhenLaunching: Bool
  private var openNewWindowOnReactivation: Bool

  private let openWhenLaunchingCheckbox = NSButton(forAutoLayout: ())
  private let openOnReactivationCheckbox = NSButton(forAutoLayout: ())

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
    self.configureCheckbox(button: self.openWhenLaunchingCheckbox,
                           title: "On Launch",
                           action: #selector(GeneralPrefPane.openUntitledWindowWhenLaunchingAction(_:)))
    self.configureCheckbox(button: self.openOnReactivationCheckbox,
                           title: "On Re-Activation",
                           action: #selector(GeneralPrefPane.openUntitledWindowOnReactivation(_:)))

    self.addSubview(paneTitle)

    let whenLaunching = self.openWhenLaunchingCheckbox
    let onReactivation = self.openOnReactivationCheckbox

    self.addSubview(openUntitledWindowTitle)
    self.addSubview(whenLaunching)
    self.addSubview(onReactivation)

    paneTitle.autoPinEdgeToSuperviewEdge(.Top, withInset: 18)
    paneTitle.autoPinEdgeToSuperviewEdge(.Left, withInset: 18)

    openUntitledWindowTitle.autoAlignAxis(.Baseline, toSameAxisOfView: whenLaunching, withOffset: 0)
    openUntitledWindowTitle.autoPinEdgeToSuperviewEdge(.Left, withInset: 18)

    whenLaunching.autoPinEdge(.Top, toEdge: .Bottom, ofView: paneTitle, withOffset: 18)
    whenLaunching.autoPinEdge(.Left, toEdge: .Right, ofView: openUntitledWindowTitle, withOffset: 5)

    onReactivation.autoPinEdge(.Top, toEdge: .Bottom, ofView: whenLaunching, withOffset: 5)
    onReactivation.autoPinEdge(.Left, toEdge: .Left, ofView: whenLaunching)
    onReactivation.autoPinEdgeToSuperviewEdge(.Bottom, withInset: 18)

    self.updateViews()
  }

  override func subscription(source source: Observable<Any>) -> Disposable {
    return source
      .filter { $0 is GeneralPrefData }
      .map { $0 as! GeneralPrefData }
      .filter { [unowned self] data in
        data.openNewWindowWhenLaunching != self.openNewWindowWhenLaunching
          || data.openNewWindowOnReactivation != self.openNewWindowOnReactivation
      }
      .subscribeNext { [unowned self] data in
        self.openNewWindowWhenLaunching = data.openNewWindowWhenLaunching
        self.openNewWindowOnReactivation = data.openNewWindowOnReactivation

        self.updateViews()
    }
  }

  private func updateViews() {
    self.openWhenLaunchingCheckbox.state = self.openNewWindowWhenLaunching ? NSOnState : NSOffState
    self.openOnReactivationCheckbox.state = self.openNewWindowOnReactivation ? NSOnState : NSOffState
  }
}

// MARK: - Actions
extension GeneralPrefPane {

  private func generalPrefData() -> GeneralPrefData {
    return GeneralPrefData(openNewWindowWhenLaunching: self.openNewWindowWhenLaunching,
                           openNewWindowOnReactivation: self.openNewWindowOnReactivation)
  }

  func openUntitledWindowWhenLaunchingAction(sender: NSButton) {
    NSLog("\(#function)")
    self.openNewWindowWhenLaunching = self.openWhenLaunchingCheckbox.state == NSOnState ? true : false
    self.publish(event: generalPrefData())
  }

  func openUntitledWindowOnReactivation(sender: NSButton) {
    NSLog("\(#function)")
    self.openNewWindowOnReactivation = self.openOnReactivationCheckbox.state == NSOnState ? true : false
    self.publish(event: generalPrefData())
  }
}
