/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa

struct PositionedUtf16Cell {

  var utf16: [Unicode.UTF16.CodeUnit]
  var column: Int
}

struct CellIndexedUtf16Char {

  var codeUnit: Unicode.UTF16.CodeUnit
  var index: Int
}

struct Utf16IndexedGlyph {

  var glyph: CGGlyph

  var index: CFIndex

  var position: CGPoint
  var advance: CGSize
}

class Typesetter {

  func fontGlyphRunsWithLigatures(
    nvimUtf16Cells: [[Unicode.UTF16.CodeUnit]],
    startColumn: Int,
    yPosition: CGFloat,
    foreground: Int,
    font: NSFont,
    cellWidth: CGFloat
  ) -> [FontGlyphRun] {

    let utf16Chars = nvimUtf16Cells.flatMap { $0 }
    let ctRuns = self.ctRuns(
      from: utf16Chars, font: font, foreground: foreground
    )
    let utf16IndexedGlyphs = self.utf16IndexedGlyphs(from: ctRuns)

    let cellIndexedUtf16Chars = nvimUtf16Cells
      .filter { !$0.isEmpty }
      .enumerated()
      .map { element in
        element.1.map { utf16 in
          CellIndexedUtf16Char(codeUnit: utf16, index: element.0)
        }
      }
      .flatMap { $0 }

    let positionedCells = nvimUtf16Cells
      .enumerated()
      .compactMap { element -> PositionedUtf16Cell? in
        if element.1.isEmpty { return nil }

        return PositionedUtf16Cell(
          utf16: element.1, column: startColumn + element.0
        )
      }

    let groupedCellsAndGlyphs = self.groupUtf16CellsAndGlyphs(
      positionedCells: positionedCells,
      cellIndexedUtf16Chars: cellIndexedUtf16Chars,
      utf16IndexedGlyphs: utf16IndexedGlyphs
    )

    let stringRanges = ctRuns.map { run -> CountableRange<Int> in
      let range = CTRunGetStringRange(run)
      return range.location..<(range.location + range.length)
    }

    let fonts = ctRuns.map { run -> NSFont in
      guard
        let attrs = CTRunGetAttributes(run) as? [NSAttributedStringKey: Any],
        let font = attrs[NSAttributedStringKey.font] as? NSFont
        else {
        // FIXME: GH-666: Return the default font
        preconditionFailure("Could not get font from CTRun!")
      }

      return font
    }

    let fontRanges = self.groupByStringRanges(
      stringRanges: stringRanges, groupedCellsAndGlyphs: groupedCellsAndGlyphs
    )

    let cellsAndGlyphsGroupedByFont = fontRanges.map { range in
      Array(groupedCellsAndGlyphs[range])
    }

    let fontGlyphRuns = self.fontGlyphRuns(
      fonts: fonts,
      cellsAndGlyphsGroupedByFont: cellsAndGlyphsGroupedByFont,
      estimatedGlyphsCount: utf16Chars.count,
      cellWidth: cellWidth,
      yPosition: yPosition
    )

    return fontGlyphRuns
  }

