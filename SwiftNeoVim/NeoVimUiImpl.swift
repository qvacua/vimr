/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

class NeoVimUiImpl: NSObject, NeoVimUi {

  func resize(rows: Int32, columns: Int32) {
    print("### resize: \(rows), \(columns)")
  }

  func clear() {
    print("### clear")
  }

  func eolClear() {
    print("### eol clear")
  }

  func cursorGoto(row: Int32, column: Int32) {
    print("### cursor goto: \(row), \(column)")
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

  func setScrollRegion(top: Int32, bottom: Int32, left: Int32, right: Int32) {
    print("### set scroll region: \(top), \(bottom), \(left), \(right)")
  }

  func scroll(count: Int32) {
    print("### count: \(count)")
  }

  func highlightSet(attrs: HighlightAttributes) {
    print("### highlight set: \(attrs)");
  }

  func put(str: String) {
    print("### " + str);
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

  func updateFg(fg: Int32) {
    print("### update fg: \(fg)")
  }

  func updateBg(bg: Int32) {
    print("### update bg: \(bg)")
  }

  func updateSp(sp: Int32) {
    print("### update sp: \(sp)")
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
}
