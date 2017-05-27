/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa

// MARK: - NSUserInterfaceValidationsProtocol
extension NeoVimView {

  public func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
    let canUndoOrRedo = self.mode == .insert || self.mode == .replace
                        || self.mode == .normal || self.mode == .visual
    let canCopyOrCut = self.mode == .normal || self.mode == .visual
    let canPaste = self.pasteboard.string(forType: NSPasteboardTypeString) != nil
    let canDelete = self.mode == .visual || self.mode == .normal
    let canSelectAll = self.mode == .insert || self.mode == .replace
                       || self.mode == .normal || self.mode == .visual

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
extension NeoVimView {

  @IBAction func undo(_ sender: AnyObject?) {
    switch self.mode {
    case .insert, .replace:
      self.agent.vimInput("<Esc>ui")
    case .normal, .visual:
      self.agent.vimInput("u")
    default:
      return
    }
  }

  @IBAction func redo(_ sender: AnyObject?) {
    switch self.mode {
    case .insert, .replace:
      self.agent.vimInput("<Esc><C-r>i")
    case .normal, .visual:
      self.agent.vimInput("<C-r>")
    default:
      return
    }
  }

  @IBAction func cut(_ sender: AnyObject?) {
    switch self.mode {
    case .visual, .normal:
      self.agent.vimInput("\"+d")
    default:
      return
    }
  }

  @IBAction func copy(_ sender: AnyObject?) {
    switch self.mode {
    case .visual, .normal:
      self.agent.vimInput("\"+y")
    default:
      return
    }
  }

  @IBAction func paste(_ sender: AnyObject?) {
    guard let content = self.pasteboard.string(forType: NSPasteboardTypeString) else {
      return
    }

    if self.mode == .cmdline || self.mode == .cmdlineInsert || self.mode == .cmdlineReplace
       || self.mode == .replace
       || self.mode == .termFocus {
      self.agent.vimInput(self.vimPlainString(content))
      return
    }

    guard let curPasteMode = self.agent.boolOption("paste") else {
      self.ipcBecameInvalid("Reason: 'set paste' failed")
      return
    }

    let pasteModeSet: Bool

    if curPasteMode == false {
      self.agent.setBoolOption("paste", to: true)
      pasteModeSet = true
    } else {
      pasteModeSet = false
    }

    let resetPasteModeCmd = pasteModeSet ? ":set nopaste<CR>" : ""

    switch self.mode {
    case .insert:
      self.agent.vimInput("<ESC>\"+p\(resetPasteModeCmd)a")
    case .normal, .visual:
      self.agent.vimInput("\"+p\(resetPasteModeCmd)")
    default:
      return
    }
  }

  @IBAction func delete(_ sender: AnyObject?) {
    switch self.mode {
    case .normal, .visual:
      self.agent.vimInput("x")
    default:
      return
    }
  }

  @IBAction public override func selectAll(_ sender: Any?) {
    switch self.mode {
    case .insert, .visual:
      self.agent.vimInput("<Esc>ggVG")
    default:
      self.agent.vimInput("ggVG")
    }
  }
}

// MARK: - Font Menu Items
extension NeoVimView {

  @IBAction func resetFontSize(_ sender: Any?) {
    self.font = self._font
  }

  @IBAction func makeFontBigger(_ sender: Any?) {
    let curFont = self.drawer.font
    let font = self.fontManager.convert(curFont,
                                        toSize: min(curFont.pointSize + 1, NeoVimView.maxFontSize))
    self.updateFontMetaData(font)
  }

  @IBAction func makeFontSmaller(_ sender: Any?) {
    let curFont = self.drawer.font
    let font = self.fontManager.convert(curFont,
                                        toSize: max(curFont.pointSize - 1, NeoVimView.minFontSize))
    self.updateFontMetaData(font)
  }
}
