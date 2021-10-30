/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import Nimble
import XCTest

@testable import NvimView

class TypesetterWithoutLigaturesTest: XCTestCase {
  // GH-709
  func testHindi() {
    let runs = typesetter.fontGlyphRunsWithoutLigatures(
      nvimUtf16Cells: emojiMarked(["क", "ख", "ग", "घ", "ड़", "-", ">", "ड़"]),
      startColumn: 10,
      offset: offset,
      font: defaultFont,
      cellWidth: defaultWidth
    )
    expect(runs).to(haveCount(4))

    var run = runs[0]
    expect(run.font).to(equalFont(kohinoorDevanagari))
    expect(run.glyphs).to(equal([51, 52, 53, 54, 99]))
    expect(run.positions).to(equal(
      (10..<15).map {
        CGPoint(x: offset.x + CGFloat($0) * defaultWidth, y: offset.y)
      }
    ))

    run = runs[1]
    expect(run.font).to(equalFont(defaultFont))
    expect(run.glyphs).to(equal([16, 33]))
    expect(run.positions).to(equal(
      (15..<17).map {
        CGPoint(x: offset.x + CGFloat($0) * defaultWidth, y: offset.y)
      }
    ))

    run = runs[2]
    expect(run.font).to(equalFont(kohinoorDevanagari))
    expect(run.glyphs).to(equal([99]))
    expect(run.positions).to(equal(
      (17..<18).map {
        CGPoint(x: offset.x + CGFloat($0) * defaultWidth, y: offset.y)
      }
    ))

    self.assertEmojiMarker(
      run: runs[3],
      xPosition: offset.x + 18 * defaultWidth
    )
  }

  func testSimpleAsciiChars() {
    let runs = typesetter.fontGlyphRunsWithoutLigatures(
      nvimUtf16Cells: emojiMarked(["a", "b", "c"]),
      startColumn: 10,
      offset: offset,
      font: defaultFont,
      cellWidth: defaultWidth
    )
    expect(runs).to(haveCount(2))

    let run = runs[0]
    expect(run.font).to(equalFont(defaultFont))
    expect(run.glyphs).to(haveCount(3))
    expect(run.positions).to(equal(
      (10..<13).map {
        CGPoint(x: offset.x + CGFloat($0) * defaultWidth, y: offset.y)
      }
    ))

    self.assertEmojiMarker(
      run: runs[1],
      xPosition: offset.x + 13 * defaultWidth
    )
  }

  func testAccentedChars() {
    let runs = typesetter.fontGlyphRunsWithoutLigatures(
      nvimUtf16Cells: emojiMarked(["ü", "î", "ñ"]),
      startColumn: 20,
      offset: offset,
      font: defaultFont,
      cellWidth: defaultWidth
    )
    expect(runs).to(haveCount(2))

    let run = runs[0]
    expect(run.font).to(equalFont(defaultFont))
    expect(run.glyphs).to(haveCount(3))
    expect(run.positions).to(equal(
      (20..<23).map {
        CGPoint(x: offset.x + CGFloat($0) * defaultWidth, y: offset.y)
      }
    ))

    self.assertEmojiMarker(
      run: runs[1],
      xPosition: offset.x + 23 * defaultWidth
    )
  }

