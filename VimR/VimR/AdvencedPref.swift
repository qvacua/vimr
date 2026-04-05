/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import PureLayout

final class AdvancedPref: PrefPane, UiComponent, NSTextFieldDelegate {
  typealias StateType = AppState

  enum Action {
    case setUseInteractiveZsh(Bool)
    case setUseSnapshotUpdate(Bool)
    case setNvimBinary(String)
    case setNvimAppName(String)
    case setConnectionMode(MainWindow.NvimConnectionMode)
  }

  let uuid = UUID()

  override var displayName: String {
    "Advanced"
  }

  override var pinToContainer: Bool {
    true
  }

  required init(context: ReduxContext, state: StateType) {
    self.emit = context.actionEmitter.typedEmit()

    self.useInteractiveZsh = state.mainWindowTemplate.useInteractiveZsh
    self.useSnapshotUpdate = state.useSnapshotUpdate
    self.nvimBinary = state.mainWindowTemplate.nvimBinary
    self.nvimAppName = state.nvimAppName
    self.connectionMode = state.mainWindowTemplate.connectionMode

    super.init(frame: .zero)

    self.addViews()
    self.updateViews()

    context.subscribe(uuid: self.uuid) { state in
      if self.useInteractiveZsh != state.mainWindowTemplate.useInteractiveZsh
        || self.nvimBinary != state.mainWindowTemplate.nvimBinary
        || self.nvimAppName != state.nvimAppName
        || self.useSnapshotUpdate != state.useSnapshotUpdate
        || self.connectionMode != state.mainWindowTemplate.connectionMode
      {
        self.useInteractiveZsh = state.mainWindowTemplate.useInteractiveZsh
        self.nvimBinary = state.mainWindowTemplate.nvimBinary
        self.nvimAppName = state.nvimAppName
        self.useSnapshotUpdate = state.useSnapshotUpdate
        self.connectionMode = state.mainWindowTemplate.connectionMode

        self.updateViews()
      }
    }
  }

  private let emit: (Action) -> Void

  private var useInteractiveZsh: Bool
  private var useSnapshotUpdate: Bool
  private var nvimBinary: String = ""
  private var nvimAppName: String = ""
  private var connectionMode: MainWindow.NvimConnectionMode

  private let useInteractiveZshCheckbox = NSButton(forAutoLayout: ())
  private let useSnapshotUpdateCheckbox = NSButton(forAutoLayout: ())
  private let nvimBinaryField = NSTextField(forAutoLayout: ())
  private let nvimAppNameField = NSTextField(forAutoLayout: ())
  private let connectionModePopup = NSPopUpButton(forAutoLayout: ())

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func windowWillClose() {
    self.nvimBinaryFieldAction()
    self.nvimAppNameFieldAction()
  }

