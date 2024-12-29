/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import NvimApi
import RxSwift

// MARK: - NSUserInterfaceValidationsProtocol

public extension NvimView {
  func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
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

    guard let action = item.action else { return true }

    switch action {
    case #selector(undo(_:)), #selector(redo(_:)): return canUndoOrRedo
    case #selector(copy(_:)), #selector(cut(_:)): return canCopyOrCut
    case #selector(paste(_:)): return canPaste
    case #selector(delete(_:)): return canDelete
    case #selector(selectAll(_:)): return canSelectAll
    default: return true
    }
  }
}

// MARK: - Edit Menu Items

extension NvimView {
  @IBAction func undo(_: Any?) {
    Task {
      switch self.mode {
      case .insert, .replace:
        await self.api.nvimInput(keys: "<Esc>ui").cauterize()
      case .normal, .visual:
        await self.api.nvimInput(keys: "u").cauterize()
      default:
        return
      }
    }
  }

  @IBAction func redo(_: Any?) {
    Task {
      switch self.mode {
      case .insert, .replace:
        await self.api.nvimInput(keys: "<Esc><C-r>i").cauterize()
      case .normal, .visual:
        await self.api.nvimInput(keys: "<C-r>").cauterize()
      default:
        return
      }
    }
  }

  @IBAction func cut(_: Any?) {
    Task {
      switch self.mode {
      case .visual, .normal:
        await self.api.nvimInput(keys: "\"+d").cauterize()
      default:
        return
      }
    }
  }

  @IBAction func copy(_: Any?) {
    Task {
      switch self.mode {
      case .visual, .normal:
        await self.api.nvimInput(keys: "\"+y").cauterize()
      default:
        return
      }
    }
  }

  @IBAction func paste(_: Any?) {
    Task {
      guard let content = NSPasteboard.general.string(forType: .string) else { return }
      // phase == 1 means paste in a single call
      await self.api.nvimPaste(data: content, crlf: false, phase: -1).cauterize()
    }
  }

  @IBAction func delete(_: Any?) {
    Task {
      switch self.mode {
      case .normal, .visual:
        await self.api.nvimInput(keys: "x").cauterize()
      default:
        return
      }
    }
  }

  @IBAction override public func selectAll(_: Any?) {
    Task {
      switch self.mode {
      case .insert, .visual:
        await self.api.nvimInput(keys: "<Esc>ggVG").cauterize()
      default:
        await self.api.nvimInput(keys: "ggVG").cauterize()
      }
    }
  }
}

// MARK: - Font Menu Items

extension NvimView {
  @IBAction func resetFontSize(_: Any?) { self.font = self._font }

  @IBAction func makeFontBigger(_: Any?) {
    let curFont = self.drawer.font
    let font = NSFontManager.shared
      .convert(curFont, toSize: min(curFont.pointSize + 1, NvimView.maxFontSize))
    self.updateFontMetaData(font)
  }

  @IBAction func makeFontSmaller(_: Any?) {
    let curFont = self.drawer.font
    let font = NSFontManager.shared
      .convert(curFont, toSize: max(curFont.pointSize - 1, NvimView.minFontSize))
    self.updateFontMetaData(font)
  }
}