  func testCombiningChars() {
    let runs = typesetter.fontGlyphRunsWithoutLigatures(
      nvimUtf16Cells: emojiMarked(
        ["a", "a\u{1DC1}", "a\u{032A}", "a\u{034B}", "b", "c"]
      ),
      startColumn: 10,
      offset: offset,
      font: defaultFont,
      cellWidth: defaultWidth
    )
    expect(runs).to(haveCount(6))

    var run = runs[0]
    expect(run.font).to(equalFont(defaultFont))
    expect(run.glyphs).to(haveCount(1))
    expect(run.positions).to(equal(
      [
        CGPoint(x: offset.x + 10 * defaultWidth, y: offset.y),
      ]
    ))

    run = runs[1]
    expect(run.font).to(equalFont(courierNew))
    expect(run.glyphs).to(haveCount(2))
    expect(run.positions[0])
      .to(equal(CGPoint(x: offset.x + 11 * defaultWidth, y: offset.y)))
    expect(run.positions[1].x)
      .to(beCloseTo(offset.x + 11 * defaultWidth + 0.003, within: 0.001))
    expect(run.positions[1].y).to(beCloseTo(offset.y + 0.305, within: 0.001))

    run = runs[2]
    expect(run.font).to(equalFont(defaultFont))
    expect(run.glyphs).to(haveCount(2))
    expect(run.positions[0])
      .to(equal(CGPoint(x: offset.x + 12 * defaultWidth, y: offset.y)))
    expect(run.positions[1].x)
      .to(beCloseTo(offset.x + 12 * defaultWidth, within: 0.001))
    expect(run.positions[1].y).to(beCloseTo(offset.y - 0.279, within: 0.001))

    run = runs[3]
    expect(run.font).to(equalFont(monaco))
    expect(run.glyphs).to(haveCount(2))
    expect(run.positions[0])
      .to(equal(CGPoint(x: offset.x + 13 * defaultWidth, y: offset.y)))
    expect(run.positions[1].x)
      .to(beCloseTo(offset.x + 13 * defaultWidth + 7.804, within: 0.001))
    expect(run.positions[1].y).to(beCloseTo(offset.y + 2.446, within: 0.001))

    run = runs[4]
    expect(run.font).to(equalFont(defaultFont))
    expect(run.glyphs).to(haveCount(2))
    expect(run.positions).to(equal(
      [
        CGPoint(x: offset.x + 14 * defaultWidth, y: offset.y),
        CGPoint(x: offset.x + 15 * defaultWidth, y: offset.y),
      ]
    ))

    self.assertEmojiMarker(
      run: runs[5],
      xPosition: offset.x + 16 * defaultWidth
    )
  }

  func testSimpleEmojis() {
    let runs = typesetter.fontGlyphRunsWithoutLigatures(
      nvimUtf16Cells: asciiMarked(["a", "b", "\u{1F600}", "", "\u{1F377}", ""]),
      startColumn: 1,
      offset: offset,
      font: defaultFont,
      cellWidth: defaultWidth
    )
    expect(runs).to(haveCount(3))

    var run = runs[0]
    expect(run.font).to(equalFont(defaultFont))
    expect(run.glyphs).to(haveCount(2))
    expect(run.positions).to(equal(
      [
        CGPoint(x: offset.x + 1 * defaultWidth, y: offset.y),
        CGPoint(x: offset.x + 2 * defaultWidth, y: offset.y),
      ]
    ))

    run = runs[1]
    expect(run.font).to(equalFont(emoji))
    expect(run.glyphs).to(haveCount(2))
    expect(run.positions).to(equal(
      [
        CGPoint(x: offset.x + 3 * defaultWidth, y: offset.y),
        CGPoint(x: offset.x + 5 * defaultWidth, y: offset.y),
      ]
    ))

    self.assertAsciiMarker(run: runs[2], xPosition: offset.x + 7 * defaultWidth)
  }

  func testEmojisWithFitzpatrickModifier() {
    let runs = typesetter.fontGlyphRunsWithoutLigatures(
      nvimUtf16Cells: asciiMarked(["a", "\u{1F476}", "", "\u{1F3FD}", ""]),
      startColumn: 1,
      offset: offset,
      font: defaultFont,
      cellWidth: defaultWidth
    )

    expect(runs).to(haveCount(3))

    var run = runs[0]
    expect(run.font).to(equalFont(defaultFont))
    expect(run.glyphs).to(haveCount(1))
    expect(run.positions).to(equal(
      [
        CGPoint(x: offset.x + 1 * defaultWidth, y: offset.y),
      ]
    ))

    run = runs[1]
    expect(run.font).to(equalFont(emoji))
    expect(run.positions).to(equal(
      [
        CGPoint(x: offset.x + 2 * defaultWidth, y: offset.y),
      ]
    ))

    self.assertAsciiMarker(run: runs[2], xPosition: offset.x + 6 * defaultWidth)
  }

