/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa

/// Contiguous piece of cells of a row that has the same attributes.
private struct RowRun: CustomStringConvertible {

  let row: Int
  let range: Range<Int>
  let attrs: CellAttributes

  var description: String {
    return "RowRun<\(row): \(range)\n\(attrs)>"
  }
}

public class NeoVimView: NSView {
  
  public var delegate: NeoVimViewDelegate?

  private var font: NSFont {
    didSet {
      self.drawer.font = self.font
      self.cellSize = self.drawer.cellSize
      self.descent = self.drawer.descent
      self.leading = self.drawer.leading
      
      // FIXME: resize and redraw
    }
  }
  
  private let drawer: TextDrawer

  let xpc: NeoVimXpc

  var markedText: String?
  var keyDownDone = true
  
  var cellSize = CGSize.zero
  var descent = CGFloat(0)
  var leading = CGFloat(0)

  let grid = Grid()

  init(frame rect: NSRect = CGRect.zero, xpc: NeoVimXpc) {
    self.xpc = xpc
    
    self.font = NSFont(name: "Menlo", size: 16)!
    self.drawer = TextDrawer(font: font)
    
    super.init(frame: rect)
    
    self.wantsLayer = true
    self.cellSize = self.drawer.cellSize
    self.descent = self.drawer.descent
    self.leading = self.drawer.leading
  }

  override public func drawRect(dirtyUnionRect: NSRect) {
    guard self.grid.hasData else {
      return
    }
    
    let context = NSGraphicsContext.currentContext()!.CGContext

    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
    CGContextSetTextDrawingMode(context, .Fill);

    let dirtyRects = self.rectsBeingDrawn()

    self.rowRunIntersecting(rects: dirtyRects).forEach { rowFrag in
      let positions = rowFrag.range
        // filter out the put(0, 0)s (after a wide character)
        .filter { self.grid.cells[rowFrag.row][$0].string.characters.count > 0 }
        .map { self.positionOnView(rowFrag.row, column: $0) }

      self.drawBackground(positions: positions, background: rowFrag.attrs.background)

      let string = self.grid.cells[rowFrag.row][rowFrag.range].reduce("") { $0 + $1.string }
      let glyphPositions = positions.map { CGPoint(x: $0.x, y: $0.y + self.descent + self.leading) }
      self.drawer.drawString(string,
                             positions: UnsafeMutablePointer(glyphPositions), positionsCount: positions.count,
                             highlightAttrs: rowFrag.attrs,
                             context: context)
    }
  }

  private func drawBackground(positions positions: [CGPoint], background: UInt32) {
    ColorUtils.colorFromCodeIgnoringAlpha(background).set()
    let backgroundRect = CGRect(
      x: positions[0].x, y: positions[0].y,
      width: positions.last!.x + self.cellSize.width, height: self.cellSize.height
    )
    backgroundRect.fill()
  }

  private func rowRunIntersecting(rects rects: [CGRect]) -> [RowRun] {
    return rects
      .map { rect -> Region in
        // Get all Regions that intersects with the given rects. There can be overlaps between the Regions, but for the
        // time being we ignore them; probably not necessary to optimize them away.
        let rowStart = Int(floor((self.frame.height - (rect.origin.y + rect.size.height)) / self.cellSize.height))
        let rowEnd = Int(ceil((self.frame.height - rect.origin.y) / self.cellSize.height)) - 1
        let columnStart = Int(floor(rect.origin.x / self.cellSize.width))
        let columnEnd = Int(ceil((rect.origin.x + rect.size.width) / self.cellSize.width)) - 1
        
        return Region(top: rowStart, bottom: rowEnd, left: columnStart, right: columnEnd)
      }
      .map { region -> [RowRun] in
        // Map Regions to RowRuns for drawing.
        return region.rowRange
          // Map each row in a Region to RowRuns
          .map { row -> [RowRun] in
            let columns = region.columnRange
            let rowCells = self.grid.cells[row]
            let startIndex = columns.startIndex
            
            var result = [ RowRun(row: row, range: startIndex...startIndex, attrs: rowCells[startIndex].attrs) ]
            columns.forEach { idx in
              if rowCells[idx].attrs == result.last!.attrs {
                let last = result.popLast()!
                result.append(RowRun(row: row, range: last.range.startIndex...idx, attrs: last.attrs))
              } else {
                result.append(RowRun(row: row, range: idx...idx, attrs: rowCells[idx].attrs))
              }
            }
            
            return result // All RowRuns for a row in a Region.
          }               // All RowRuns for all rows in a Region grouped by row.
          .flatMap { $0 } // Flattened RowRuns for a Region.
      }                   // All RowRuns for all Regions grouped by Region.
      .flatMap { $0 }     // Flattened RowRuns for all Regions.
  }

  func positionOnView(row: Int, column: Int) -> CGPoint {
    return CGPoint(
      x: CGFloat(column) * self.cellSize.width,
      y: self.frame.size.height - CGFloat(row) * self.cellSize.height - self.cellSize.height
    )
  }

  func cellRect(row: Int, column: Int) -> CGRect {
    return CGRect(origin: self.positionOnView(row, column: column), size: self.cellSize)
  }

  required public init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

