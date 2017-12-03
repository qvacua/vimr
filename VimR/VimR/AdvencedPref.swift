/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import PureLayout
import RxSwift

class AdvancedPref: PrefPane, UiComponent, NSTextFieldDelegate {

  typealias StateType = AppState

  enum Action {

    case setUseInteractiveZsh(Bool)
    case setUseSnapshotUpdate(Bool)
  }

  override var displayName: String {
    return "Advanced"
  }

  override var pinToContainer: Bool {
    return true
  }

  required init(source: Observable<StateType>, emitter: ActionEmitter, state: StateType) {
    self.emit = emitter.typedEmit()

    self.useInteractiveZsh = state.mainWindowTemplate.useInteractiveZsh
    self.useSnapshotUpdate = state.useSnapshotUpdate

    super.init(frame: .zero)

    self.addViews()
    self.updateViews()

    source
      .observeOn(MainScheduler.instance)
      .subscribe(onNext: { state in
        if self.useInteractiveZsh != state.mainWindowTemplate.useInteractiveZsh
           || self.useSnapshotUpdate != state.useSnapshotUpdate {
          self.useInteractiveZsh = state.mainWindowTemplate.useInteractiveZsh
          self.useSnapshotUpdate = state.useSnapshotUpdate

          self.updateViews()
        }
      })
      .disposed(by: self.disposeBag)
  }

  fileprivate let emit: (Action) -> Void
  fileprivate let disposeBag = DisposeBag()

  fileprivate var useInteractiveZsh: Bool
  fileprivate var useSnapshotUpdate: Bool

  fileprivate let useInteractiveZshCheckbox = NSButton(forAutoLayout: ())
  fileprivate let useSnapshotUpdateCheckbox = NSButton(forAutoLayout: ())

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  fileprivate func updateViews() {
    self.useSnapshotUpdateCheckbox.boolState = self.useSnapshotUpdate
    self.useInteractiveZshCheckbox.boolState = self.useInteractiveZsh
  }

  fileprivate func addViews() {
    let paneTitle = self.paneTitleTextField(title: "Advanced")

    let useInteractiveZsh = self.useInteractiveZshCheckbox
    self.configureCheckbox(button: useInteractiveZsh,
                           title: "Use interactive mode for zsh",
                           action: #selector(AdvancedPref.useInteractiveZshAction(_:)))

    let useInteractiveZshInfo = self.infoTextField(
      markdown: "If your login shell is `zsh`, when checked, the `-i` option will be used to launch `zsh`.  \n"
                + "Checking this option may break VimR if your `.zshrc` contains complex stuff.  \n"
                + "It may be a good idea to put the `PATH`-settings in `.zshenv` and let this unchecked.  \n"
                + "Use with caution."
    )

    let useSnapshotUpdate = self.useSnapshotUpdateCheckbox
    self.configureCheckbox(button: self.useSnapshotUpdateCheckbox,
                           title: "Use Snapshot Update Channel",
                           action: #selector(AdvancedPref.useSnapshotUpdateChannelAction(_:)))

    let useSnapshotUpdateInfo = self.infoTextField(
      markdown: "If you are adventurous, check this.  \n"
                + "You'll be test driving the newest snapshot builds of VimR in no time!"
    )

    self.addSubview(paneTitle)

    self.addSubview(useSnapshotUpdate)
    self.addSubview(useSnapshotUpdateInfo)
    self.addSubview(useInteractiveZsh)
    self.addSubview(useInteractiveZshInfo)

    paneTitle.autoPinEdge(toSuperviewEdge: .top, withInset: 18)
    paneTitle.autoPinEdge(toSuperviewEdge: .left, withInset: 18)
    paneTitle.autoPinEdge(toSuperviewEdge: .right, withInset: 18, relation: .greaterThanOrEqual)

    useSnapshotUpdate.autoPinEdge(.top, to: .bottom, of: paneTitle, withOffset: 18)
    useSnapshotUpdate.autoPinEdge(toSuperviewEdge: .left, withInset: 18)

    useSnapshotUpdateInfo.autoPinEdge(.top, to: .bottom, of: useSnapshotUpdate, withOffset: 5)
    useSnapshotUpdateInfo.autoPinEdge(toSuperviewEdge: .left, withInset: 18)

    useInteractiveZsh.autoPinEdge(.top, to: .bottom, of: useSnapshotUpdateInfo, withOffset: 18)
    useInteractiveZsh.autoPinEdge(toSuperviewEdge: .left, withInset: 18)

    useInteractiveZshInfo.autoPinEdge(.top, to: .bottom, of: useInteractiveZsh, withOffset: 5)
    useInteractiveZshInfo.autoPinEdge(toSuperviewEdge: .left, withInset: 18)
  }
}

// MARK: - Actions
extension AdvancedPref {

  @objc func useInteractiveZshAction(_ sender: NSButton) {
    self.emit(.setUseInteractiveZsh(sender.boolState))
  }

  @objc func useSnapshotUpdateChannelAction(_ sender: NSButton) {
    self.emit(.setUseSnapshotUpdate(sender.boolState))
  }
}