  func testHangul() {
    let runs = typesetter.fontGlyphRunsWithoutLigatures(
      nvimUtf16Cells: asciiMarked(["a", "b", "하", "", "태", "", "원", ""]),
      startColumn: 1,
      offset: offset,
      font: defaultFont,
      cellWidth: defaultWidth
    )
    expect(runs).to(haveCount(3))

    var run = runs[0]
    expect(run.font).to(equalFont(defaultFont))
    expect(run.glyphs).to(haveCount(2))
    expect(run.positions).to(equal(
      [
        CGPoint(x: offset.x + 1 * defaultWidth, y: offset.y),
        CGPoint(x: offset.x + 2 * defaultWidth, y: offset.y),
      ]
    ))

    run = runs[1]
    expect(run.font).to(equalFont(gothic))
    expect(run.positions).to(equal(
      [
        CGPoint(x: offset.x + 3 * defaultWidth, y: offset.y),
        CGPoint(x: offset.x + 5 * defaultWidth, y: offset.y),
        CGPoint(x: offset.x + 7 * defaultWidth, y: offset.y),
      ]
    ))

    self.assertAsciiMarker(run: runs[2], xPosition: offset.x + 9 * defaultWidth)
  }

  func testHanja() {
    let runs = typesetter.fontGlyphRunsWithoutLigatures(
      nvimUtf16Cells: asciiMarked(["a", "b", "河", "", "泰", "", "元", ""]),
      startColumn: 1,
      offset: offset,
      font: defaultFont,
      cellWidth: defaultWidth
    )
    expect(runs).to(haveCount(3))

    var run = runs[0]
    expect(run.font).to(equalFont(defaultFont))
    expect(run.glyphs).to(haveCount(2))
    expect(run.positions).to(equal(
      [
        CGPoint(x: offset.x + 1 * defaultWidth, y: offset.y),
        CGPoint(x: offset.x + 2 * defaultWidth, y: offset.y),
      ]
    ))

    run = runs[1]
    expect(run.font).to(equalFont(gothic))
    expect(run.positions).to(equal(
      [
        CGPoint(x: offset.x + 3 * defaultWidth, y: offset.y),
        CGPoint(x: offset.x + 5 * defaultWidth, y: offset.y),
        CGPoint(x: offset.x + 7 * defaultWidth, y: offset.y),
      ]
    ))

    self.assertAsciiMarker(run: runs[2], xPosition: offset.x + 9 * defaultWidth)
  }

  func testOthers() {
    let runs = typesetter.fontGlyphRunsWithoutLigatures(
      nvimUtf16Cells: emojiMarked(["a", "\u{10437}", "\u{1F14}"]),
      startColumn: 1,
      offset: offset,
      font: defaultFont,
      cellWidth: defaultWidth
    )
    expect(runs).to(haveCount(4))

    var run = runs[0]
    expect(run.font).to(equalFont(defaultFont))
    expect(run.glyphs).to(haveCount(1))
    expect(run.positions).to(equal(
      [
        CGPoint(x: offset.x + 1 * defaultWidth, y: offset.y),
      ]
    ))

    run = runs[1]
    expect(run.font).to(equalFont(baskerville))
    expect(run.positions).to(equal(
      [
        CGPoint(x: offset.x + 2 * defaultWidth, y: offset.y),
      ]
    ))

    run = runs[2]
    expect(run.font).to(equalFont(defaultFont))
    expect(run.glyphs).to(haveCount(1))
    expect(run.positions).to(equal(
      [
        CGPoint(x: offset.x + 3 * defaultWidth, y: offset.y),
      ]
    ))

    self.assertEmojiMarker(run: runs[3], xPosition: offset.x + 4 * defaultWidth)
  }

  func testSimpleLigatureChars() {
    let runs = typesetter.fontGlyphRunsWithoutLigatures(
      nvimUtf16Cells: emojiMarked(["a", "-", "-", ">", "a"]),
      startColumn: 1,
      offset: offset,
      font: fira,
      cellWidth: firaWidth
    )

    expect(runs).to(haveCount(2))

    let run = runs[0]
    expect(run.font).to(equalFont(fira))
    expect(run.glyphs).to(equal([139, 1059, 1059, 1228, 139]))
    expect(run.positions).to(equal(
      (1..<6).map {
        CGPoint(x: offset.x + CGFloat($0) * firaWidth, y: offset.y)
      }
    ))

    self.assertEmojiMarker(run: runs[1], xPosition: offset.x + 6 * firaWidth)
  }

