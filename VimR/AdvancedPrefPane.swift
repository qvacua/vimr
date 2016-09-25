/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import PureLayout
import RxSwift

struct AdvancedPrefData: Equatable {
  let useInteractiveZsh: Bool
}

func == (left: AdvancedPrefData, right: AdvancedPrefData) -> Bool {
  return left.useInteractiveZsh == right.useInteractiveZsh
}

class AdvancedPrefPane: PrefPane {

  override var displayName: String {
    return "Advanced"
  }

  override var pinToContainer: Bool {
    return true
  }

  fileprivate var data: AdvancedPrefData

  fileprivate let useInteractiveZshCheckbox = NSButton(forAutoLayout: ())

  init(source: Observable<Any>, initialData: AdvancedPrefData) {
    self.data = initialData
    super.init(source: source)

    self.updateViews(newData: initialData)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func addViews() {
    let paneTitle = self.paneTitleTextField(title: "Advanced")

    self.configureCheckbox(button: self.useInteractiveZshCheckbox,
                           title: "Use interactive mode for zsh",
                           action: #selector(AdvancedPrefPane.useInteractiveZshAction(_:)))

    let useInteractiveZsh = self.useInteractiveZshCheckbox
    let useInteractiveZshInfo = self.infoTextField(
      text: "If your login shell is zsh, when checked, the '-i' option will be used to launch zsh.\n"
        + "Checking this option may break VimR if your .zshrc contains complex stuff.\n"
        + "It may be a good idea to put the PATH-settings in .zshenv and let this unchecked.\n"
        + "Use with caution."
    )

    self.addSubview(paneTitle)
    self.addSubview(useInteractiveZsh)
    self.addSubview(useInteractiveZshInfo)

    paneTitle.autoPinEdge(toSuperviewEdge: .top, withInset: 18)
    paneTitle.autoPinEdge(toSuperviewEdge: .left, withInset: 18)
    paneTitle.autoPinEdge(toSuperviewEdge: .right, withInset: 18, relation: .greaterThanOrEqual)

    useInteractiveZsh.autoPinEdge(.top, to: .bottom, of: paneTitle, withOffset: 18)
    useInteractiveZsh.autoPinEdge(toSuperviewEdge: .left, withInset: 18)

    useInteractiveZshInfo.autoPinEdge(.top, to: .bottom, of: useInteractiveZsh, withOffset: 5)
    useInteractiveZshInfo.autoPinEdge(toSuperviewEdge: .left, withInset: 18)

    useInteractiveZsh.boolState = self.data.useInteractiveZsh
  }

  override func subscription(source: Observable<Any>) -> Disposable {
    return source
      .filter { $0 is PrefData }
      .map { ($0 as! PrefData).advanced }
      .filter { [unowned self] data in data != self.data }
      .subscribe(onNext: { [unowned self] data in
        self.updateViews(newData: data)
        self.data = data
    })
  }

  fileprivate func set(data: AdvancedPrefData) {
    self.data = data
    self.publish(event: data)
  }

  fileprivate func updateViews(newData: AdvancedPrefData) {
    self.useInteractiveZshCheckbox.boolState = newData.useInteractiveZsh
  }
}

// MARK: - Actions
extension AdvancedPrefPane {

  func useInteractiveZshAction(_ sender: NSButton) {
    self.set(data: AdvancedPrefData(useInteractiveZsh: self.useInteractiveZshCheckbox.boolState))
  }
}


