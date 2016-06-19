/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa

func == (left: CellAttributes, right: CellAttributes) -> Bool {
  if left.foreground != right.foreground { return false }
  if left.fontTrait != right.fontTrait { return false }

  if left.background != right.background { return false }
  if left.special != right.special { return false }

  return true
}

func != (left: CellAttributes, right: CellAttributes) -> Bool {
  return !(left == right)
}

extension CellAttributes: CustomStringConvertible {
  
  public var description: String {
    return "CellAttributes<fg: \(String(format: "%x", self.foreground)), bg: \(String(format: "%x", self.background)))"
  }
}

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

  private let qDispatchMainQueue = dispatch_get_main_queue()

  private var font: NSFont {
    didSet {
      self.drawer.font = self.font
      self.cellSize = self.drawer.cellSize
      self.descent = self.drawer.descent
      self.leading = self.drawer.leading
      
      // FIXME: resize and redraw
    }
  }
  
  private let xpc: NeoVimXpc
  private let drawer: TextDrawer
  
  private var cellSize = CGSize.zero
  private var descent = CGFloat(0)
  private var leading = CGFloat(0)

  private let grid = Grid()

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
  
  override public func keyDown(theEvent: NSEvent) {
    self.xpc.vimInput(theEvent.charactersIgnoringModifiers!)
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

  private func positionOnView(row: Int, column: Int) -> CGPoint {
    return CGPoint(
      x: CGFloat(column) * self.cellSize.width,
      y: self.frame.size.height - CGFloat(row) * self.cellSize.height - self.cellSize.height
    )
  }

  private func gui(call: () -> Void) {
    dispatch_async(qDispatchMainQueue, call)
  }
  
  required public init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

extension NeoVimView: NeoVimUiBridgeProtocol {

  public func resizeToWidth(width: Int32, height: Int32) {
    let rectSize = CGSizeMake(
      CGFloat(width) * self.cellSize.width,
      CGFloat(height) * self.cellSize.height
    )
    
    gui {
      Swift.print("### resize to \(width):\(height)")
      self.grid.resize(Size(width: Int(width), height: Int(height)))
      self.delegate?.resizeToSize(rectSize)
    }
  }
  
  public func clear() {
    gui {
      Swift.print("### clear")
      self.grid.clear()
      self.needsDisplay = true
    }
  }
  
  public func eolClear() {
    gui {
      Swift.print("### eol clear")
      self.grid.eolClear()

      let origin = self.positionOnView(self.grid.position.row, column: self.grid.position.column)
      let size = CGSize(
        width: CGFloat(self.grid.region.right - self.grid.position.column + 1) * self.cellSize.width,
        height: self.cellSize.height
      )
      let rect = CGRect(origin: origin, size: size)
      self.setNeedsDisplayInRect(rect)
    }
  }
  
  public func cursorGotoRow(row: Int32, column: Int32) {
    gui {
      Swift.print("### goto: \(row):\(column)")
      self.grid.goto(Position(row: Int(row), column: Int(column)))
    }
  }
  
  public func updateMenu() {
    //    Swift.print("### update menu")
  }
  
  public func busyStart() {
    //    Swift.print("### busy start")
  }
  
  public func busyStop() {
    //    Swift.print("### busy stop")
  }
  
  public func mouseOn() {
    //    Swift.print("### mouse on")
  }
  
  public func mouseOff() {
    //    Swift.print("### mouse off")
  }
  
  public func modeChange(mode: Int32) {
    //    Swift.print("### mode change to: \(String(format: "%04X", mode))")
  }
  
  public func setScrollRegionToTop(top: Int32, bottom: Int32, left: Int32, right: Int32) {
    Swift.print("### set scroll region: \(top), \(bottom), \(left), \(right)")
    gui {
      self.grid.setScrollRegion(Region(top: Int(top), bottom: Int(bottom), left: Int(left), right: Int(right)))
    }
  }
  
  public func scroll(count: Int32) {
    Swift.print("### scroll count: \(count)")

    gui {
      self.grid.scroll(Int(count))

      let region = self.grid.region
      let top = CGFloat(region.top)
      let bottom = CGFloat(region.bottom)
      let left = CGFloat(region.left)
      let right = CGFloat(region.right)

      let width = right - left + 1
      let height = bottom - top + 1

      let rect = CGRect(x: left * self.cellSize.width, y: bottom * self.cellSize.height,
                        width: width * self.cellSize.width, height: height * self.cellSize.height)
      self.setNeedsDisplayInRect(rect)
    }
  }
  
  public func highlightSet(attrs: CellAttributes) {
    gui {
//      Swift.print("### set highlight")
      self.grid.attrs = attrs
    }
  }
  
  public func put(string: String) {
    gui {
      let curPos = Position(row: self.grid.position.row, column: self.grid.position.column)
      self.grid.put(string)

//      Swift.print("### put: \(curPos) -> '\(string)'")

      let rect = CGRect(origin: self.positionOnView(curPos.row, column: curPos.column), size: self.cellSize)
      self.setNeedsDisplayInRect(rect)
    }
  }
  
  public func bell() {
    gui {
      NSBeep()
    }
  }
  
  public func visualBell() {
    //    Swift.print("### visual bell")
  }
  
  public func flush() {
//    gui {
//      Swift.print("### flush")
//    }
  }
  
  public func updateForeground(fg: Int32) {
//      Swift.print("### update fg: \(String(format: "%x", fg))")
    gui {
      self.grid.foreground = UInt32(bitPattern: fg)
    }
  }
  
  public func updateBackground(bg: Int32) {
//      Swift.print("### update bg: \(String(format: "%x", bg))")
    gui {
      self.grid.background = UInt32(bitPattern: bg)
    }
  }
  
  public func updateSpecial(sp: Int32) {
//      Swift.print("### update sp: \(String(format: "%x", sp)")
    gui {
      self.grid.special = UInt32(bitPattern: sp)
    }
  }
  
  public func suspend() {
    //    Swift.print("### suspend")
  }
  
  public func setTitle(title: String) {
    self.delegate?.setTitle(title)
  }
  
  public func setIcon(icon: String) {
    //    Swift.print("### set icon: \(icon)")
  }
  
  public func stop() {
    Swift.print("### stop")
  }
}