  private func assertAsciiMarker(run: FontGlyphRun, xPosition: CGFloat) {
    expect(run.font).to(equalFont(defaultFont))
    expect(run.positions).to(equal([CGPoint(x: xPosition, y: offset.y)]))
  }

  private func assertEmojiMarker(run: FontGlyphRun, xPosition: CGFloat) {
    expect(run.font).to(equalFont(emoji))
    expect(run.positions).to(equal([CGPoint(x: xPosition, y: offset.y)]))
  }
}

class TypesetterWithLigaturesTest: XCTestCase {
  func testSimpleAsciiChars() {
    let runs = typesetter.fontGlyphRunsWithLigatures(
      nvimUtf16Cells: emojiMarked(Array(repeating: "a", count: 20)),
      startColumn: 1,
      offset: offset,
      font: defaultFont,
      cellWidth: defaultWidth
    )
    expect(runs).to(haveCount(2))

    let run = runs[0]
    expect(run.font).to(equalFont(defaultFont))
    expect(run.glyphs).to(haveCount(20))
    expect(run.positions).to(equal(
      (1..<21).map {
        CGPoint(x: offset.x + CGFloat($0) * defaultWidth, y: offset.y)
      }
    ))

    self.assertEmojiMarker(
      run: runs[1],
      xPosition: offset.x + 21 * defaultWidth
    )
  }

  func testAccentedChars() {
    let runs = typesetter.fontGlyphRunsWithLigatures(
      nvimUtf16Cells: emojiMarked(["ü", "î", "ñ"]),
      startColumn: 10,
      offset: offset,
      font: defaultFont,
      cellWidth: defaultWidth
    )

    expect(runs).to(haveCount(2))

    let run = runs[0]
    expect(run.font).to(equalFont(defaultFont))
    expect(run.glyphs).to(haveCount(3))
    expect(run.positions).to(equal(
      [
        CGPoint(x: offset.x + 10 * defaultWidth, y: offset.y),
        CGPoint(x: offset.x + 11 * defaultWidth, y: offset.y),
        CGPoint(x: offset.x + 12 * defaultWidth, y: offset.y),
      ]
    ))

    self.assertEmojiMarker(run: runs[1], xPosition: offset.x + 13 * defaultWidth)
  }

  func testCombiningChars() {
    let runs = typesetter.fontGlyphRunsWithLigatures(
      nvimUtf16Cells: emojiMarked(["a\u{1DC1}", "a\u{032A}", "a\u{034B}"]),
      startColumn: 1,
      offset: offset,
      font: defaultFont,
      cellWidth: defaultWidth
    )
    expect(runs).to(haveCount(4))

    // newest xcode(13.1) will crash at the follwing code, by use var run, and call expect(run.positions[0]). avoid crash
    do {
        // The positions of the combining characters are copied from print outputs
        // and they are visually checked by drawing them and inspecting them...
        let run = runs[0]
        expect(run.font).to(equalFont(courierNew))
        expect(run.glyphs).to(haveCount(2))
        expect(run.positions[0])
          .to(equal(CGPoint(x: offset.x + 1 * defaultWidth, y: offset.y)))
        expect(run.positions[1].x)
          .to(beCloseTo(offset.x + 1 * defaultWidth + 0.003, within: 0.001))
        expect(run.positions[1].y).to(beCloseTo(offset.y + 0.305, within: 0.001))
    }

    do {
        let run = runs[1]
        expect(run.font).to(equalFont(defaultFont))
        expect(run.glyphs).to(haveCount(2))
        expect(run.positions[0])
          .to(equal(CGPoint(x: offset.x + 2 * defaultWidth, y: offset.y)))
        expect(run.positions[1].x)
          .to(beCloseTo(offset.x + 2 * defaultWidth, within: 0.001))
        expect(run.positions[1].y).to(beCloseTo(offset.y - 0.279, within: 0.001))
    }

    do {
        let run = runs[2]
        expect(run.font).to(equalFont(monaco))
        expect(run.glyphs).to(haveCount(2))
        expect(run.positions[0])
          .to(equal(CGPoint(x: offset.x + 3 * defaultWidth, y: offset.y)))
        expect(run.positions[1].x)
          .to(beCloseTo(offset.x + 3 * defaultWidth + 7.804, within: 0.001))
        expect(run.positions[1].y).to(beCloseTo(offset.y + 2.446, within: 0.001))
    }

    self.assertEmojiMarker(run: runs[3], xPosition: offset.x + 4 * defaultWidth)
  }

