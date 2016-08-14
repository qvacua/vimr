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

  private var data: GeneralPrefData

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

    self.updateViews()
  }

  override func subscription(source source: Observable<Any>) -> Disposable {
    return source
      .filter { $0 is GeneralPrefData }
      .map { $0 as! GeneralPrefData }
      .filter { [unowned self] data in data != self.data }
      .subscribeNext { [unowned self] data in
        self.updateViews(newData: data)
        self.data = data
    }
  }

  private func updateViews(newData newValue: GeneralPrefData? = nil) {
    if let newData = newValue {
      if newData.openNewWindowWhenLaunching != self.data.openNewWindowWhenLaunching {
        self.openWhenLaunchingCheckbox.state = newData.openNewWindowWhenLaunching ? NSOnState : NSOffState
      }

      if newData.openNewWindowOnReactivation != self.data.openNewWindowOnReactivation {
        self.openOnReactivationCheckbox.state = newData.openNewWindowOnReactivation ? NSOnState : NSOffState
      }

      return
    }

    self.openWhenLaunchingCheckbox.state = self.data.openNewWindowWhenLaunching ? NSOnState : NSOffState
    self.openOnReactivationCheckbox.state = self.data.openNewWindowOnReactivation ? NSOnState : NSOffState
  }
}

// MARK: - Actions
extension GeneralPrefPane {

  func openUntitledWindowWhenLaunchingAction(sender: NSButton) {
    let whenLaunching = self.openWhenLaunchingCheckbox.state == NSOnState ? true : false
    self.data = GeneralPrefData(openNewWindowWhenLaunching: whenLaunching,
                                openNewWindowOnReactivation: self.data.openNewWindowOnReactivation)

    self.publish(event: self.data)
  }

  func openUntitledWindowOnReactivation(sender: NSButton) {
    let onReactivation = self.openOnReactivationCheckbox.state == NSOnState ? true : false
    self.data = GeneralPrefData(openNewWindowWhenLaunching: self.data.openNewWindowWhenLaunching,
                                openNewWindowOnReactivation: onReactivation)

    self.publish(event: self.data)
  }
}
