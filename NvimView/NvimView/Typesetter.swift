/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa

class Typesetter {

  final func fontGlyphRunsWithLigatures(
    nvimUtf16Cells: [[Unicode.UTF16.CodeUnit]],
    startColumn: Int,
    offset: CGPoint,
    foreground: Int,
    font: NSFont,
    cellWidth: CGFloat
  ) -> [FontGlyphRun] {

    let utf16Chars = self.utf16Chars(from: nvimUtf16Cells)
    let cellIndices = self.cellIndices(
      from: nvimUtf16Cells,
      utf16CharsCount: utf16Chars.count
    )
    let ctRuns = self.ctRuns(
      from: utf16Chars, font: font, foreground: foreground
    )

    var result = Array<FontGlyphRun>()
    result.reserveCapacity(ctRuns.count)
    for run in ctRuns {
      let glyphCount = CTRunGetGlyphCount(run)

      var glyphs = Array(repeating: CGGlyph(), count: glyphCount)
      CTRunGetGlyphs(run, .zero, &glyphs)

      var positions = Array(repeating: CGPoint.zero, count: glyphCount)
      CTRunGetPositions(run, .zero, &positions)

      var indices = Array(repeating: CFIndex(), count: glyphCount)
      CTRunGetStringIndices(run, .zero, &indices)

      var advances = Array(repeating: CGSize.zero, count: glyphCount)
      CTRunGetAdvances(run, .zero, &advances)

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

      guard
        let attrs = CTRunGetAttributes(run) as? [NSAttributedStringKey: Any],
        let font = attrs[NSAttributedStringKey.font] as? NSFont
        else {
        // FIXME: GH-666: Return the default font
        preconditionFailure("Could not get font from CTRun!")
      }

      let fontGlyphRun = FontGlyphRun(
        font: font, glyphs: glyphs, positions: positions
      )

      result.append(fontGlyphRun)
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
      defer { cellIndex += 1 }

      if nvimUtf16Cells[cellIndex].isEmpty {
        continue
      }

      for _ in (0..<nvimUtf16Cells[cellIndex].count) {
        cellIndices[i] = cellIndex
        i += 1
      }
    } while cellIndex < nvimUtf16Cells.count

    return cellIndices
  }

  private func utf16Chars(from nvimUtf16Cells: [[Unicode.UTF16.CodeUnit]]) -> Array<UInt16> {
    var utf16Chars = Array<Unicode.UTF16.CodeUnit>()
    utf16Chars.reserveCapacity(Int(Double(nvimUtf16Cells.count) * 1.5))

    for i in 0..<nvimUtf16Cells.count {
      utf16Chars.append(contentsOf: nvimUtf16Cells[i])
    }

    return utf16Chars
  }

  final func fontGlyphRunsWithoutLigatures(
    nvimCells: [String],
    startColumn: Int,
    offset: CGPoint,
    foreground: Int,
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
          foreground: foreground,
          font: font,
          cellWidth: cellWidth
        )
      }

      let unichars = self.utf16Chars(from: run.nvimUtf16Cells)
      var glyphs = Array<CGGlyph>(repeating: CGGlyph(), count: unichars.count)

      let gotAllGlyphs = CTFontGetGlyphsForCharacters(
        font, unichars, &glyphs, unichars.count
      )
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
      let groupRanges = glyphs.groupedRanges { _, element, _ in element == 0 }
      let groupRuns: [[FontGlyphRun]] = groupRanges.map { range in
        if unichars[range.lowerBound] == 0 {
          let nvimUtf16Cells = unichars[range].map { [$0] }
          return self.fontGlyphRunsWithLigatures(
            nvimUtf16Cells: nvimUtf16Cells,
            startColumn: startColumn + range.lowerBound,
            offset: offset,
            foreground: foreground,
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
    from utf16Chars: [Unicode.UTF16.CodeUnit],
    font: NSFont,
    foreground: Int
  ) -> [CTRun] {
    let attrStr = NSAttributedString(
      string: String(utf16CodeUnits: utf16Chars, count: utf16Chars.count),
      attributes: [
        .font: font,
        .foregroundColor: ColorUtils.cgColorIgnoringAlpha(foreground),
        .ligature: 1,
      ]
    )
    let ctLine = CTLineCreateWithAttributedString(attrStr)

    guard let ctRuns = CTLineGetGlyphRuns(ctLine) as? [CTRun] else { return [] }
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
    let utf16Chars = nvimUtf16Cells.flatMap { $0 }

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