  func testSimpleEmojis() {
    let runs = typesetter.fontGlyphRunsWithLigatures(
      nvimUtf16Cells: asciiMarked(["\u{1F600}", "", "\u{1F377}", ""]),
      startColumn: 0,
      offset: offset,
      font: defaultFont,
      cellWidth: defaultWidth
    )
    expect(runs).to(haveCount(2))

    let run = runs[0]
    expect(run.font).to(equalFont(emoji))
    expect(run.positions).to(equal(
      [
        CGPoint(x: offset.x + 0, y: offset.y),
        CGPoint(x: offset.x + 2 * defaultWidth, y: offset.y),
      ]
    ))

    self.assertAsciiMarker(run: runs[1], xPosition: offset.x + 4 * defaultWidth)
  }

  func testEmojisWithFitzpatrickModifier() {
    let runs = typesetter.fontGlyphRunsWithLigatures(
      // Neovim does not yet seem to support the Fitzpatrick modifiers:
      // It sends the following instead of ["\u{1F476}\u{1F3FD}", ""].
      // We render it together anyway and treat it as a 4-cell character.
      nvimUtf16Cells: asciiMarked(["\u{1F476}", "", "\u{1F3FD}", ""]),
      startColumn: 0,
      offset: offset,
      font: defaultFont,
      cellWidth: defaultWidth
    )
    expect(runs).to(haveCount(2))

    let run = runs[0]
    expect(run.font).to(equalFont(emoji))
    expect(run.positions).to(equal(
      [
        CGPoint(x: offset.x + 0, y: offset.y),
      ]
    ))

    self.assertAsciiMarker(run: runs[1], xPosition: offset.x + 4 * defaultWidth)
  }

  func testEmojisWithZeroWidthJoiner() {
    // Neovim does not yet seem to support Emojis composed by zero-width-joiner:
    // If it did, we'd render it correctly.
    let runs = typesetter.fontGlyphRunsWithLigatures(
      nvimUtf16Cells: asciiMarked(
        [
          "\u{1F468}\u{200D}\u{1F468}\u{200D}\u{1F467}\u{200D}\u{1F467}", "",
        ]
      ),
      startColumn: 1,
      offset: offset,
      font: defaultFont,
      cellWidth: defaultWidth
    )
    expect(runs).to(haveCount(2))

    let run = runs[0]
    expect(run.font).to(equalFont(emoji))
    expect(run.glyphs).to(haveCount(1))
    expect(run.positions).to(equal(
      [
        CGPoint(x: offset.x + 1 * defaultWidth, y: offset.y),
      ]
    ))

    self.assertAsciiMarker(run: runs[1], xPosition: offset.x + 3 * defaultWidth)
  }

  func testHangul() {
    let runs = typesetter.fontGlyphRunsWithLigatures(
      nvimUtf16Cells: asciiMarked(["하", "", "태", "", "원", ""]),
      startColumn: 1,
      offset: offset,
      font: defaultFont,
      cellWidth: defaultWidth
    )
    expect(runs).to(haveCount(2))

    let run = runs[0]
    expect(run.font).to(equalFont(gothic))
    expect(run.positions).to(equal(
      [
        CGPoint(x: offset.x + 1 * defaultWidth, y: offset.y),
        CGPoint(x: offset.x + 3 * defaultWidth, y: offset.y),
        CGPoint(x: offset.x + 5 * defaultWidth, y: offset.y),
      ]
    ))

    self.assertAsciiMarker(run: runs[1], xPosition: offset.x + 7 * defaultWidth)
  }

  func testHanja() {
    let runs = typesetter.fontGlyphRunsWithLigatures(
      nvimUtf16Cells: asciiMarked(["河", "", "泰", "", "元", ""]),
      startColumn: 1,
      offset: offset,
      font: defaultFont,
      cellWidth: defaultWidth
    )
    expect(runs).to(haveCount(2))

    let run = runs[0]
    expect(run.font).to(equalFont(gothic))
    expect(run.positions).to(equal(
      [
        CGPoint(x: offset.x + 1 * defaultWidth, y: offset.y),
        CGPoint(x: offset.x + 3 * defaultWidth, y: offset.y),
        CGPoint(x: offset.x + 5 * defaultWidth, y: offset.y),
      ]
    ))

    self.assertAsciiMarker(run: runs[1], xPosition: offset.x + 7 * defaultWidth)
  }