  func fontGlyphRunsWithoutLigatures(
    nvimCells: [String],
    startColumn: Int,
    yPosition: CGFloat,
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
          yPosition: yPosition,
          foreground: foreground,
          font: font,
          cellWidth: cellWidth
        )
      }

      let unichars = run.nvimUtf16Cells.flatMap { $0 }
      var glyphs = Array<CGGlyph>(repeating: CGGlyph(), count: unichars.count)

      let gotAllGlyphs = CTFontGetGlyphsForCharacters(
        font, unichars, &glyphs, unichars.count
      )
      if gotAllGlyphs {
        let startColumnForPositions = startColumn + run.startColumn
        let endColumn = startColumnForPositions + glyphs.count
        let positions = (startColumnForPositions..<endColumn).map { i in
          CGPoint(
            x: CGFloat(i) * cellWidth,
            y: yPosition
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
            yPosition: yPosition,
            foreground: foreground,
            font: font,
            cellWidth: cellWidth
          )
        } else {
          let startColumnForPositions = startColumn + range.lowerBound
          let endColumn = startColumnForPositions + glyphs.count
          let positions = (startColumnForPositions..<endColumn).map { i in
            CGPoint(
              x: CGFloat(i + startColumn + range.lowerBound) * cellWidth,
              y: yPosition
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

  // For testing internal
  func groupUtf16CellsAndGlyphs(
    positionedCells: [PositionedUtf16Cell],
    cellIndexedUtf16Chars: [CellIndexedUtf16Char],
    utf16IndexedGlyphs: [Utf16IndexedGlyph]
  ) -> [([PositionedUtf16Cell], [Utf16IndexedGlyph])] {

    let utf16IndicesOfGlyphs = utf16IndexedGlyphs.map { $0.index }.uniqued()
    let extendedUtf16Indices
      = utf16IndicesOfGlyphs + [cellIndexedUtf16Chars.count]

    let utf16RangesOfGlyphs = (0..<utf16IndicesOfGlyphs.count).map { i in
      extendedUtf16Indices[i]..<extendedUtf16Indices[i + 1]
    }

    let nonUniqueGroupedUtf16CellIndices = utf16RangesOfGlyphs.map { range in
      cellIndexedUtf16Chars[range]
        .map { $0.index }
        .uniqued()
    }

    var groupedUtf16CellIndices = [[Int]]()
    groupedUtf16CellIndices.reserveCapacity(
      nonUniqueGroupedUtf16CellIndices.count
    )
    var lastIndex = -1
    nonUniqueGroupedUtf16CellIndices.forEach { element in
      guard let first = element.first, let last = element.last else {
        preconditionFailure("There are no first and last element in " +
                              "a grouped UTF16 cell indices " +
                              "non-unique collection!")
      }

      guard first > lastIndex else { return }
      groupedUtf16CellIndices.append(element)
      lastIndex = last
    }

    let groupedUtf16CellRanges = groupedUtf16CellIndices
      .map { ind -> CountableClosedRange<Int> in

      guard let first = ind.first, let last = ind.last else {
        preconditionFailure("There are no first and last element in " +
                              "a grouped UTF16 cell indices!")
      }

      return first...last
    }

    let partitionedUtf16Cells = groupedUtf16CellRanges.map { range in
      Array(positionedCells[range])
    }

    let partitionedGlyphs = utf16IndexedGlyphs
      .map { cellIndexedUtf16Chars[$0.index].index }
      .groupedRanges { _, cellIndexOfUtf16Index, _ in cellIndexOfUtf16Index }
      .map { Array(utf16IndexedGlyphs[$0]) }

    return Array(zip(partitionedUtf16Cells, partitionedGlyphs))
  }

  // For testing internal
  func groupByStringRanges(
    stringRanges: [CountableRange<Int>],
    groupedCellsAndGlyphs: [([PositionedUtf16Cell], [Utf16IndexedGlyph])]
  ) -> Array<CountableClosedRange<Int>> {
    var lastLength = 0
    var lastIndex = 0

    var result = Array<CountableClosedRange<Int>>()
    result.reserveCapacity(stringRanges.count)

    for range in stringRanges {
      for i in (lastIndex..<groupedCellsAndGlyphs.count) {
        lastLength += groupedCellsAndGlyphs[i].0.reduce(0) { result, element in
          result + element.utf16.count
        }
        if lastLength == range.upperBound {
          result.append(lastIndex...i)
          lastIndex = i + 1
          break
        }
      }
    }

    return result
  }

  private func fontGlyphRuns(
    fonts: [NSFont],
    cellsAndGlyphsGroupedByFont: [[([PositionedUtf16Cell], [Utf16IndexedGlyph])]],
    estimatedGlyphsCount: Int,
    cellWidth: CGFloat,
    yPosition: CGFloat
  ) -> [FontGlyphRun] {
    let zipped = zip(fonts, cellsAndGlyphsGroupedByFont)
    let fontGlyphRuns = zipped.map { zip -> FontGlyphRun in
      let font = zip.0
      let cellsAndGlyphs = zip.1

      var glyphs = Array<CGGlyph>()
      glyphs.reserveCapacity(estimatedGlyphsCount)
      var positions = Array<CGPoint>()
      positions.reserveCapacity(estimatedGlyphsCount)

      for element in cellsAndGlyphs {
        let cells = element.0
        let indexedGlyphs = element.1

        let startColumnPosition = CGFloat(cells[0].column) * cellWidth
        let deltaX = startColumnPosition - indexedGlyphs[0].position.x

        glyphs.append(contentsOf: indexedGlyphs.map { $0.glyph })
        positions.append(contentsOf: indexedGlyphs.map { indexedGlyph in
          CGPoint(x: indexedGlyph.position.x + deltaX, y: yPosition)
        })
      }

      // FIXME: GH-666: Proper error handling
      if glyphs.count != positions.count {
        print("Counts of glyphs and positions are not the same")
      }

      return FontGlyphRun(
        font: font, glyphs: glyphs, positions: positions
      )
    }

    return fontGlyphRuns
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

  private func utf16IndexedGlyphs(
    from ctRuns: [CTRun]
  ) -> [Utf16IndexedGlyph] {
    let utf16IndexedGlyphs = ctRuns
      .map { run -> [Utf16IndexedGlyph] in
        let glyphCount = CTRunGetGlyphCount(run)

        var indices = Array(repeating: CFIndex(), count: glyphCount)
        CTRunGetStringIndices(run, .zero, &indices)

        var glyphs = Array(repeating: CGGlyph(), count: glyphCount)
        CTRunGetGlyphs(run, .zero, &glyphs)

        var positions = Array(repeating: CGPoint.zero, count: glyphCount)
        CTRunGetPositions(run, .zero, &positions)

        var advances = Array(repeating: CGSize.zero, count: glyphCount)
        CTRunGetAdvances(run, .zero, &advances)

        return (0..<glyphCount).map { i in
          Utf16IndexedGlyph(
            glyph: glyphs[i],
            index: indices[i],
            position: positions[i],
            advance: advances[i]
          )
        }
      }
      .flatMap { $0 }

    return utf16IndexedGlyphs
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
