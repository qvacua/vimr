/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa

final class Typesetter {

  func fontGlyphRunsWithLigatures(
    nvimUtf16Cells: [[Unicode.UTF16.CodeUnit]],
    startColumn: Int,
    offset: CGPoint,
    font: NSFont,
    cellWidth: CGFloat
  ) -> [FontGlyphRun] {

    let utf16Chars = self.utf16Chars(from: nvimUtf16Cells)
    let cellIndices = self.cellIndices(
      from: nvimUtf16Cells,
      utf16CharsCount: utf16Chars.count
    )
    let ctRuns = self.ctRuns(from: utf16Chars, font: font)

    let result = ctRuns.map { run -> FontGlyphRun in
      let glyphCount = CTRunGetGlyphCount(run)

      var glyphs = Array(repeating: CGGlyph(), count: glyphCount)
      CTRunGetGlyphs(run, .zero, &glyphs)

      var positions = Array(repeating: CGPoint.zero, count: glyphCount)
      CTRunGetPositions(run, .zero, &positions)

      var indices = Array(repeating: CFIndex(), count: glyphCount)
      CTRunGetStringIndices(run, .zero, &indices)

      var column = -1
      var columnPosition = CGFloat(0)
      var deltaX = CGFloat(0)
      for i in 0..<positions.count {
        let newColumn = cellIndices[indices[i]] + startColumn
        if newColumn != column {
          columnPosition = offset.x + CGFloat(newColumn) * cellWidth
          deltaX = columnPosition - positions[i].x
          column = newColumn
        }
        positions[i].x += deltaX
        positions[i].y += offset.y
      }

      let attrs = CTRunGetAttributes(run)
      let font = Unmanaged<NSFont>.fromOpaque(
        CFDictionaryGetValue(
          attrs, Unmanaged.passUnretained(kCTFontAttributeName).toOpaque()
        )
      ).takeUnretainedValue()

      return FontGlyphRun(
        font: font, glyphs: glyphs, positions: positions
      )
    }

    return result
  }

  private func cellIndices(
    from nvimUtf16Cells: [[Unicode.UTF16.CodeUnit]],
    utf16CharsCount: Int
  ) -> Array<Int> {
    var cellIndices = Array(repeating: 0, count: utf16CharsCount)
    var cellIndex = 0
    var i = 0
    repeat {
      if nvimUtf16Cells[cellIndex].isEmpty {
        cellIndex = cellIndex &+ 1
        continue
      }

      for _ in (0..<nvimUtf16Cells[cellIndex].count) {
        cellIndices[i] = cellIndex
        i = i &+ 1
      }
      cellIndex = cellIndex &+ 1
    } while cellIndex < nvimUtf16Cells.count

    return cellIndices
  }

  private func utf16Chars(
    from nvimUtf16Cells: [[Unicode.UTF16.CodeUnit]]
  ) -> Array<UInt16> {
    // Using reduce seems to be slower than the following:
    var count = 0
    for i in 0..<nvimUtf16Cells.count {
      count = count &+ nvimUtf16Cells[i].count
    }

    // Using append(contentsOf:) seems to be slower than the following:
    var result = Array(repeating: Unicode.UTF16.CodeUnit(), count: count)
    var i = 0
    for cell in nvimUtf16Cells {
      if cell.isEmpty {
        continue
      }

      for j in 0..<cell.count {
        result[i &+ j] = cell[j]
      }

      i = i &+ cell.count
    }

    return result
  }

