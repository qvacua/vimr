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

func == (left: GeneralPrefData, right: GeneralPrefData) -> Bool {
  return left.openNewWindowWhenLaunching == right.openNewWindowWhenLaunching
    && left.openNewWindowOnReactivation == right.openNewWindowOnReactivation
}

func != (left: GeneralPrefData, right: GeneralPrefData) -> Bool {
  return !(left == right)
}

class GeneralPrefPane: PrefPane {

  private var data: GeneralPrefData {
    willSet {
      self.updateViews(newData: newValue)
    }

    didSet {
      self.publish(event: self.data)
    }
  }

  private let openWhenLaunchingCheckbox = NSButton(forAutoLayout: ())
  private let openOnReactivationCheckbox = NSButton(forAutoLayout: ())

  init(source: Observable<Any>, initialData: GeneralPrefData) {
    self.data = initialData
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

    self.openWhenLaunchingCheckbox.boolState = self.data.openNewWindowWhenLaunching
    self.openOnReactivationCheckbox.boolState = self.data.openNewWindowOnReactivation
  }

  override func subscription(source source: Observable<Any>) -> Disposable {
    return source
      .filter { $0 is PrefData }
      .map { ($0 as! PrefData).general }
      .filter { [unowned self] data in data != self.data }
      .subscribeNext { [unowned self] data in self.data = data }
  }

  private func updateViews(newData newData: GeneralPrefData) {
    call(self.openWhenLaunchingCheckbox.boolState = newData.openNewWindowWhenLaunching,
         whenNot: newData.openNewWindowWhenLaunching == self.data.openNewWindowWhenLaunching)

    call(self.openOnReactivationCheckbox.boolState = newData.openNewWindowOnReactivation,
         whenNot: newData.openNewWindowOnReactivation == self.data.openNewWindowOnReactivation)
  }
}

// MARK: - Actions
extension GeneralPrefPane {

  func openUntitledWindowWhenLaunchingAction(sender: NSButton) {
    self.data = GeneralPrefData(openNewWindowWhenLaunching: self.openWhenLaunchingCheckbox.boolState,
                                openNewWindowOnReactivation: self.data.openNewWindowOnReactivation)
  }

  func openUntitledWindowOnReactivation(sender: NSButton) {
    self.data = GeneralPrefData(openNewWindowWhenLaunching: self.data.openNewWindowWhenLaunching,
                                openNewWindowOnReactivation: self.openOnReactivationCheckbox.boolState)
  }
}
