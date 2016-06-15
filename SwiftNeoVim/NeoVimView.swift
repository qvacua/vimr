/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import RxSwift

struct RowFragment: CustomStringConvertible {

  let row: Int
  let range: Range<Int>

  var description: String {
    return "RowFragment<\(row): \(range)>"
  }
}

public class NeoVimView: NSView {
  
  public var delegate: NeoVimViewDelegate?

  private let qDispatchMainQueue = dispatch_get_main_queue()
  private let qLineGap = CGFloat(4)
  
  private var foregroundColor = Int32(bitPattern: UInt32(0xFF000000))
  private var backgroundColor = Int32(bitPattern: UInt32(0xFFFFFFFF))
  private var font = NSFont(name: "Menlo", size: 13)!
  
  private let xpc: NeoVimXpc
  private let drawer = TextDrawer()
  
  private var cellSize: CGSize = CGSizeMake(0, 0)

  private let grid = Grid()

  init(frame rect: NSRect = CGRect.zero, xpc: NeoVimXpc) {
    self.xpc = xpc
    super.init(frame: rect)

    self.wantsLayer = true

    // hard-code some stuff
    let attrs = [ NSFontAttributeName: self.font ]
    let width = ceil(" ".sizeWithAttributes(attrs).width)
    let height = ceil(self.font.ascender - self.font.descender + self.font.leading) + qLineGap
    self.cellSize = CGSize(width: width, height: height)
  }
  
  override public func keyDown(theEvent: NSEvent) {
    self.xpc.vimInput(theEvent.charactersIgnoringModifiers!)
  }

  override public func drawRect(dirtyUnionRect: NSRect) {
    guard self.grid.hasData else {
      return
    }

//    Swift.print("------- DRAW")

    let context = NSGraphicsContext.currentContext()!.CGContext

    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
    CGContextSetTextDrawingMode(context, .Fill);

    self.rowFragmentsIntersecting(rects: self.rectsBeingDrawn()).forEach { rowFrag in
      let string = self.grid.cells[rowFrag.row][rowFrag.range].reduce("") { $0 + $1.string }
      let positions = rowFrag.range
        // filter out the put(0, 0)s (after a wide character)
        .filter { self.grid.cells[rowFrag.row][$0].string.characters.count > 0 }
        .map { self.originOnView(rowFrag.row, column: $0) }

      ColorUtils.colorFromCode(self.backgroundColor).set()
      let backgroundRect = CGRect(
        x: positions[0].x, y: positions[0].y,
        width: positions.last!.x + self.cellSize.width, height: self.cellSize.height
      )
      NSRectFill(backgroundRect)

      ColorUtils.colorFromCode(self.foregroundColor).set()
      let glyphPositions = positions.map { CGPoint(x: $0.x, y: $0.y + qLineGap) }
      self.drawer.drawString(
        string, positions: UnsafeMutablePointer(glyphPositions),
        font: self.font, foreground: self.foregroundColor, background: self.backgroundColor,
        context: context
      )
    }
//    Swift.print("------- DRAW END")
  }

  private func rowFragmentsIntersecting(rects rects: [CGRect]) -> [RowFragment] {
    return rects
      .map { rect -> Region in
        let rowStart = Int(floor((self.frame.height - (rect.origin.y + rect.size.height)) / self.cellSize.height))
        let rowEnd = Int(ceil((self.frame.height - rect.origin.y) / self.cellSize.height)) - 1
        let columnStart = Int(floor(rect.origin.x / self.cellSize.width))
        let columnEnd = Int(ceil((rect.origin.x + rect.size.width) / self.cellSize.width)) - 1
        return Region(top: rowStart, bottom: rowEnd, left: columnStart, right: columnEnd)
      }
      .map { region -> [RowFragment] in
        return (region.rowRange).map { RowFragment(row: $0, range: region.columnRange) }
      }
      .flatMap { $0 }
  }

  private func originOnView(row: Int, column: Int) -> CGPoint {
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

      let origin = self.originOnView(self.grid.position.row, column: self.grid.position.column)
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
    self.grid.setScrollRegion(Region(top: Int(top), bottom: Int(bottom), left: Int(left), right: Int(right)))
  }
  
  public func scroll(count: Int32) {
    Swift.print("### scroll count: \(count)")

//    Swift.print("before scroll: \(self.grid)")
    self.grid.scroll(Int(count))
//    Swift.print("after scroll: \(self.grid)")

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
  
  public func highlightSet(attrs: HighlightAttributes) {
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

      let rect = CGRect(origin: self.originOnView(curPos.row, column: curPos.column), size: self.cellSize)
      self.setNeedsDisplayInRect(rect)
    }
  }
  
  public func bell() {
    //    Swift.print("### bell")
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
    //    Swift.print("### set title: \(title)")
  }
  
  public func setIcon(icon: String) {
    //    Swift.print("### set icon: \(icon)")
  }
  
  public func stop() {
    Swift.print("### stop")
  }
}
