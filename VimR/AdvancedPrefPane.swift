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

  override var pinToContainer: Bool {
    return true
  }

  private var data: AdvancedPrefData

  private let useInteractiveZshCheckbox = NSButton(forAutoLayout: ())

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

    paneTitle.autoPinEdgeToSuperviewEdge(.Top, withInset: 18)
    paneTitle.autoPinEdgeToSuperviewEdge(.Left, withInset: 18)
    paneTitle.autoPinEdgeToSuperviewEdge(.Right, withInset: 18, relation: .GreaterThanOrEqual)

    useInteractiveZsh.autoPinEdge(.Top, toEdge: .Bottom, ofView: paneTitle, withOffset: 18)
    useInteractiveZsh.autoPinEdgeToSuperviewEdge(.Left, withInset: 18)

    useInteractiveZshInfo.autoPinEdge(.Top, toEdge: .Bottom, ofView: useInteractiveZsh, withOffset: 5)
    useInteractiveZshInfo.autoPinEdgeToSuperviewEdge(.Left, withInset: 18)

    useInteractiveZsh.boolState = self.data.useInteractiveZsh
  }

  override func subscription(source source: Observable<Any>) -> Disposable {
    return source
      .filter { $0 is PrefData }
      .map { ($0 as! PrefData).advanced }
      .filter { [unowned self] data in data != self.data }
      .subscribeNext { [unowned self] data in
        self.updateViews(newData: data)
        self.data = data
    }
  }

  private func set(data data: AdvancedPrefData) {
    self.data = data
    self.publish(event: data)
  }

  private func updateViews(newData newData: AdvancedPrefData) {
    self.useInteractiveZshCheckbox.boolState = newData.useInteractiveZsh
  }
}

// MARK: - Actions
extension AdvancedPrefPane {

  func useInteractiveZshAction(sender: NSButton) {
    self.set(data: AdvancedPrefData(useInteractiveZsh: self.useInteractiveZshCheckbox.boolState))
  }
}