  private func updateViews() {
    self.useSnapshotUpdateCheckbox.boolState = self.useSnapshotUpdate
    self.useInteractiveZshCheckbox.boolState = self.useInteractiveZsh
    self.nvimBinaryField.stringValue = self.nvimBinary
    self.nvimAppNameField.stringValue = self.nvimAppName

    let modeIndex = MainWindow.NvimConnectionMode.allCases
      .firstIndex(of: self.connectionMode) ?? 0
    self.connectionModePopup.selectItem(at: modeIndex)
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

    let nvimBinaryTitle = self.titleTextField(title: "Nvim Binary:")
    let nvimBinaryField = self.nvimBinaryField

    let nvimAppNameTitle = self.titleTextField(title: "NVIM_APPNAME:")
    let nvimAppNameField = self.nvimAppNameField
    let nvimAppNameInfo = self.infoTextField(markdown: #"""
    When set, VimR will set the `NVIM_APPNAME` environment variable to this value by default.
    """#)

    let connectionModeTitle = self.titleTextField(title: "Connection Mode:")
    let connectionModePopup = self.connectionModePopup
    connectionModePopup.removeAllItems()
    connectionModePopup.addItems(withTitles: [
      "Embedded (stdio pipe)",
      "Embedded (socket)",
    ])
    connectionModePopup.target = self
    connectionModePopup.action = #selector(AdvancedPref.connectionModeAction(_:))
    let connectionModeInfo = self.infoTextField(markdown: #"""
    **Embedded (stdio pipe)**: Classic mode. VimR launches nvim and communicates via stdin/stdout.\
    **Embedded (socket)**: VimR launches nvim with `--listen` and connects via Unix socket.\
    Socket mode enables future support for attaching to running servers.
    """#)

    self.addSubview(paneTitle)

    self.addSubview(useSnapshotUpdate)
    self.addSubview(useSnapshotUpdateInfo)
    self.addSubview(useInteractiveZsh)
    self.addSubview(useInteractiveZshInfo)
    self.addSubview(nvimBinaryTitle)
    self.addSubview(nvimBinaryField)
    self.addSubview(nvimAppNameTitle)
    self.addSubview(nvimAppNameField)
    self.addSubview(nvimAppNameInfo)
    self.addSubview(connectionModeTitle)
    self.addSubview(connectionModePopup)
    self.addSubview(connectionModeInfo)

    paneTitle.autoPinEdge(toSuperviewEdge: .top, withInset: 18)
    paneTitle.autoPinEdge(toSuperviewEdge: .left, withInset: 18)
    paneTitle.autoPinEdge(toSuperviewEdge: .right, withInset: 18, relation: .greaterThanOrEqual)

    useSnapshotUpdate.autoPinEdge(.top, to: .bottom, of: paneTitle, withOffset: 18)
    useSnapshotUpdate.autoPinEdge(.left, to: .right, of: nvimAppNameTitle, withOffset: 5)

    useSnapshotUpdateInfo.autoPinEdge(.top, to: .bottom, of: useSnapshotUpdate, withOffset: 5)
    useSnapshotUpdateInfo.autoPinEdge(.left, to: .left, of: useSnapshotUpdate)

    useInteractiveZsh.autoPinEdge(.top, to: .bottom, of: useSnapshotUpdateInfo, withOffset: 18)
    useInteractiveZsh.autoPinEdge(.left, to: .right, of: nvimAppNameTitle, withOffset: 5)

    useInteractiveZshInfo.autoPinEdge(.top, to: .bottom, of: useInteractiveZsh, withOffset: 5)
    useInteractiveZshInfo.autoPinEdge(.left, to: .left, of: useInteractiveZsh)

    nvimBinaryTitle.autoPinEdge(.top, to: .bottom, of: useInteractiveZshInfo, withOffset: 18)
    nvimBinaryTitle.autoPinEdge(.right, to: .right, of: nvimAppNameTitle)
    
    nvimBinaryField.autoAlignAxis(.baseline, toSameAxisOf: nvimBinaryTitle)
    nvimBinaryField.autoPinEdge(.left, to: .right, of: nvimBinaryTitle, withOffset: 5)
    nvimBinaryField.autoSetDimension(.width, toSize: 180, relation: .greaterThanOrEqual)
    nvimBinaryField.autoSetDimension(.width, toSize: 400, relation: .lessThanOrEqual)
    nvimBinaryField.autoPinEdge(
      toSuperviewEdge: .right,
      withInset: 18,
      relation: .greaterThanOrEqual
    )
    NotificationCenter.default.addObserver(
      forName: NSControl.textDidEndEditingNotification,
      object: nvimBinaryField,
      queue: nil
    ) { [weak self] _ in
      Task { @MainActor in self?.nvimBinaryFieldAction() }
    }

    nvimAppNameTitle.autoPinEdge(.top, to: .bottom, of: nvimBinaryField, withOffset: 18)
    nvimAppNameTitle.autoPinEdge(
      toSuperviewEdge: .left,
      withInset: 18,
      relation: .greaterThanOrEqual
    )

    nvimAppNameField.autoAlignAxis(.baseline, toSameAxisOf: nvimAppNameTitle)
    nvimAppNameField.autoPinEdge(.left, to: .right, of: nvimAppNameTitle, withOffset: 5)
    nvimAppNameField.autoSetDimension(.width, toSize: 180)
    NotificationCenter.default.addObserver(
      forName: NSControl.textDidEndEditingNotification,
      object: nvimAppNameField,
      queue: nil
    ) { [weak self] _ in
      Task { @MainActor in self?.nvimAppNameFieldAction() }
    }

    nvimAppNameInfo.autoPinEdge(.top, to: .bottom, of: nvimAppNameField, withOffset: 5)
    nvimAppNameInfo.autoPinEdge(.left, to: .right, of: nvimAppNameTitle, withOffset: 5)

    connectionModeTitle.autoPinEdge(.top, to: .bottom, of: nvimAppNameInfo, withOffset: 18)
    connectionModeTitle.autoPinEdge(.right, to: .right, of: nvimAppNameTitle)

    connectionModePopup.autoAlignAxis(.baseline, toSameAxisOf: connectionModeTitle)
    connectionModePopup.autoPinEdge(.left, to: .right, of: connectionModeTitle, withOffset: 5)

    connectionModeInfo.autoPinEdge(.top, to: .bottom, of: connectionModePopup, withOffset: 5)
    connectionModeInfo.autoPinEdge(.left, to: .left, of: connectionModePopup)
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

  func nvimAppNameFieldAction() {
    let newNvimAppName = self.nvimAppNameField.stringValue
    self.emit(.setNvimAppName(newNvimAppName))
  }

  @objc func connectionModeAction(_ sender: NSPopUpButton) {
    let modes = MainWindow.NvimConnectionMode.allCases
    let index = sender.indexOfSelectedItem
    guard index >= 0, index < modes.count else { return }
    self.emit(.setConnectionMode(modes[index]))
  }
}
