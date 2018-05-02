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

  @IBAction func undo(_ sender: AnyObject?) {
    switch self.mode {
    case .insert, .replace:
      self.uiBridge
        .vimInput("<Esc>ui")
        .subscribe(onError: { error in
          self.eventsSubject.onNext(.apiError(msg: "Could not undo", cause: error))
        })
    case .normal, .visual:
      self.uiBridge
        .vimInput("u")
        .subscribe(onError: { error in
          self.eventsSubject.onNext(.apiError(msg: "Could not undo", cause: error))
        })
    default:
      return
    }
  }

  @IBAction func redo(_ sender: AnyObject?) {
    switch self.mode {
    case .insert, .replace:
      self.uiBridge
        .vimInput("<Esc><C-r>i")
        .subscribe(onError: { error in
          self.eventsSubject.onNext(.apiError(msg: "Could not redo", cause: error))
        })
    case .normal, .visual:
      self.uiBridge
        .vimInput("<C-r>")
        .subscribe(onError: { error in
          self.eventsSubject.onNext(.apiError(msg: "Could not redo", cause: error))
        })
    default:
      return
    }
  }

  @IBAction func cut(_ sender: AnyObject?) {
    switch self.mode {
    case .visual, .normal:
      self.uiBridge
        .vimInput("\"+d")
        .subscribe(onError: { error in
          self.eventsSubject.onNext(.apiError(msg: "Could not cut", cause: error))
        })
    default:
      return
    }
  }

  @IBAction func copy(_ sender: AnyObject?) {
    switch self.mode {
    case .visual, .normal:
      self.uiBridge
        .vimInput("\"+y")
        .subscribe(onError: { error in
          self.eventsSubject.onNext(.apiError(msg: "Could not copy", cause: error))
        })
    default:
      return
    }
  }

  @IBAction func paste(_ sender: AnyObject?) {
    guard let content = NSPasteboard.general.string(forType: .string) else {
      return
    }

    if self.mode == .cmdline || self.mode == .cmdlineInsert || self.mode == .cmdlineReplace
       || self.mode == .replace
       || self.mode == .termFocus {
      self.uiBridge
        .vimInput(self.vimPlainString(content))
        .subscribe(onError: { error in
          self.eventsSubject.onNext(.apiError(msg: "Could not paste \(content)", cause: error))
        })
      return
    }

    self.nvim
      .getOption(name: "paste")
      .flatMap { curPasteMode -> Single<Bool> in
        if curPasteMode == false {
          return self.nvim
            .setOption(name: "paste", value: .bool(true))
            .map { _ in true }
        } else {
          return Single.just(false)
        }
      }
      .flatMap { pasteModeSet -> Single<Bool> in
        switch self.mode {

        case .insert:
          return self.uiBridge
            .vimInput("<ESC>\"+pa")
            .andThen(Single.just(pasteModeSet))

        case .normal, .visual:
          return self.uiBridge
            .vimInput("\"+p")
            .andThen(Single.just(pasteModeSet))

        default:
          return Single.just(pasteModeSet)

        }
      }
      .flatMap { pasteModeSet -> Single<Void> in
        if pasteModeSet {
          return self.nvim.setOption(name: "paste", value: .bool(false))
        }

        return Single.just(())
      }
      .subscribe(onError: { error in
        self.eventsSubject.onNext(.apiError(msg: "There was an pasting.", cause: error))
      })
  }

  @IBAction func delete(_ sender: AnyObject?) {
    switch self.mode {
    case .normal, .visual:
      self.uiBridge
        .vimInput("x")
        .subscribe(onError: { error in
          self.eventsSubject.onNext(.apiError(msg: "Could not delete", cause: error))
        })
    default:
      return
    }
  }

  @IBAction public override func selectAll(_ sender: Any?) {
    switch self.mode {
    case .insert, .visual:
      self.uiBridge
        .vimInput("<Esc>ggVG")
        .subscribe(onError: { error in
          self.eventsSubject.onNext(.apiError(msg: "Could not select all", cause: error))
        })
    default:
      self.uiBridge
        .vimInput("ggVG")
        .subscribe(onError: { error in
          self.eventsSubject.onNext(.apiError(msg: "Could not select all", cause: error))
        })
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
