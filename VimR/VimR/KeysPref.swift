/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import PureLayout
import RxSwift

class KeysPref: PrefPane, UiComponent, NSTextFieldDelegate {

  typealias StateType = AppState

  enum Action {

    case isLeftOptionMeta(Bool)
    case isRightOptionMeta(Bool)
  }

  override var displayName: String {
    return "Keys"
  }

  override var pinToContainer: Bool {
    return true
  }

  required init(source: Observable<StateType>, emitter: ActionEmitter, state: StateType) {
    self.emit = emitter.typedEmit()

    self.isLeftOptionMeta = state.mainWindowTemplate.isLeftOptionMeta
    self.isRightOptionMeta = state.mainWindowTemplate.isRightOptionMeta

    super.init(frame: .zero)

    self.addViews()
    self.updateViews()

    source
      .observeOn(MainScheduler.instance)
      .subscribe(onNext: { state in
        if self.isLeftOptionMeta != state.mainWindowTemplate.isLeftOptionMeta
        || self.isRightOptionMeta != state.mainWindowTemplate.isRightOptionMeta
        {
          self.isLeftOptionMeta = state.mainWindowTemplate.isLeftOptionMeta
          self.isRightOptionMeta = state.mainWindowTemplate.isRightOptionMeta

          self.updateViews()
        }
      })
      .disposed(by: self.disposeBag)
  }

  private let emit: (Action) -> Void
  private let disposeBag = DisposeBag()

  private var isLeftOptionMeta: Bool
  private var isRightOptionMeta: Bool

  private let isLeftOptionMetaCheckbox = NSButton(forAutoLayout: ())
  private let isRightOptionMetaCheckbox = NSButton(forAutoLayout: ())

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func updateViews() {
    self.isLeftOptionMetaCheckbox.boolState = self.isLeftOptionMeta
    self.isRightOptionMetaCheckbox.boolState = self.isRightOptionMeta
  }

  private func addViews() {
    let paneTitle = self.paneTitleTextField(title: "Keys")

    let isLeftOptionMeta = self.isLeftOptionMetaCheckbox
    self.configureCheckbox(button: isLeftOptionMeta,
                           title: "Use Left Option as Meta",
                           action: #selector(KeysPref.isLeftOptionMetaAction(_:)))

    let isRightOptionMeta = self.isRightOptionMetaCheckbox
    self.configureCheckbox(button: isRightOptionMeta,
                           title: "Use Right Option as Meta",
                           action: #selector(KeysPref.isRightOptionMetaAction(_:)))

    let metaInfo = self.infoTextField(markdown: #"""
    When an Option key is set to Meta, then every input containing the corresponding Option key will\
    be passed through to Neovim. This means that you can use mappings like `<M-1>` in Neovim, but\
    cannot use the corresponding Option key for keyboard shortcuts containing `Option` or to enter\
    special characters like `µ` which is entered by `Option-M` (on the ABC keyboard layout).
    """#)

    self.addSubview(paneTitle)

    self.addSubview(isLeftOptionMeta)
    self.addSubview(isRightOptionMeta)
    self.addSubview(metaInfo)

    paneTitle.autoPinEdge(toSuperviewEdge: .top, withInset: 18)
    paneTitle.autoPinEdge(toSuperviewEdge: .left, withInset: 18)
    paneTitle.autoPinEdge(toSuperviewEdge: .right, withInset: 18, relation: .greaterThanOrEqual)

    isLeftOptionMeta.autoPinEdge(.top, to: .bottom, of: paneTitle, withOffset: 18)
    isLeftOptionMeta.autoPinEdge(toSuperviewEdge: .left, withInset: 18)

    isRightOptionMeta.autoPinEdge(.top, to: .bottom, of: isLeftOptionMeta, withOffset: 5)
    isRightOptionMeta.autoPinEdge(toSuperviewEdge: .left, withInset: 18)

    metaInfo.autoPinEdge(.top, to: .bottom, of: isRightOptionMeta, withOffset: 5)
    metaInfo.autoPinEdge(toSuperviewEdge: .left, withInset: 18)
  }
}

// MARK: - Actions
extension KeysPref {

  @objc func isLeftOptionMetaAction(_ sender: NSButton) {
    self.emit(.isLeftOptionMeta(sender.boolState))
  }

  @objc func isRightOptionMetaAction(_ sender: NSButton) {
    self.emit(.isRightOptionMeta(sender.boolState))
  }
}