  func testOthers() {
    let runs = typesetter.fontGlyphRunsWithLigatures(
      nvimUtf16Cells: emojiMarked(["\u{10437}", "\u{1F14}"]),
      startColumn: 0,
      offset: offset,
      font: defaultFont,
      cellWidth: defaultWidth
    )
    expect(runs).to(haveCount(3))

    var run = runs[0]
    expect(run.font).to(equalFont(baskerville))
    expect(run.positions).to(equal(
      [
        CGPoint(x: offset.x + 0, y: offset.y),
      ]
    ))

    run = runs[1]
    expect(run.font).to(equalFont(defaultFont))
    expect(run.positions).to(equal(
      [
        CGPoint(x: offset.x + 1 * defaultWidth, y: offset.y),
      ]
    ))

    self.assertEmojiMarker(run: runs[2], xPosition: offset.x + 2 * defaultWidth)
  }

  func testSimpleLigatureChars() {
    let runs = typesetter.fontGlyphRunsWithLigatures(
      nvimUtf16Cells: emojiMarked(["-", "-", ">", "a"]),
      startColumn: 0,
      offset: offset,
      font: fira,
      cellWidth: firaWidth
    )
    expect(runs).to(haveCount(2))

    let run = runs[0]
    expect(run.font).to(equalFont(fira))
    // Ligatures of popular monospace fonts like Fira Code seem to be composed
    // of multiple characters with the same advance as other normal characters.
    // The glyph codes may change from version to version of Fira Code.
    // Check using http://mathew-kurian.github.io/CharacterMap/.
    expect(run.glyphs).to(equal([1142, 1141, 1743, 139]))
    expect(run.positions).to(equal(
      (0..<4).map {
        CGPoint(x: offset.x + CGFloat($0) * firaWidth, y: offset.y)
      }
    ))

    self.assertEmojiMarker(run: runs[1], xPosition: offset.x + 4 * firaWidth)
  }

  private func assertAsciiMarker(run: FontGlyphRun, xPosition: CGFloat) {
    expect(run.font).to(equalFont(defaultFont))
    expect(run.positions).to(equal(
      [
        CGPoint(x: xPosition, y: offset.y),
      ]
    ))
  }

  private func assertEmojiMarker(run: FontGlyphRun, xPosition: CGFloat) {
    expect(run.font).to(equalFont(emoji))
    expect(run.positions).to(equal(
      [
        CGPoint(x: xPosition, y: offset.y),
      ]
    ))
  }
}

private let defaultFont = NSFont(name: "Menlo", size: 13)!
private let fira = NSFont(name: "FiraCode-Regular", size: 13)!
private let courierNew = NSFont(name: "Courier New", size: 13)!
private let monaco = NSFont(name: "Monaco", size: 13)!
private let emoji = NSFont(name: "AppleColorEmoji", size: 13)!
private let gothic = NSFont(name: "Apple SD Gothic Neo", size: 13)!
private let baskerville = NSFont(name: "Baskerville", size: 13)!
private let kohinoorDevanagari = NSFont(name: "Kohinoor Devanagari", size: 13)!

private let defaultWidth = FontUtils
  .cellSize(of: defaultFont, linespacing: 1, characterspacing: 1).width
private let firaWidth = FontUtils.cellSize(of: fira, linespacing: 1, characterspacing: 1).width

private let offset = CGPoint(x: 7, y: 8)

private let typesetter = Typesetter()

private func asciiMarked(_ strings: [String]) -> [[Unicode.UTF16.CodeUnit]] {
  utf16Chars(strings + ["a"])
}

private func emojiMarked(_ strings: [String]) -> [[Unicode.UTF16.CodeUnit]] {
  utf16Chars(strings + ["\u{1F600}"])
}

private func utf16Chars(_ array: [String]) -> [[Unicode.UTF16.CodeUnit]] {
  array.map { Array($0.utf16) }
}
