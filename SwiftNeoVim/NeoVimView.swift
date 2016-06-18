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

private struct RowFragment: CustomStringConvertible {

  let row: Int
  let range: Range<Int>

  var description: String {
    return "RowFragment<\(row): \(range)>"
  }
}

private struct AttributedRowFragment: CustomStringConvertible {

  let row: Int
  let range: Range<Int>
  let attrs: CellAttributes

  var description: String {
    return "AttributedRowFragment<\(row): \(range)\n\(attrs)>"
  }
}

public class NeoVimView: NSView {
  
  public var delegate: NeoVimViewDelegate?

  private let qDispatchMainQueue = dispatch_get_main_queue()

  private var font: NSFont {
    didSet {
      self.drawer.font = self.font
      self.cellSize = self.drawer.cellSize
      self.lineSpace = self.drawer.lineSpace
      
      // FIXME: resize and redraw
    }
  }
  
  private let xpc: NeoVimXpc
  private let drawer: TextDrawer
  
  private var cellSize = CGSize.zero
  private var lineSpace = CGFloat(0)

  private let grid = Grid()

  init(frame rect: NSRect = CGRect.zero, xpc: NeoVimXpc) {
    self.xpc = xpc
    
    self.font = NSFont(name: "Menlo", size: 13)!
    self.drawer = TextDrawer(font: font)
    
    super.init(frame: rect)
    
    self.wantsLayer = true
    self.cellSize = self.drawer.cellSize
    self.lineSpace = self.drawer.lineSpace
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

    self.attributedRowFragmentsIntersecting(rects: dirtyRects).forEach { rowFrag in
      let positions = rowFrag.range
        // filter out the put(0, 0)s (after a wide character)
        .filter { self.grid.cells[rowFrag.row][$0].string.characters.count > 0 }
        .map { self.positionOnView(rowFrag.row, column: $0) }

      self.drawBackground(positions: positions, background: rowFrag.attrs.background)

      let string = self.grid.cells[rowFrag.row][rowFrag.range].reduce("") { $0 + $1.string }
      let glyphPositions = positions.map { CGPoint(x: $0.x, y: $0.y + self.lineSpace) }
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

  private func attributedRowFragmentsIntersecting(rects rects: [CGRect]) -> [AttributedRowFragment] {
    return self.rowFragmentsIntersecting(rects: rects)
      .map { rowFrag -> [AttributedRowFragment] in
        let row = rowFrag.row
        let rowCells = self.grid.cells[rowFrag.row]
        let range = rowFrag.range
        let startIndex = range.startIndex

        var result = [
          AttributedRowFragment(row: row, range: startIndex...startIndex, attrs: rowCells[startIndex].attrs)
        ]
        range.forEach { idx in
          if rowCells[idx].attrs == result.last!.attrs {
            let last = result.popLast()!
            result.append(AttributedRowFragment(row: row, range: last.range.startIndex...idx, attrs: last.attrs))
          } else {
            result.append(AttributedRowFragment(row: row, range: idx...idx, attrs: rowCells[idx].attrs))
          }
        }

        return result
      }
      .flatMap { $0 }
  }

  private func rowFragmentsIntersecting(rects rects: [CGRect]) -> [RowFragment] {
    return rects
      .map { rect -> Region in
        let rowStart = Int(floor((self.frame.height - (rect.origin.y + rect.size.height)) / self.cellSize.height))
        let rowEnd = Int(ceil((self.frame.height - rect.origin.y) / self.cellSize.height)) - 1
        let columnStart = Int(floor(rect.origin.x / self.cellSize.width))
        let columnEnd = Int(ceil((rect.origin.x + rect.size.width) / self.cellSize.width)) - 1
        return Region(top: rowStart, bottom: rowEnd, left: columnStart, right: columnEnd)
      } // There can be overlaps between the Regions, but for the time being we ignore them.
      .map { region -> [RowFragment] in
        return (region.rowRange).map { RowFragment(row: $0, range: region.columnRange) }
      }
      .flatMap { $0 }
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
//      Swift.print("before scroll: \(self.grid)")
      self.grid.scroll(Int(count))
//      Swift.print("after scroll: \(self.grid)")

      let top = CGFloat(self.grid.region.top)
      let bottom = CGFloat(self.grid.region.bottom)
      let left = CGFloat(self.grid.region.left)
      let right = CGFloat(self.grid.region.right)

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
    //    Swift.print("### update fg: \(colorFromCode(fg))")
  }
  
  public func updateBackground(bg: Int32) {
    //    Swift.print("### update bg: \(colorFromCode(bg, kind: .Background))")
  }
  
  public func updateSpecial(sp: Int32) {
    //    Swift.print("### update sp: \(colorFromCode(sp, kind: .Special))")
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
