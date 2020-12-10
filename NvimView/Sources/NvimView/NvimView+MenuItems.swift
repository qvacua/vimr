/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
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
    switch self.mode {
    case .insert, .replace:
      self.api
        .input(keys: "<Esc>ui", errWhenBlocked: false)
        .subscribe(onError: { [weak self] error in
          self?.eventsSubject.onNext(.apiError(msg: "Could not undo", cause: error))
        })
        .disposed(by: self.disposeBag)
    case .normal, .visual:
      self.api
        .input(keys: "u", errWhenBlocked: false)
        .subscribe(onError: { [weak self] error in
          self?.eventsSubject.onNext(.apiError(msg: "Could not undo", cause: error))
        })
        .disposed(by: self.disposeBag)
    default:
      return
    }
  }

  @IBAction func redo(_: Any?) {
    switch self.mode {
    case .insert, .replace:
      self.api
        .input(keys: "<Esc><C-r>i", errWhenBlocked: false)
        .subscribe(onError: { [weak self] error in
          self?.eventsSubject.onNext(.apiError(msg: "Could not redo", cause: error))
        })
        .disposed(by: self.disposeBag)
    case .normal, .visual:
      self.api
        .input(keys: "<C-r>", errWhenBlocked: false)
        .subscribe(onError: { [weak self] error in
          self?.eventsSubject.onNext(.apiError(msg: "Could not redo", cause: error))
        })
        .disposed(by: self.disposeBag)
    default:
      return
    }
  }

  @IBAction func cut(_: Any?) {
    switch self.mode {
    case .visual, .normal:
      self.api
        .input(keys: "\"+d", errWhenBlocked: false)
        .subscribe(onError: { [weak self] error in
          self?.eventsSubject.onNext(.apiError(msg: "Could not cut", cause: error))
        })
        .disposed(by: self.disposeBag)
    default:
      return
    }
  }

  @IBAction func copy(_: Any?) {
    switch self.mode {
    case .visual, .normal:
      self.api
        .input(keys: "\"+y", errWhenBlocked: false)
        .subscribe(onError: { [weak self] error in
          self?.eventsSubject.onNext(.apiError(msg: "Could not copy", cause: error))
        })
        .disposed(by: self.disposeBag)
    default:
      return
    }
  }

  @IBAction func paste(_: Any?) {
    guard let content = NSPasteboard.general.string(forType: .string) else { return }

    // phase == 1 means paste in a single call
    self.api
      .paste(data: content, crlf: false, phase: -1)
      .subscribe(onError: { [weak self] error in
        self?.eventsSubject.onNext(.apiError(msg: "Could not paste \(content)", cause: error))
      })
      .disposed(by: self.disposeBag)
  }

  @IBAction func delete(_: Any?) {
    switch self.mode {
    case .normal, .visual:
      self.api
        .input(keys: "x", errWhenBlocked: false)
        .subscribe(onError: { [weak self] error in
          self?.eventsSubject.onNext(.apiError(msg: "Could not delete", cause: error))
        })
        .disposed(by: self.disposeBag)
    default:
      return
    }
  }

  @IBAction override public func selectAll(_: Any?) {
    switch self.mode {
    case .insert, .visual:
      self.api
        .input(keys: "<Esc>ggVG", errWhenBlocked: false)
        .subscribe(onError: { [weak self] error in
          self?.eventsSubject.onNext(.apiError(msg: "Could not select all", cause: error))
        })
        .disposed(by: self.disposeBag)
    default:
      self.api
        .input(keys: "ggVG", errWhenBlocked: false)
        .subscribe(onError: { [weak self] error in
          self?.eventsSubject.onNext(.apiError(msg: "Could not select all", cause: error))
        })
        .disposed(by: self.disposeBag)
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
