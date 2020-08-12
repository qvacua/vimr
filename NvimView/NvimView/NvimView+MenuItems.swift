/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import RxSwift

// MARK: - NSUserInterfaceValidationsProtocol
extension NvimView {

  public func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
    let canUndoOrRedo = self.mode == .insert
                        || self.mode == .replace
                        || self.mode == .normal
                        || self.mode == .visual
    let canCopyOrCut = self.mode == .normal || self.mode == .visual
    let canPaste = NSPasteboard.general.string(forType: .string) != nil
    let canDelete = self.mode == .visual || self.mode == .normal
    let canSelectAll = self.mode == .insert
                       || self.mode == .replace
                       || self.mode == .normal
                       || self.mode == .visual

    guard let action = item.action else {
      return true
    }

    switch action {
    case #selector(undo(_:)), #selector(redo(_:)):
      return canUndoOrRedo
    case #selector(copy(_:)), #selector(cut(_:)):
      return canCopyOrCut
    case #selector(paste(_:)):
      return canPaste
    case #selector(delete(_:)):
      return canDelete
    case #selector(selectAll(_:)):
      return canSelectAll
    default:
      return true
    }
  }
}

// MARK: - Edit Menu Items
extension NvimView {

  @IBAction func undo(_ sender: Any?) {
    switch self.mode {
    case .insert, .replace:
      self.api
        .input(keys: "<Esc>ui", errWhenBlocked: false)
        .subscribe(onError: { error in
          self.eventsSubject.onNext(.apiError(msg: "Could not undo", cause: error))
        })
        .disposed(by: self.disposeBag)
    case .normal, .visual:
      self.api
        .input(keys: "u", errWhenBlocked: false)
        .subscribe(onError: { error in
          self.eventsSubject.onNext(.apiError(msg: "Could not undo", cause: error))
        })
        .disposed(by: self.disposeBag)
    default:
      return
    }
  }

  @IBAction func redo(_ sender: Any?) {
    switch self.mode {
    case .insert, .replace:
      self.api
        .input(keys: "<Esc><C-r>i", errWhenBlocked: false)
        .subscribe(onError: { error in
          self.eventsSubject.onNext(.apiError(msg: "Could not redo", cause: error))
        })
        .disposed(by: self.disposeBag)
    case .normal, .visual:
      self.api
        .input(keys: "<C-r>", errWhenBlocked: false)
        .subscribe(onError: { error in
          self.eventsSubject.onNext(.apiError(msg: "Could not redo", cause: error))
        })
        .disposed(by: self.disposeBag)
    default:
      return
    }
  }

  @IBAction func cut(_ sender: Any?) {
    switch self.mode {
    case .visual, .normal:
      self.api
        .input(keys: "\"+d", errWhenBlocked: false)
        .subscribe(onError: { error in
          self.eventsSubject.onNext(.apiError(msg: "Could not cut", cause: error))
        })
        .disposed(by: self.disposeBag)
    default:
      return
    }
  }

  @IBAction func copy(_ sender: Any?) {
    switch self.mode {
    case .visual, .normal:
      self.api
        .input(keys: "\"+y", errWhenBlocked: false)
        .subscribe(onError: { error in
          self.eventsSubject.onNext(.apiError(msg: "Could not copy", cause: error))
        })
        .disposed(by: self.disposeBag)
    default:
      return
    }
  }

  @IBAction func paste(_ sender: Any?) {
    guard let content = NSPasteboard.general.string(forType: .string) else {
      return
    }

    if self.mode == .cmdlineNormal || self.mode == .cmdlineInsert || self.mode == .cmdlineReplace
       || self.mode == .replace
       || self.mode == .termFocus {
      self.api
        .input(keys: self.vimPlainString(content), errWhenBlocked: false)
        .subscribe(onError: { error in
          self.eventsSubject.onNext(.apiError(msg: "Could not paste \(content)", cause: error))
        })
        .disposed(by: self.disposeBag)
      return
    }

    Single.zip(
        self.api
          .getCurrentWin()
          .flatMap { win in self.api.winGetCursor(window: win) },
        self.api
          .getOption(name: "paste")
          .flatMap { curPasteMode -> Single<Bool> in
            if curPasteMode == false {
              return self.api
                .setOption(name: "paste", value: .bool(true))
                .andThen(Single.just(true))
            } else {
              return Single.just(false)
            }
          }
      )
      .map { result in (column: result.0[1], pasteModeSet: result.1) }
      .flatMap { element -> Single<Bool> in
        switch self.mode {

        case .insert:
          let cmd = element.column == 0 ? "<ESC>\"+Pa" : "<ESC>\"+pa"
          return self.api
            .input(keys: cmd, errWhenBlocked: false).asCompletable()
            .andThen(Single.just(element.pasteModeSet))

        case .normal, .visual:
          return self.api
            .input(keys: "\"+p", errWhenBlocked: false).asCompletable()
            .andThen(Single.just(element.pasteModeSet))

        default:
          return Single.just(element.pasteModeSet)

        }
      }
      .flatMapCompletable { pasteModeSet -> Completable in
        if pasteModeSet {
          return self.api.setOption(name: "paste", value: .bool(false))
        }

        return Completable.empty()
      }
      .subscribe(onError: { error in
        self.eventsSubject.onNext(.apiError(msg: "There was an pasting.", cause: error))
      })
      .disposed(by: self.disposeBag)
  }

  @IBAction func delete(_ sender: Any?) {
    switch self.mode {
    case .normal, .visual:
      self.api
        .input(keys: "x", errWhenBlocked: false)
        .subscribe(onError: { error in
          self.eventsSubject.onNext(.apiError(msg: "Could not delete", cause: error))
        })
        .disposed(by: self.disposeBag)
    default:
      return
    }
  }

  @IBAction public override func selectAll(_ sender: Any?) {
    switch self.mode {
    case .insert, .visual:
      self.api
        .input(keys: "<Esc>ggVG", errWhenBlocked: false)
        .subscribe(onError: { error in
          self.eventsSubject.onNext(.apiError(msg: "Could not select all", cause: error))
        })
        .disposed(by: self.disposeBag)
    default:
      self.api
        .input(keys: "ggVG", errWhenBlocked: false)
        .subscribe(onError: { error in
          self.eventsSubject.onNext(.apiError(msg: "Could not select all", cause: error))
        })
        .disposed(by: self.disposeBag)
    }
  }
}

// MARK: - Font Menu Items
extension NvimView {

  @IBAction func resetFontSize(_ sender: Any?) {
    self.font = self._font
  }

  @IBAction func makeFontBigger(_ sender: Any?) {
    let curFont = self.drawer.font
    let font = NSFontManager.shared
      .convert(curFont, toSize: min(curFont.pointSize + 1, NvimView.maxFontSize))
    self.updateFontMetaData(font)
  }

  @IBAction func makeFontSmaller(_ sender: Any?) {
    let curFont = self.drawer.font
    let font = NSFontManager.shared
      .convert(curFont, toSize: max(curFont.pointSize - 1, NvimView.minFontSize))
    self.updateFontMetaData(font)
  }
}
