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
    case setUseLiveResize(Bool)
    case setDrawsParallel(Bool)
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
    self.useLiveResize = state.mainWindowTemplate.useLiveResize
    self.drawsParallel = state.mainWindowTemplate.drawsParallel

    super.init(frame: .zero)

    self.addViews()
    self.updateViews()

    source
      .observe(on: MainScheduler.instance)
      .subscribe(onNext: { state in
        if self.useInteractiveZsh != state.mainWindowTemplate.useInteractiveZsh
          || self.useSnapshotUpdate != state.useSnapshotUpdate
          || self.useLiveResize != state.mainWindowTemplate.useLiveResize
          || self.drawsParallel != state.mainWindowTemplate.drawsParallel
        {
          self.useInteractiveZsh = state.mainWindowTemplate.useInteractiveZsh
          self.useSnapshotUpdate = state.useSnapshotUpdate
          self.useLiveResize = state.mainWindowTemplate.useLiveResize
          self.drawsParallel = state.mainWindowTemplate.drawsParallel

          self.updateViews()
        }
      })
      .disposed(by: self.disposeBag)
  }

  private let emit: (Action) -> Void
  private let disposeBag = DisposeBag()

  private var useInteractiveZsh: Bool
  private var useSnapshotUpdate: Bool
  private var useLiveResize: Bool
  private var drawsParallel: Bool

  private let useInteractiveZshCheckbox = NSButton(forAutoLayout: ())
  private let useSnapshotUpdateCheckbox = NSButton(forAutoLayout: ())
  private let useLiveResizeCheckbox = NSButton(forAutoLayout: ())
  private let drawsParallelCheckbox = NSButton(forAutoLayout: ())

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func updateViews() {
    self.useSnapshotUpdateCheckbox.boolState = self.useSnapshotUpdate
    self.useInteractiveZshCheckbox.boolState = self.useInteractiveZsh
    self.useLiveResizeCheckbox.boolState = self.useLiveResize
    self.drawsParallelCheckbox.boolState = self.drawsParallel
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

    let useLiveResize = self.useLiveResizeCheckbox
    self.configureCheckbox(
      button: useLiveResize,
      title: "Use Live Window Resizing",
      action: #selector(AdvancedPref.useLiveResizeAction(_:))
    )

    let useLiveResizeInfo = self.infoTextField(markdown: #"""
    The Live Resizing is yet experimental. You may experience some issues.\
    If you do, please report them at [GitHub](https://github.com/qvacua/vimr/issues).
    """#)

    let drawsParallelBox = self.drawsParallelCheckbox
    self.configureCheckbox(
      button: drawsParallelBox,
      title: "Use Concurrent Rendering",
      action: #selector(AdvancedPref.drawParallelAction(_:))
    )

    let drawsParallelInfo = self.infoTextField(markdown: #"""
    VimR can compute the glyphs concurrently. This may result in faster rendering,\
    depending on the situation. It will definitely result in higher CPU usage, e.g.\
    when scrolling very fast.
    """#)

    self.addSubview(paneTitle)

    self.addSubview(useSnapshotUpdate)
    self.addSubview(useSnapshotUpdateInfo)
    self.addSubview(useInteractiveZsh)
    self.addSubview(useInteractiveZshInfo)
    self.addSubview(useLiveResize)
    self.addSubview(useLiveResizeInfo)
    self.addSubview(drawsParallelBox)
    self.addSubview(drawsParallelInfo)

    paneTitle.autoPinEdge(toSuperviewEdge: .top, withInset: 18)
    paneTitle.autoPinEdge(toSuperviewEdge: .left, withInset: 18)
    paneTitle.autoPinEdge(toSuperviewEdge: .right, withInset: 18, relation: .greaterThanOrEqual)

    useLiveResize.autoPinEdge(.top, to: .bottom, of: paneTitle, withOffset: 18)
    useLiveResize.autoPinEdge(toSuperviewEdge: .left, withInset: 18)

    useLiveResizeInfo.autoPinEdge(.top, to: .bottom, of: useLiveResize, withOffset: 5)
    useLiveResizeInfo.autoPinEdge(.left, to: .left, of: useLiveResize)

    drawsParallelBox.autoPinEdge(.top, to: .bottom, of: useLiveResizeInfo, withOffset: 18)
    drawsParallelBox.autoPinEdge(.left, to: .left, of: useLiveResize, withOffset: 5)

    drawsParallelInfo.autoPinEdge(.top, to: .bottom, of: drawsParallelBox, withOffset: 5)
    drawsParallelInfo.autoPinEdge(.left, to: .left, of: drawsParallelBox)

    useSnapshotUpdate.autoPinEdge(.top, to: .bottom, of: drawsParallelInfo, withOffset: 18)
    useSnapshotUpdate.autoPinEdge(.left, to: .left, of: useLiveResize, withOffset: 5)

    useSnapshotUpdateInfo.autoPinEdge(.top, to: .bottom, of: useSnapshotUpdate, withOffset: 5)
    useSnapshotUpdateInfo.autoPinEdge(.left, to: .left, of: useSnapshotUpdate)

    useInteractiveZsh.autoPinEdge(.top, to: .bottom, of: useSnapshotUpdateInfo, withOffset: 18)
    useInteractiveZsh.autoPinEdge(.left, to: .left, of: useLiveResize, withOffset: 5)

    useInteractiveZshInfo.autoPinEdge(.top, to: .bottom, of: useInteractiveZsh, withOffset: 5)
    useInteractiveZshInfo.autoPinEdge(.left, to: .left, of: useInteractiveZsh)
  }
}

// MARK: - Actions

extension AdvancedPref {
  @objc func useLiveResizeAction(_ sender: NSButton) {
    self.emit(.setUseLiveResize(sender.boolState))
  }

  @objc func drawParallelAction(_ sender: NSButton) {
    self.emit(.setDrawsParallel(sender.boolState))
  }

  @objc func useInteractiveZshAction(_ sender: NSButton) {
    self.emit(.setUseInteractiveZsh(sender.boolState))
  }

  @objc func useSnapshotUpdateChannelAction(_ sender: NSButton) {
    self.emit(.setUseSnapshotUpdate(sender.boolState))
  }
}
