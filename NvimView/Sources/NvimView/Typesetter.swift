/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import Commons
import os

final class Typesetter {
  func clearCache() {
    self.ctRunsCache.clear()
  }

  func fontGlyphRunsWithLigatures(
    nvimUtf16Cells: [[Unicode.UTF16.CodeUnit]],
    startColumn: Int,
    offset: CGPoint,
    font: NSFont,
    cellWidth: CGFloat
  ) -> [FontGlyphRun] {
    let utf16Chars = self.utf16Chars(from: nvimUtf16Cells)
    let cellIndices = self.cellIndices(from: nvimUtf16Cells, utf16CharsCount: utf16Chars.count)
    let ctRuns = self.ctRuns(from: utf16Chars, font: font)

    return ctRuns.withUnsafeBufferPointer { pointer -> [FontGlyphRun] in
      // Tried to use Array(unsafeUninitializedCapacity, initializingWith:) for result,
      // but I get EXC_BAD_ACCESS, I don't know why.
      var result: [FontGlyphRun] = []
      result.reserveCapacity(pointer.count)

      for k in 0..<pointer.count {
        let run = pointer[k]

        let glyphCount = CTRunGetGlyphCount(run)

        // swiftlint:disable force_unwrapping
        let glyphs = [CGGlyph](unsafeUninitializedCapacity: glyphCount) { buffer, count in
          CTRunGetGlyphs(run, .zero, buffer.baseAddress!)
          count = glyphCount
        }

        var positions = [CGPoint](unsafeUninitializedCapacity: glyphCount) { buffer, count in
          CTRunGetPositions(run, .zero, buffer.baseAddress!)
          count = glyphCount
        }

        let indices = [CFIndex](unsafeUninitializedCapacity: glyphCount) { buffer, count in
          CTRunGetStringIndices(run, .zero, buffer.baseAddress!)
          count = glyphCount
        }
        // swiftlint:enable force_unwrapping

        var column = -1
        var columnPosition = 0.0
        var deltaX = 0.0

        positions.withUnsafeMutableBufferPointer { positionsPtr in
          for i in 0..<positionsPtr.count {
            let newColumn = cellIndices[indices[i]] + startColumn
            if newColumn != column {
              columnPosition = offset.x + newColumn.cgf * cellWidth
              deltaX = columnPosition - positionsPtr[i].x
              column = newColumn
            }
            positionsPtr[i].x += deltaX
            positionsPtr[i].y += offset.y
          }
        }

        let attrs = CTRunGetAttributes(run)
        let font = Unmanaged<NSFont>.fromOpaque(
          CFDictionaryGetValue(attrs, Unmanaged.passUnretained(kCTFontAttributeName).toOpaque())
        ).takeUnretainedValue()

        result.append(FontGlyphRun(font: font, glyphs: glyphs, positions: positions))
      }

      return result
    }
  }

  func fontGlyphRunsWithoutLigatures(
    nvimUtf16Cells: [[Unicode.UTF16.CodeUnit]],
    startColumn: Int,
    offset: CGPoint,
    font: NSFont,
    cellWidth: CGFloat
  ) -> [FontGlyphRun] {
    let nvimUtf16CellsRuns = self.groupSimpleAndNonSimpleChars(
      nvimUtf16Cells: nvimUtf16Cells, font: font
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
      var glyphs = [CGGlyph](repeating: CGGlyph(), count: unichars.count)

      let gotAllGlyphs = CTFontGetGlyphsForCharacters(font, unichars, &glyphs, unichars.count)
      if gotAllGlyphs {
        let startColumnForPositions = startColumn + run.startColumn
        let endColumn = startColumnForPositions + glyphs.count
        let positions = (startColumnForPositions..<endColumn).map { i in
          CGPoint(x: offset.x + i.cgf * cellWidth, y: offset.y)
        }

        return [FontGlyphRun(font: font, glyphs: glyphs, positions: positions)]
      }

      let groupRanges = glyphs.groupedRanges { element in element == 0 }
      let groupRuns: [[FontGlyphRun]] = groupRanges.map { range in
        if glyphs[range.lowerBound] == 0 {
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
          let endColumn = startColumnForPositions + range.count
          let positions = (startColumnForPositions..<endColumn).map { i in
            CGPoint(x: offset.x + i.cgf * cellWidth, y: offset.y)
          }

          return [FontGlyphRun(font: font, glyphs: Array(glyphs[range]), positions: positions)]
        }
      }

      return groupRuns.flatMap { $0 }
    }

    return runs.flatMap { $0 }
  }

