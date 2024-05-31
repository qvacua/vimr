/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import PureLayout
import RxSwift

final class AdvancedPref: PrefPane, UiComponent, NSTextFieldDelegate {
  typealias StateType = AppState

  enum Action {
    case setUseInteractiveZsh(Bool)
    case setUseSnapshotUpdate(Bool)
    case setNvimBinary(String)
  }

  override var displayName: String {
    "Advanced"
  }

  override var pinToContainer: Bool {
    true
  }

  required init(source: Observable<StateType>, emitter: ActionEmitter, state: StateType) {
    self.emit = emitter.typedEmit()

    self.useInteractiveZsh = state.mainWindowTemplate.useInteractiveZsh
    self.useSnapshotUpdate = state.useSnapshotUpdate
    self.nvimBinary = state.mainWindowTemplate.nvimBinary

    super.init(frame: .zero)

    self.addViews()
    self.updateViews()

    source
      .observe(on: MainScheduler.instance)
      .subscribe(onNext: { state in
        if self.useInteractiveZsh != state.mainWindowTemplate.useInteractiveZsh
          || self.nvimBinary != state.mainWindowTemplate.nvimBinary
          || self.useSnapshotUpdate != state.useSnapshotUpdate
        {
          self.useInteractiveZsh = state.mainWindowTemplate.useInteractiveZsh
          self.nvimBinary = state.mainWindowTemplate.nvimBinary
          self.useSnapshotUpdate = state.useSnapshotUpdate

          self.updateViews()
        }
      })
      .disposed(by: self.disposeBag)
  }

  private let emit: (Action) -> Void
  private let disposeBag = DisposeBag()

  private var useInteractiveZsh: Bool
  private var useSnapshotUpdate: Bool
  private var nvimBinary: String = ""

  private let useInteractiveZshCheckbox = NSButton(forAutoLayout: ())
  private let useSnapshotUpdateCheckbox = NSButton(forAutoLayout: ())
  private let nvimBinaryField = NSTextField(forAutoLayout: ())

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func windowWillClose() {
    self.nvimBinaryFieldAction()
  }

  private func updateViews() {
    self.useSnapshotUpdateCheckbox.boolState = self.useSnapshotUpdate
    self.useInteractiveZshCheckbox.boolState = self.useInteractiveZsh
    self.nvimBinaryField.stringValue = self.nvimBinary
  }

  private func addViews() {
    let paneTitle = self.paneTitleTextField(title: "Advanced")

    let useInteractiveZsh = self.useInteractiveZshCheckbox
    self.configureCheckbox(
      button: useInteractiveZsh,
      title: "Use interactive mode for zsh",
      action: #selector(AdvancedPref.useInteractiveZshAction(_:))
    )

    let useInteractiveZshInfo = self.infoTextField(markdown: #"""
    If your login shell is `zsh`, when checked, the `-i` option will be used to launch `zsh`.\
    Checking this option may break VimR if your `.zshrc` contains complex stuff.\
    It may be a good idea to put the `PATH`-settings in `.zshenv` and let this unchecked.\
    *Use with caution.*
    """#)

    let useSnapshotUpdate = self.useSnapshotUpdateCheckbox
    self.configureCheckbox(
      button: self.useSnapshotUpdateCheckbox,
      title: "Use Snapshot Update Channel",
      action: #selector(AdvancedPref.useSnapshotUpdateChannelAction(_:))
    )

    let useSnapshotUpdateInfo = self.infoTextField(markdown: #"""
    If you are adventurous, check this. You'll be test driving the newest snapshot builds\
    of VimR in no time!
    """#)

    let nvimBinaryTitle = self.titleTextField(title: "NeoVim Binary:")
    let nvimBinaryField = self.nvimBinaryField

    self.addSubview(paneTitle)

    self.addSubview(useSnapshotUpdate)
    self.addSubview(useSnapshotUpdateInfo)
    self.addSubview(useInteractiveZsh)
    self.addSubview(useInteractiveZshInfo)
    self.addSubview(nvimBinaryTitle)
    self.addSubview(nvimBinaryField)

    paneTitle.autoPinEdge(toSuperviewEdge: .top, withInset: 18)
    paneTitle.autoPinEdge(toSuperviewEdge: .left, withInset: 18)
    paneTitle.autoPinEdge(toSuperviewEdge: .right, withInset: 18, relation: .greaterThanOrEqual)

    useSnapshotUpdate.autoPinEdge(.top, to: .bottom, of: paneTitle, withOffset: 18)
    useSnapshotUpdate.autoPinEdge(.left, to: .left, of: paneTitle)

    useSnapshotUpdateInfo.autoPinEdge(.top, to: .bottom, of: useSnapshotUpdate, withOffset: 5)
    useSnapshotUpdateInfo.autoPinEdge(.left, to: .left, of: useSnapshotUpdate)

    useInteractiveZsh.autoPinEdge(.top, to: .bottom, of: useSnapshotUpdateInfo, withOffset: 18)
    useInteractiveZsh.autoPinEdge(.left, to: .left, of: useSnapshotUpdate)

    useInteractiveZshInfo.autoPinEdge(.top, to: .bottom, of: useInteractiveZsh, withOffset: 5)
    useInteractiveZshInfo.autoPinEdge(.left, to: .left, of: useInteractiveZsh)

    nvimBinaryTitle.autoPinEdge(.top, to: .bottom, of: useInteractiveZshInfo, withOffset: 18)
    nvimBinaryTitle.autoPinEdge(.left, to: .left, of: useSnapshotUpdate)
    // nvimBinaryTitle.autoAlignAxis(.baseline, toSameAxisOf: nvimBinaryField)

    nvimBinaryField.autoPinEdge(.top, to: .bottom, of: useInteractiveZshInfo, withOffset: 18)
    nvimBinaryField.autoPinEdge(.left, to: .right, of: nvimBinaryTitle)
    nvimBinaryField.autoPinEdge(toSuperviewEdge: .right, withInset: 18)
    nvimBinaryField.autoSetDimension(.height, toSize: 20, relation: .greaterThanOrEqual)
    NotificationCenter.default.addObserver(
      forName: NSControl.textDidEndEditingNotification,
      object: nvimBinaryField,
      queue: nil
    ) { [weak self] _ in self?.nvimBinaryFieldAction() }
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

  func nvimBinaryFieldAction() {
    let newNvimBinary = self.nvimBinaryField.stringValue
    self.emit(.setNvimBinary(newNvimBinary))
  }
}
