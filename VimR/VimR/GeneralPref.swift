/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import PureLayout
import RxSwift

class GeneralPref: PrefPane, UiComponent, NSTextFieldDelegate {
  typealias StateType = AppState

  enum Action {
    case setOpenOnLaunch(Bool)
    case setOpenFilesFromApplications(AppState.OpenFilesFromApplicationsAction)
    case setAfterLastWindowAction(AppState.AfterLastWindowAction)
    case setActivateAsciiImInNormalModeAction(Bool)
    case setOpenOnReactivation(Bool)
    case setDefaultUsesVcsIgnores(Bool)
  }

  override var displayName: String { "General" }
  override var pinToContainer: Bool { true }

  required init(source: Observable<StateType>, emitter: ActionEmitter, state: StateType) {
    self.emit = emitter.typedEmit()

    super.init(frame: .zero)

    self.addViews()

    self.openWhenLaunchingCheckbox.boolState = state.openNewMainWindowOnLaunch
    self.activateAsciiImInNormalModeCheckbox.boolState = state.activateAsciiImInNormalMode
    self.openOnReactivationCheckbox.boolState = state.openNewMainWindowOnReactivation
    self.defaultUsesVcsIgnoresCheckbox.boolState = state.openQuickly.defaultUsesVcsIgnores

    self.openFilesFromApplicationsAction = state.openFilesFromApplicationsAction
    self.openFilesFromApplicationsPopup
      .selectItem(
        at: AppState.OpenFilesFromApplicationsAction.allCases
          .firstIndex(of: state.openFilesFromApplicationsAction) ?? 0
      )

    self.lastWindowAction = state.afterLastWindowAction
    self.afterLastWindowPopup
      .selectItem(at: indexToAfterLastWindowAction.firstIndex(of: state.afterLastWindowAction) ?? 0)

    source
      .observe(on: MainScheduler.instance)
      .subscribe(onNext: { state in
        if self.openWhenLaunchingCheckbox.boolState != state.openNewMainWindowOnLaunch {
          self.openWhenLaunchingCheckbox.boolState = state.openNewMainWindowOnLaunch
        }

        if self.openOnReactivationCheckbox.boolState != state.openNewMainWindowOnReactivation {
          self.openOnReactivationCheckbox.boolState = state.openNewMainWindowOnReactivation
        }

        if self.openFilesFromApplicationsAction != state.openFilesFromApplicationsAction {
          self.openFilesFromApplicationsPopup.selectItem(
            at: AppState.OpenFilesFromApplicationsAction.allCases
              .firstIndex(of: state.openFilesFromApplicationsAction) ?? 0
          )
          self.openFilesFromApplicationsAction = state.openFilesFromApplicationsAction
        }

        if self.lastWindowAction != state.afterLastWindowAction {
          self.afterLastWindowPopup.selectItem(
            at: indexToAfterLastWindowAction.firstIndex(of: state.afterLastWindowAction) ?? 0
          )
        }
        self.lastWindowAction = state.afterLastWindowAction
      })
      .disposed(by: self.disposeBag)
  }

  private let emit: (Action) -> Void
  private let disposeBag = DisposeBag()

  private var openFilesFromApplicationsAction = AppState.OpenFilesFromApplicationsAction.inNewWindow
  private var lastWindowAction = AppState.AfterLastWindowAction.doNothing

  private let activateAsciiImInNormalModeCheckbox = NSButton(forAutoLayout: ())
  private let openWhenLaunchingCheckbox = NSButton(forAutoLayout: ())
  private let openOnReactivationCheckbox = NSButton(forAutoLayout: ())
  private let defaultUsesVcsIgnoresCheckbox = NSButton(forAutoLayout: ())

  private let openFilesFromApplicationsPopup = NSPopUpButton(forAutoLayout: ())
  private let afterLastWindowPopup = NSPopUpButton(forAutoLayout: ())

  @available(*, unavailable)
  required init?(coder _: NSCoder) { fatalError("init(coder:) has not been implemented") }

