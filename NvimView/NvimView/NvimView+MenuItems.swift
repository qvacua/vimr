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
      self.uiBridge.vimInput("<Esc>ui")
    case .normal, .visual:
      self.uiBridge.vimInput("u")
    default:
      return
    }
  }

  @IBAction func redo(_ sender: AnyObject?) {
    switch self.mode {
    case .insert, .replace:
      self.uiBridge.vimInput("<Esc><C-r>i")
    case .normal, .visual:
      self.uiBridge.vimInput("<C-r>")
    default:
      return
    }
  }

  @IBAction func cut(_ sender: AnyObject?) {
    switch self.mode {
    case .visual, .normal:
      self.uiBridge.vimInput("\"+d")
    default:
      return
    }
  }

  @IBAction func copy(_ sender: AnyObject?) {
    switch self.mode {
    case .visual, .normal:
      self.uiBridge.vimInput("\"+y")
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
      self.uiBridge.vimInput(self.vimPlainString(content))
      return
    }

    self.nvim
      .getOption(name: "paste")
      .flatMap { curPasteMode -> Single<Bool> in
        if curPasteMode == false {
          return self
            .nvim.setOption(name: "paste", value: .bool(true))
            .map { _ in true }
        } else {
          return Single.just(false)
        }
      }
      .do(onSuccess: { pasteModeSet in
        switch self.mode {
        case .insert:
          self.uiBridge.vimInput("<ESC>\"+pa")
        case .normal, .visual:
          self.uiBridge.vimInput("\"+p")
        default:
          return
        }
      })
      .flatMap { pasteModeSet -> Single<Void> in
        if pasteModeSet {
          return self.nvim.setOption(name: "paste", value: .bool(false))
        }

        return Single.just(())
      }
      .subscribe(onError: { error in
        self.eventsSubject.onNext(.apiError(error: error, msg: "There was an pasting."))
      })
  }

  @IBAction func delete(_ sender: AnyObject?) {
    switch self.mode {
    case .normal, .visual:
      self.uiBridge.vimInput("x")
    default:
      return
    }
  }

  @IBAction public override func selectAll(_ sender: Any?) {
    switch self.mode {
    case .insert, .visual:
      self.uiBridge.vimInput("<Esc>ggVG")
    default:
      self.uiBridge.vimInput("ggVG")
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