  private func ctRuns(from utf16Chars: [Unicode.UTF16.CodeUnit], font: NSFont) -> [CTRun] {
    if let ctRunsAndFont = self.ctRunsCache.valueForKey(utf16Chars) { return ctRunsAndFont }

    let attrStr = NSAttributedString(
      string: String(utf16CodeUnits: utf16Chars, count: utf16Chars.count),
      attributes: [.font: font, .ligature: ligatureOption]
    )

    let ctLine = CTLineCreateWithAttributedString(attrStr)
    guard let ctRuns = CTLineGetGlyphRuns(ctLine) as? [CTRun] else { return [] }

    self.ctRunsCache.set(ctRuns, forKey: utf16Chars)

    return ctRuns
  }

  private func groupSimpleAndNonSimpleChars(
    nvimUtf16Cells: [[Unicode.UTF16.CodeUnit]],
    font _: NSFont
  ) -> [NvimUtf16CellsRun] {
    if nvimUtf16Cells.isEmpty { return [] }

    let hasMoreThanTwoCells = nvimUtf16Cells.count >= 2
    let firstCharHasSingleUnichar = nvimUtf16Cells[0].count == 1
    let firstCharHasDoubleWidth = hasMoreThanTwoCells && nvimUtf16Cells[1].isEmpty

    var result = [NvimUtf16CellsRun]()
    result.reserveCapacity(nvimUtf16Cells.count)

    let inclusiveEndIndex = nvimUtf16Cells.endIndex - 1
    var previousWasSimple = firstCharHasSingleUnichar && !firstCharHasDoubleWidth
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
      let hasDoubleWidth = i + 1 < nvimUtf16Cells.count && nvimUtf16Cells[i + 1].isEmpty
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

  private func cellIndices(
    from nvimUtf16Cells: [[Unicode.UTF16.CodeUnit]],
    utf16CharsCount: Int
  ) -> [Int] {
    nvimUtf16Cells.withUnsafeBufferPointer { pointer -> [Int] in
      var cellIndices = Array(repeating: 0, count: utf16CharsCount)
      var cellIndex = 0
      var i = 0

      repeat {
        if pointer[cellIndex].isEmpty {
          cellIndex = cellIndex &+ 1
          continue
        }

        for _ in 0..<pointer[cellIndex].count {
          cellIndices[i] = cellIndex
          i = i + 1
        }
        cellIndex = cellIndex &+ 1
      } while cellIndex < pointer.count

      return cellIndices
    }
  }

  private func utf16Chars(from nvimUtf16Cells: [[Unicode.UTF16.CodeUnit]]) -> [UInt16] {
    nvimUtf16Cells.withUnsafeBufferPointer { pointer -> [UInt16] in
      let count = pointer.reduce(0) { acc, elem in acc + elem.count }

      return [Unicode.UTF16.CodeUnit](unsafeUninitializedCapacity: count) { resultPtr, initCount in
        var i = 0
        for k in 0..<pointer.count {
          let element = pointer[k]
          if element.isEmpty { continue }

          for j in 0..<element.count {
            resultPtr[i + j] = element[j]
          }

          i = i + element.count
        }
        initCount = count
      }
    }
  }

  private let ctRunsCache = FifoCache<[Unicode.UTF16.CodeUnit], [CTRun]>(count: 5000)

  private let log = OSLog(subsystem: Defs.loggerSubsystem, category: Defs.LoggerCategory.view)

  private struct NvimUtf16CellsRun {
    var startColumn: Int
    var nvimUtf16Cells: [[Unicode.UTF16.CodeUnit]]
    var isSimple: Bool
  }
}

private let ligatureOption = NSNumber(integerLiteral: 1)
