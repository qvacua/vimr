/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import RxSwift

class NeoVimUiBridge: NSObject, NeoVimUiBridgeProtocol {

  private let subject: PublishSubject<NeoVim.UiEvent> = PublishSubject()

  var observable: Observable<NeoVim.UiEvent> {
    return self.subject.asObservable()
  }

  func resizeToRows(rows: Int32, columns: Int32) {
    self.subject.onNext(.Resize(size: NeoVim.Size(rows: rows, columns: columns)))
  }

  func clear() {
    print("### clear")
  }

  func eolClear() {
    print("### eol clear")
  }

  func cursorGotoRow(row: Int32, column: Int32) {
    self.subject.onNext(.MoveCursor(position: NeoVim.Position(row: row, column: column)))
  }

  func updateMenu() {
    print("### update menu")
  }

  func busyStart() {
    print("### busy start")
  }

  func busyStop() {
    print("### busy stop")
  }

  func mouseOn() {
    print("### mouse on")
  }

  func mouseOff() {
    print("### mouse off")
  }

  func modeChange(mode: Int32) {
    print("### mode change to: \(String(format: "%04X", mode))")
  }

  func setScrollRegionToTop(top: Int32, bottom: Int32, left: Int32, right: Int32) {
    print("### set scroll region: \(top), \(bottom), \(left), \(right)")
  }

  func scroll(count: Int32) {
    print("### count: \(count)")
  }

  func highlightSet(attrs: HighlightAttributes) {
    print("### highlight set: \(attrs)");
    print("### highlight foreground: \(colorFromCode(attrs.foreground))")
    print("### highlight background: \(colorFromCode(attrs.background, kind: .Background))")
    print("### highlight special: \(colorFromCode(attrs.special, kind: .Special))")
  }

  func put(str: String) {
    self.subject.onNext(.Put(string: str))
  }

  func bell() {
    print("### bell")
  }

  func visualBell() {
    print("### visual bell")
  }

  func flush() {
    print("### flush")
  }

  func updateForeground(fg: Int32) {
    print("### update fg: \(colorFromCode(fg))")
  }

  func updateBackground(bg: Int32) {
    print("### update bg: \(colorFromCode(bg, kind: .Background))")
  }

  func updateSpecial(sp: Int32) {
    print("### update sp: \(colorFromCode(sp, kind: .Special))")
  }

  func suspend() {
    print("### suspend")
  }

  func setTitle(title: String) {
    print("### set title: \(title)")
  }

  func setIcon(icon: String) {
    print("### set icon: \(icon)")
  }

  func stop() {
    print("### stop")
  }

  private func colorFromCode(rgb: Int32, kind: NeoVim.ColorKind = .Foreground) -> NSColor {
    if rgb >= 0 {
      return ColorUtils.colorFromCode(rgb)
    }

    switch kind {
    case .Foreground: return NSColor.blackColor()
    case .Background: return NSColor.whiteColor()
    case .Special: return NSColor.blackColor()
    }
  }
}