  private func addViews() {
    let paneTitle = self.paneTitleTextField(title: "General")

    let openUntitledWindowTitle = self.titleTextField(title: "Open Untitled Window:")
    self.configureCheckbox(
      button: self.openWhenLaunchingCheckbox,
      title: "On launch",
      action: #selector(GeneralPref.openUntitledWindowWhenLaunchingAction)
    )
    self.configureCheckbox(
      button: self.openOnReactivationCheckbox,
      title: "On re-activation",
      action: #selector(GeneralPref.openUntitledWindowOnReactivationAction)
    )
    self.configureCheckbox(
      button: self.defaultUsesVcsIgnoresCheckbox,
      title: "Use VCS Ignores",
      action: #selector(GeneralPref.defaultUsesVcsIgnoresAction)
    )

    let whenLaunching = self.openWhenLaunchingCheckbox
    let onReactivation = self.openOnReactivationCheckbox

    let openFilesFromApplicationsTitle = self.titleTextField(title: "Open files from applications:")
    self.openFilesFromApplicationsPopup.target = self
    self.openFilesFromApplicationsPopup
      .action = #selector(GeneralPref.afterOpenFilesFromApplicationsAction)
    self.openFilesFromApplicationsPopup.addItems(withTitles: [
      "In a New Window",
      "In the Current Window",
    ])
    let openFilesFromApplicationsInfo =
      self.infoTextField(markdown: #"""
      This applies to files opened from the Finder \
      (e.g. by double-clicking on a file or by dragging a file onto the VimR dock icon) \
      or from external programs such as Xcode.
      """#)

    let afterLastWindowTitle = self.titleTextField(title: "After Last Window Closes:")
    let lastWindow = self.afterLastWindowPopup
    lastWindow.target = self
    lastWindow.action = #selector(GeneralPref.afterLastWindowAction)
    lastWindow.addItems(withTitles: [
      "Do Nothing",
      "Hide",
      "Quit",
    ])

    let activateAsciiImTitle = self.titleTextField(title: "When entering Normal Mode:")
    self.configureCheckbox(
      button: self.activateAsciiImInNormalModeCheckbox,
      title: "Activate ASCII-compatible Input Method",
      action: #selector(GeneralPref.activateAsciiImInNormalModeAction)
    )
    let asciiIm = self.activateAsciiImInNormalModeCheckbox
    let asciiInfo =
      self.infoTextField(markdown: #"""
      When checked, VimR will automatically select the last ASCII-compatible input method\
      when you enter Normal mode. When you re-enter Insert mode, VimR will select\
      the last input method used in the Insert mode.
      """#)

    let ignoreListTitle = self.titleTextField(title: "Open Quickly:")
    let ignoreInfo =
      self.infoTextField(markdown: #"""
      When checked, the ignore files of VCSs, e.g. `gitignore`, will we used to ignore files.\
      This checkbox will set the initial value for each VimR window.\
      You can change this setting for each VimR window in the Open Quickly window.
      """#)

    let cliToolTitle = self.titleTextField(title: "CLI Tool:")
    let cliToolButton = NSButton(forAutoLayout: ())
    cliToolButton.title = "Copy 'vimr' CLI Tool..."
    cliToolButton.bezelStyle = .rounded
    cliToolButton.isBordered = true
    cliToolButton.setButtonType(.momentaryPushIn)
    cliToolButton.target = self
    cliToolButton.action = #selector(GeneralPref.copyCliTool(_:))
    let cliToolInfo = self.infoTextField(
      markdown: #"""
      Put the executable `vimr` in your `$PATH` and execute `vimr -h` for help.\
      You need `python3` executable in your `$PATH`.
      """#
    )

    let vcsIg = self.defaultUsesVcsIgnoresCheckbox

    self.addSubview(paneTitle)
    self.addSubview(openUntitledWindowTitle)
    self.addSubview(whenLaunching)
    self.addSubview(onReactivation)

    self.addSubview(vcsIg)
    self.addSubview(ignoreListTitle)
    self.addSubview(ignoreInfo)

    self.addSubview(openFilesFromApplicationsTitle)
    self.addSubview(self.openFilesFromApplicationsPopup)
    self.addSubview(openFilesFromApplicationsInfo)

    self.addSubview(afterLastWindowTitle)
    self.addSubview(lastWindow)

    self.addSubview(activateAsciiImTitle)
    self.addSubview(asciiIm)
    self.addSubview(asciiInfo)

    self.addSubview(cliToolTitle)
    self.addSubview(cliToolButton)
    self.addSubview(cliToolInfo)

    paneTitle.autoPinEdge(toSuperviewEdge: .top, withInset: 18)
    paneTitle.autoPinEdge(toSuperviewEdge: .left, withInset: 18)
    paneTitle.autoPinEdge(toSuperviewEdge: .right, withInset: 18, relation: .greaterThanOrEqual)

    openUntitledWindowTitle.autoAlignAxis(.baseline, toSameAxisOf: whenLaunching, withOffset: 0)
    openUntitledWindowTitle.autoPinEdge(.right, to: .right, of: afterLastWindowTitle)
    openUntitledWindowTitle.autoPinEdge(
      toSuperviewEdge: .left,
      withInset: 18,
      relation: .greaterThanOrEqual
    )

    whenLaunching.autoPinEdge(.top, to: .bottom, of: paneTitle, withOffset: 18)
    whenLaunching.autoPinEdge(.left, to: .right, of: openUntitledWindowTitle, withOffset: 5)
    whenLaunching.autoPinEdge(toSuperviewEdge: .right, withInset: 18, relation: .greaterThanOrEqual)

    onReactivation.autoPinEdge(.top, to: .bottom, of: whenLaunching, withOffset: 5)
    onReactivation.autoPinEdge(.left, to: .left, of: whenLaunching)
    onReactivation.autoPinEdge(
      toSuperviewEdge: .right,
      withInset: 18,
      relation: .greaterThanOrEqual
    )

    openFilesFromApplicationsTitle.autoAlignAxis(
      .baseline,
      toSameAxisOf: self.openFilesFromApplicationsPopup
    )
    openFilesFromApplicationsTitle.autoPinEdge(.right, to: .right, of: openUntitledWindowTitle)
    openFilesFromApplicationsTitle.autoPinEdge(
      toSuperviewEdge: .left,
      withInset: 18,
      relation: .greaterThanOrEqual
    )
    self.openFilesFromApplicationsPopup.autoPinEdge(
      .top,
      to: .bottom,
      of: onReactivation,
      withOffset: 18
    )
    self.openFilesFromApplicationsPopup.autoPinEdge(
      .left,
      to: .right,
      of: openFilesFromApplicationsTitle,
      withOffset: 5
    )
    openFilesFromApplicationsInfo.autoPinEdge(
      .top,
      to: .bottom,
      of: self.openFilesFromApplicationsPopup,
      withOffset: 5
    )
    openFilesFromApplicationsInfo.autoPinEdge(toSuperviewEdge: .right, withInset: 18)
    openFilesFromApplicationsInfo.autoPinEdge(
      .left,
      to: .left,
      of: self.openFilesFromApplicationsPopup
    )

    afterLastWindowTitle.autoAlignAxis(.baseline, toSameAxisOf: lastWindow)
    afterLastWindowTitle.autoPinEdge(toSuperviewEdge: .left, withInset: 18)
    lastWindow.autoPinEdge(.top, to: .bottom, of: openFilesFromApplicationsInfo, withOffset: 18)
    lastWindow.autoPinEdge(.left, to: .right, of: afterLastWindowTitle, withOffset: 5)

    activateAsciiImTitle.autoAlignAxis(.baseline, toSameAxisOf: asciiIm, withOffset: 0)
    activateAsciiImTitle.autoPinEdge(.right, to: .right, of: afterLastWindowTitle)
    activateAsciiImTitle.autoPinEdge(
      toSuperviewEdge: .left,
      withInset: 18,
      relation: .greaterThanOrEqual
    )

    asciiIm.autoPinEdge(.top, to: .bottom, of: lastWindow, withOffset: 18)
    asciiIm.autoPinEdge(.left, to: .right, of: activateAsciiImTitle, withOffset: 5)
    asciiIm.autoPinEdge(toSuperviewEdge: .right, withInset: 18, relation: .greaterThanOrEqual)

    asciiInfo.autoPinEdge(.top, to: .bottom, of: asciiIm, withOffset: 5)
    asciiInfo.autoPinEdge(toSuperviewEdge: .right, withInset: 18)
    asciiInfo.autoPinEdge(.left, to: .left, of: asciiIm)

    ignoreListTitle.autoAlignAxis(.baseline, toSameAxisOf: vcsIg)
    ignoreListTitle.autoPinEdge(.right, to: .right, of: activateAsciiImTitle)
    ignoreListTitle.autoPinEdge(
      toSuperviewEdge: .left,
      withInset: 18,
      relation: .greaterThanOrEqual
    )

    vcsIg.autoPinEdge(.top, to: .bottom, of: asciiInfo, withOffset: 18)
    vcsIg.autoPinEdge(.left, to: .right, of: ignoreListTitle, withOffset: 5)

    ignoreInfo.autoPinEdge(.top, to: .bottom, of: vcsIg, withOffset: 5)
    ignoreInfo.autoPinEdge(toSuperviewEdge: .right, withInset: 18)
    ignoreInfo.autoPinEdge(.left, to: .left, of: vcsIg)

    cliToolTitle.autoAlignAxis(.baseline, toSameAxisOf: cliToolButton)
    cliToolTitle.autoPinEdge(toSuperviewEdge: .left, withInset: 18, relation: .greaterThanOrEqual)
    cliToolTitle.autoPinEdge(.right, to: .right, of: openUntitledWindowTitle)

    cliToolButton.autoPinEdge(.top, to: .bottom, of: ignoreInfo, withOffset: 18)
    cliToolButton.autoPinEdge(toSuperviewEdge: .right, withInset: 18, relation: .greaterThanOrEqual)
    cliToolButton.autoPinEdge(.left, to: .right, of: cliToolTitle, withOffset: 5)

    cliToolInfo.autoPinEdge(.top, to: .bottom, of: cliToolButton, withOffset: 5)
    cliToolInfo.autoPinEdge(toSuperviewEdge: .right, withInset: 18, relation: .greaterThanOrEqual)
    cliToolInfo.autoPinEdge(.left, to: .right, of: cliToolTitle, withOffset: 5)
  }
}

// MARK: - Actions

extension GeneralPref {
  @objc func copyCliTool(_: NSButton) {
    let panel = NSOpenPanel()
    panel.canChooseFiles = false
    panel.canChooseDirectories = true

    panel.beginSheetModal(for: self.window!) { result in
      guard result == .OK else {
        return
      }

      guard let vimrUrl = Bundle.main.url(forResource: "vimr", withExtension: nil) else {
        self.alert(
          title: "Something Went Wrong.",
          info: "The CLI tool 'vimr' could not be found. Please re-download VimR and try again."
        )
        return
      }

      guard let targetUrl = panel.url?.appendingPathComponent("vimr") else {
        self.alert(
          title: "Something Went Wrong.",
          info: "The target directory could not be determined. Please try again with a different directory."
        )
        return
      }

      do {
        try FileManager.default.copyItem(at: vimrUrl, to: targetUrl)
      } catch let err as NSError {
        self.alert(title: "Error copying 'vimr'", info: err.localizedDescription)
      }
    }
  }

  @objc func defaultUsesVcsIgnoresAction(_ sender: NSButton) {
    self.emit(.setDefaultUsesVcsIgnores(sender.boolState))
  }

  @objc func openUntitledWindowWhenLaunchingAction(_: NSButton) {
    self.emit(.setOpenOnLaunch(self.openWhenLaunchingCheckbox.boolState))
  }

  @objc func openUntitledWindowOnReactivationAction(_: NSButton) {
    self.emit(.setOpenOnReactivation(self.openOnReactivationCheckbox.boolState))
  }

  @objc func afterOpenFilesFromApplicationsAction(_ sender: NSPopUpButton) {
    let index = sender.indexOfSelectedItem

    guard AppState.OpenFilesFromApplicationsAction.allCases.indices.contains(index) else {
      return
    }
    self.openFilesFromApplicationsAction = AppState.OpenFilesFromApplicationsAction.allCases[index]
    self.emit(.setOpenFilesFromApplications(self.openFilesFromApplicationsAction))
  }

  @objc func afterLastWindowAction(_ sender: NSPopUpButton) {
    let index = sender.indexOfSelectedItem

    guard index >= 0, index <= 2 else {
      return
    }

    self.lastWindowAction = indexToAfterLastWindowAction[index]
    self.emit(.setAfterLastWindowAction(self.lastWindowAction))
  }

  @objc func activateAsciiImInNormalModeAction(_: NSButton) {
    self.emit(
      .setActivateAsciiImInNormalModeAction(
        self.activateAsciiImInNormalModeCheckbox.boolState
      )
    )
  }

  private func alert(title: String, info: String) {
    let alert = NSAlert()
    alert.alertStyle = .warning
    alert.messageText = title
    alert.informativeText = info
    alert.runModal()
  }
}

private let indexToAfterLastWindowAction: [AppState.AfterLastWindowAction] = [
  .doNothing, .hide, .quit,
]
