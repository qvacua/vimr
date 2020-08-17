/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 *
 * 0.json from: https://github.com/gshslatexintro/An-Introduction-to-LaTeX
 * 1.json from @telemachus
 * 2.json from http://generator.lorem-ipsum.info
 */

import Cocoa
import GameKit
import os

class PerfTester {

  init() {
    self.cellSize = FontUtils.cellSize(of: self.font, linespacing: 1.25, characterspacing: 1)

    for name in ["0", "1", "2"] {
      guard let fileUrl = Bundle(for: PerfTester.self)
        .url(forResource: name, withExtension: "json")
        else {
        preconditionFailure("Could not find \(name).json")
      }

      let decoder = JSONDecoder()
      do {
        let data = try Data(contentsOf: fileUrl)
        self.ugrids.append(try decoder.decode(UGrid.self, from: data))
      } catch {
        preconditionFailure("Couldn't decode UGrid from \(name).json: \(error)")
      }
    }

    self.initAttrs()
  }

  func render(_ index: Int) -> [[FontGlyphRun]] {
    precondition((0...2).contains(index), "Wrong index!")

    let ugrid = self.ugrids[index]
    let runs = self.runs(index,
                         forRowRange: 0...ugrid.size.height - 1,
                         columnRange: 0...ugrid.size.width - 1)

    return runs.parallelMap(chunkSize: 50) { run in
      let font = FontUtils.font(
        adding: run.attrs.fontTrait, to: self.font
      )

      return self.typesetter.fontGlyphRunsWithLigatures(
        nvimUtf16Cells: run.cells.map { Array($0.string.utf16) },
        startColumn: run.cells.startIndex,
        offset: .zero,
        font: font,
        cellWidth: 20)
    }
  }

  private var ugrids = [UGrid]()
  private let cellAttrsCollection = CellAttributesCollection()
  private let typesetter = Typesetter()
  private let font = NSFont.userFixedPitchFont(ofSize: 13)!
  private let cellSize: CGSize

  private func runs(
    _ index: Int,
    forRowRange rowRange: CountableClosedRange<Int>,
    columnRange: CountableClosedRange<Int>
  ) -> [AttributesRun] {
    precondition(0 <= index && index <= 2, "Wrong index!")

    let ugrid = self.ugrids[index]
    return rowRange.map { row in
        ugrid.cells[row][columnRange]
          .groupedRanges(with: { _, cell in cell.attrId })
          .compactMap { range in
            let cells = ugrid.cells[row][range]

            guard let firstCell = cells.first,
                  let attrs = self.cellAttrsCollection.attributes(
                    of: firstCell.attrId
                  )
              else {
              // GH-666: FIXME: correct error handling
              self.log.error("row: \(row), range: \(range): " +
                             "Could not get CellAttributes with ID " +
                             "\(String(describing: cells.first?.attrId))")
              return nil
            }

            return AttributesRun(
              location: CGPoint.zero,
              cells: ugrid.cells[row][range],
              attrs: attrs
            )
          }
      }
      .flatMap { $0 }
  }

  private let fontTraitRd = GKRandomDistribution(
    randomSource: randomSource,
    lowestValue: 0,
    highestValue: 6
  )

  private let intColorRd = GKRandomDistribution(
    randomSource: randomSource,
    lowestValue: 0,
    highestValue: 16777215
  )

  private let attrsRunRd = GKRandomDistribution(
    randomSource: randomSource,
    lowestValue: 0,
    highestValue: 10
  )

  private let log = OSLog(subsystem: "com.qvacua.DrawerPerf",
                          category: "perf-tester")

  private func initAttrs() {
    for i in (1..<200) {
      self.cellAttrsCollection.set(attributes: self.randomCellAttrs(), for: i)
    }
  }

  private func randomCellAttrs() -> CellAttributes {
    return CellAttributes(fontTrait: self.randomFontTrait(),
                          foreground: self.intColorRd.nextInt(),
                          background: self.intColorRd.nextInt(),
                          special: self.intColorRd.nextInt(),
                          reverse: false)
  }

  private func randomFontTrait() -> FontTrait {
    switch self.fontTraitRd.nextInt() {
    case 0: return []
    case 1: return [.italic]
    case 2: return [.bold]
    case 3: return [.underline]
    case 4: return [.undercurl]
    case 5: return [.italic, .bold]
    case 6: return [.bold, .underline]
    default: return []
    }
  }
}

private let randomSource = GKMersenneTwisterRandomSource(seed: 95749272934)