  func fontGlyphRunsWithoutLigatures(
    nvimCells: [String],
    startColumn: Int,
    offset: CGPoint,
    font: NSFont,
    cellWidth: CGFloat
  ) -> [FontGlyphRun] {

    let nvimUtf16CellsRuns = self.groupSimpleAndNonSimpleChars(
      nvimCells: nvimCells, font: font
    )

    let runs: [[FontGlyphRun]] = nvimUtf16CellsRuns.map { run in
      guard run.isSimple else {
        return self.fontGlyphRunsWithLigatures(
          nvimUtf16Cells: run.nvimUtf16Cells,
          startColumn: startColumn + run.startColumn,
          offset: offset,
          font: font,
          cellWidth: cellWidth
        )
      }

      let unichars = self.utf16Chars(from: run.nvimUtf16Cells)
      var glyphs = Array<CGGlyph>(repeating: CGGlyph(), count: unichars.count)

      let gotAllGlyphs = unichars.withUnsafeBufferPointer { pointer in
        CTFontGetGlyphsForCharacters(
          font, pointer.baseAddress!, &glyphs, unichars.count
        )
      }
      if gotAllGlyphs {
        let startColumnForPositions = startColumn + run.startColumn
        let endColumn = startColumnForPositions + glyphs.count
        let positions = (startColumnForPositions..<endColumn).map { i in
          CGPoint(
            x: offset.x + CGFloat(i) * cellWidth,
            y: offset.y
          )
        }
        return [
          FontGlyphRun(font: font, glyphs: glyphs, positions: positions)
        ]
      }

      // TODO: GH-666: Do we ever come here?
      print("Could not get all glyphs for single-width singe UTF16 character!")
      let groupRanges = glyphs.groupedRanges { _, element in element == 0 }
      let groupRuns: [[FontGlyphRun]] = groupRanges.map { range in
        if unichars[range.lowerBound] == 0 {
          let nvimUtf16Cells = unichars[range].map { [$0] }
          return self.fontGlyphRunsWithLigatures(
            nvimUtf16Cells: nvimUtf16Cells,
            startColumn: startColumn + range.lowerBound,
            offset: offset,
            font: font,
            cellWidth: cellWidth
          )
        } else {
          let startColumnForPositions = startColumn + range.lowerBound
          let endColumn = startColumnForPositions + glyphs.count
          let positions = (startColumnForPositions..<endColumn).map { i in
            CGPoint(
              x: offset.x
                + CGFloat(i + startColumn + range.lowerBound) * cellWidth,
              y: offset.y
            )
          }
          return [
            FontGlyphRun(font: font, glyphs: glyphs, positions: positions)
          ]
        }
      }

      return groupRuns.flatMap { $0 }
    }

    return runs.flatMap { $0 }
  }

  private func ctRuns(
    from utf16Chars: Array<Unicode.UTF16.CodeUnit>,
    font: NSFont
  ) -> [CTRun] {
    let attrStr = NSAttributedString(
      string: String(utf16CodeUnits: utf16Chars, count: utf16Chars.count),
      attributes: [
        .font: font,
        .ligature: 1
      ]
    )

    let ctLine = CTLineCreateWithAttributedString(attrStr)
    guard let ctRuns = CTLineGetGlyphRuns(ctLine) as? [CTRun] else {
      return []
    }

    return ctRuns
  }

  private struct NvimUtf16CellsRun {

    var startColumn: Int
    var nvimUtf16Cells: [[Unicode.UTF16.CodeUnit]]
    var isSimple: Bool
  }

  private func groupSimpleAndNonSimpleChars(
    nvimCells: [String], font: NSFont
  ) -> [NvimUtf16CellsRun] {
    if nvimCells.isEmpty {
      return []
    }

    let nvimUtf16Cells = nvimCells.map { Array($0.utf16) }
    let utf16Chars = self.utf16Chars(from: nvimUtf16Cells)

    let hasMoreThanTwoCells = nvimUtf16Cells.count >= 2
    let firstCharHasSingleUnichar = nvimUtf16Cells[0].count == 1
    let firstCharHasDoubleWidth
      = hasMoreThanTwoCells && nvimUtf16Cells[1].isEmpty

    var result = [NvimUtf16CellsRun]()
    result.reserveCapacity(nvimUtf16Cells.count)

    let inclusiveEndIndex = nvimUtf16Cells.endIndex - 1
    var previousWasSimple
      = firstCharHasSingleUnichar && !firstCharHasDoubleWidth
    var lastStartIndex = 0
    var lastEndIndex = 0

    for (i, utf16Cell) in nvimUtf16Cells.enumerated() {
      defer { lastEndIndex = i }

      if utf16Cell.isEmpty {
        if i == inclusiveEndIndex {
          result.append(NvimUtf16CellsRun(
            startColumn: lastStartIndex,
            nvimUtf16Cells: Array(nvimUtf16Cells[lastStartIndex...i]),
            isSimple: false
          ))
        }

        continue
      }

      let hasSingleUnichar = utf16Cell.count == 1
      let hasDoubleWidth = i + 1 < nvimUtf16Cells.count
        && nvimUtf16Cells[i + 1].isEmpty
      let isSimple = hasSingleUnichar && !hasDoubleWidth

      if previousWasSimple == isSimple {
        if i == inclusiveEndIndex {
          result.append(NvimUtf16CellsRun(
            startColumn: lastStartIndex,
            nvimUtf16Cells: Array(nvimUtf16Cells[lastStartIndex...i]),
            isSimple: previousWasSimple
          ))
        }
      } else {
        result.append(NvimUtf16CellsRun(
          startColumn: lastStartIndex,
          nvimUtf16Cells: Array(nvimUtf16Cells[lastStartIndex...lastEndIndex]),
          isSimple: previousWasSimple
        ))

        lastStartIndex = i
        previousWasSimple = isSimple

        if i == inclusiveEndIndex {
          result.append(NvimUtf16CellsRun(
            startColumn: i,
            nvimUtf16Cells: Array(nvimUtf16Cells[i...i]),
            isSimple: isSimple
          ))
        }
      }
    }

    return result
  }
}
