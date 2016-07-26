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

  public let uuid = NSUUID().UUIDString
  public weak var delegate: NeoVimViewDelegate?
  
  private let agent: NeoVimAgent

  private let grid = Grid()

  private var markedText: String?

  /// We store the last marked text because Cocoa's text input system does the following:
  /// 하 -> hanja popup -> insertText(하) -> attributedSubstring...() -> setMarkedText(下) -> ...
  /// We want to return "하" in attributedSubstring...()
  private var lastMarkedText: String?
  
  private var markedPosition = Position.null
  private var keyDownDone = true

  private var lastClickedCellPosition = Position.null
  
  private var xOffset = CGFloat(0)
  private var yOffset = CGFloat(0)
  private var cellSize = CGSize.zero
  private var descent = CGFloat(0)
  private var leading = CGFloat(0)

  private let maxScrollDeltaX = 30
  private let maxScrollDeltaY = 30
  private let scrollLimiterX = CGFloat(20)
  private let scrollLimiterY = CGFloat(20)
  private var scrollGuardCounterX = 5
  private var scrollGuardCounterY = 5
  private let scrollGuardYield = 5

  private let drawer: TextDrawer
  private var font: NSFont {
    didSet {
      self.drawer.font = self.font
      self.cellSize = self.drawer.cellSize
      self.descent = self.drawer.descent
      self.leading = self.drawer.leading
      
      // We assume that the font is valid, eg fixed width, not too small, not too big, etc..
      self.resizeNeoVimUiTo(size: self.frame.size)
    }
  }
  
  override init(frame rect: NSRect = CGRect.zero) {
    self.font = NSFont(name: "Menlo", size: 13)!
    self.drawer = TextDrawer(font: font)
    self.agent = NeoVimAgent(uuid: self.uuid)

    super.init(frame: rect)
    
    self.wantsLayer = true
    self.cellSize = self.drawer.cellSize
    self.descent = self.drawer.descent
    self.leading = self.drawer.leading

    // We cannot set bridge in init since self is not available before super.init()...
    self.agent.bridge = self
    self.agent.establishLocalServer()
  }
  
  deinit {
    self.agent.cleanUp()
  }

  public func debugInfo() {
    Swift.print(self.grid)
  }

  public func setFont(font: NSFont) {
    guard font.fixedPitch else {
      return
    }

    // FIXME: check the size whether too small or too big!
    self.font = font
  }

  override public func setFrameSize(newSize: NSSize) {
    super.setFrameSize(newSize)

    // initial resizing is done when grid has data
    guard self.grid.hasData else {
      return
    }

    if self.inLiveResize {
      // TODO: Turn of live resizing for now.
      // self.resizeNeoVimUiTo(size: newSize)
      return
    }

    // There can be cases where the frame is resized not by live resizing, eg when the window is resized by window
    // management tools. Thus, we make sure that the resize call is made when this happens.
    self.resizeNeoVimUiTo(size: newSize)
  }

  override public func viewDidEndLiveResize() {
    super.viewDidEndLiveResize()
    self.resizeNeoVimUiTo(size: self.bounds.size)
  }

  private func resizeNeoVimUiTo(size size: CGSize) {
//    NSLog("\(#function): \(size)")
    let discreteSize = Size(width: Int(floor(size.width / self.cellSize.width)),
                            height: Int(floor(size.height / self.cellSize.height)))

    self.xOffset = floor((size.width - self.cellSize.width * CGFloat(discreteSize.width)) / 2)
    self.yOffset = floor((size.height - self.cellSize.height * CGFloat(discreteSize.height)) / 2)

    self.agent.resizeToWidth(Int32(discreteSize.width), height: Int32(discreteSize.height))
  }

  override public func drawRect(dirtyUnionRect: NSRect) {
    guard self.grid.hasData else {
      return
    }

    if self.inLiveResize {
      NSColor.lightGrayColor().set()
      dirtyUnionRect.fill()
      return
    }

//    NSLog("\(#function): \(dirtyUnionRect)")
    let context = NSGraphicsContext.currentContext()!.CGContext

    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
    CGContextSetTextDrawingMode(context, .Fill);

    let dirtyRects = self.rectsBeingDrawn()

    self.rowRunIntersecting(rects: dirtyRects).forEach { rowFrag in
      // For background drawing we don't filter out the put(0, 0)s: in some cases only the put(0, 0)-cells should be
      // redrawn. => FIXME: probably we have to consider this also when drawing further down, ie when the range starts
      // with '0'...
      self.drawBackground(positions: rowFrag.range.map { self.pointInViewFor(row: rowFrag.row, column: $0) },
                          background: rowFrag.attrs.background)

      let positions = rowFrag.range
        // filter out the put(0, 0)s (after a wide character)
        .filter { self.grid.cells[rowFrag.row][$0].string.characters.count > 0 }
        .map { self.pointInViewFor(row: rowFrag.row, column: $0) }

      if positions.isEmpty {
        return
      }

      let string = self.grid.cells[rowFrag.row][rowFrag.range].reduce("") { $0 + $1.string }
      let glyphPositions = positions.map { CGPoint(x: $0.x, y: $0.y + self.descent + self.leading) }
      self.drawer.drawString(string,
                             positions: UnsafeMutablePointer(glyphPositions), positionsCount: positions.count,
                             highlightAttrs: rowFrag.attrs,
                             context: context)
    }

    self.drawCursor(self.grid.background)
  }

  public func hasDirtyDocs() -> Bool {
    return self.agent.hasDirtyDocs()
  }

  private func drawCursor(background: UInt32) {
    // FIXME: for now do some rudimentary cursor drawing
    let cursorPosition = self.grid.putPosition
//    NSLog("\(#function): \(cursorPosition)")

    var cursorRect = self.cellRectFor(row: cursorPosition.row, column: cursorPosition.column)
    if self.grid.isNextCellEmpty(cursorPosition) {
      let nextPosition = self.grid.nextCellPosition(cursorPosition)
      cursorRect = cursorRect.union(self.cellRectFor(row: nextPosition.row, column:nextPosition.column))
    }

    ColorUtils.colorIgnoringAlpha(background).set()
    NSRectFillUsingOperation(cursorRect, .CompositeDifference)
  }

  private func drawBackground(positions positions: [CGPoint], background: UInt32) {
    ColorUtils.colorIgnoringAlpha(background).set()
    let backgroundRect = CGRect(
      x: positions[0].x, y: positions[0].y,
      width: CGFloat(positions.count) * self.cellSize.width, height: self.cellSize.height
    )
    backgroundRect.fill()
  }

  private func rowRunIntersecting(rects rects: [CGRect]) -> [RowRun] {
    return rects
      .map { rect -> (Range<Int>, Range<Int>) in
        // Get all Regions that intersects with the given rects. There can be overlaps between the Regions, but for the
        // time being we ignore them; probably not necessary to optimize them away.
        let region = self.regionFor(rect: rect)
        return (region.rowRange, region.columnRange)
      }
      .map { self.rowRunsFor(rowRange: $0, columnRange: $1) } // All RowRuns for all Regions grouped by their row range.
      .flatMap { $0 }                                         // Flattened RowRuns for all Regions.
  }

  private func rowRunsFor(rowRange rowRange: Range<Int>, columnRange: Range<Int>) -> [RowRun] {
    return rowRange
      .map { (row) -> [RowRun] in
        let rowCells = self.grid.cells[row]
        let startIdx = columnRange.startIndex

        var result = [ RowRun(row: row, range: startIdx...startIdx, attrs: rowCells[startIdx].attrs) ]
        columnRange.forEach { idx in
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
  }

  private func regionFor(rect rect: CGRect) -> Region {
    let rowStart = max(
      Int(floor((self.frame.height - (rect.origin.y + rect.size.height)) / self.cellSize.height)), 0
    )
    let rowEnd = min(
      Int(ceil((self.frame.height - rect.origin.y) / self.cellSize.height)) - 1, self.grid.size.height  - 1
    )
    let columnStart = max(
      Int(floor(rect.origin.x / self.cellSize.width)), 0
    )
    let columnEnd = min(
      Int(ceil((rect.origin.x + rect.size.width) / self.cellSize.width)) - 1, self.grid.size.width - 1
    )

    return Region(top: rowStart, bottom: rowEnd, left: columnStart, right: columnEnd)
  }
  
  private func pointInViewFor(position position: Position) -> CGPoint {
    return self.pointInViewFor(row: position.row, column: position.column)
  }

  private func pointInViewFor(row row: Int, column: Int) -> CGPoint {
    return CGPoint(
      x: CGFloat(column) * self.cellSize.width + self.xOffset,
      y: self.frame.size.height - CGFloat(row) * self.cellSize.height - self.cellSize.height - self.yOffset
    )
  }

  private func cellRectFor(row row: Int, column: Int) -> CGRect {
    return CGRect(origin: self.pointInViewFor(row: row, column: column), size: self.cellSize)
  }

  private func regionRectFor(region region: Region) -> CGRect {
    let top = CGFloat(region.top)
    let bottom = CGFloat(region.bottom)
    let left = CGFloat(region.left)
    let right = CGFloat(region.right)

    let width = right - left + 1
    let height = bottom - top + 1

    return CGRect(
      x: left * self.cellSize.width + self.xOffset,
      y: (CGFloat(self.grid.size.height) - bottom) * self.cellSize.height - self.yOffset,
      width: width * self.cellSize.width,
      height: height * self.cellSize.height
    )
  }

  private func wrapNamedKeys(string: String) -> String {
    return "<\(string)>"
  }
  
  private func vimPlainString(string: String) -> String {
    return string.stringByReplacingOccurrencesOfString("<", withString: self.wrapNamedKeys("lt"))
  }
  
  required public init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

// MARK: - Key Events
extension NeoVimView: NSTextInputClient {

  override public func keyDown(event: NSEvent) {
    self.keyDownDone = false
    
    let context = NSTextInputContext.currentInputContext()!
    let cocoaHandledEvent = context.handleEvent(event)
    if self.keyDownDone && cocoaHandledEvent {
      return
    }

//    NSLog("\(#function): \(event)")

    let modifierFlags = event.modifierFlags
    let capslock = modifierFlags.contains(.AlphaShiftKeyMask)
    let shift = modifierFlags.contains(.ShiftKeyMask)
    let chars = event.characters!
    let charsIgnoringModifiers = shift || capslock ? event.charactersIgnoringModifiers!.lowercaseString
                                                   : event.charactersIgnoringModifiers!

    if KeyUtils.isSpecial(key: charsIgnoringModifiers) {
      if let vimModifiers = self.vimModifierFlags(modifierFlags) {
        self.agent.vimInput(self.wrapNamedKeys(vimModifiers + KeyUtils.namedKeyFrom(key: charsIgnoringModifiers)))
      } else {
        self.agent.vimInput(self.wrapNamedKeys(KeyUtils.namedKeyFrom(key: charsIgnoringModifiers)))
      }
    } else {
      if let vimModifiers = self.vimModifierFlags(modifierFlags) {
        self.agent.vimInput(self.wrapNamedKeys(vimModifiers + charsIgnoringModifiers))
      } else {
        self.agent.vimInput(self.vimPlainString(chars))
      }
    }

    self.keyDownDone = true
  }

  public func insertText(aString: AnyObject, replacementRange: NSRange) {
//    NSLog("\(#function): \(replacementRange): '\(aString)'")

    switch aString {
    case let string as String:
      self.agent.vimInput(self.vimPlainString(string))
    case let attributedString as NSAttributedString:
      self.agent.vimInput(self.vimPlainString(attributedString.string))
    default:
      break;
    }

    // unmarkText()
    self.lastMarkedText = self.markedText
    self.markedText = nil
    self.markedPosition = Position.null
    self.keyDownDone = true
  }

  public override func doCommandBySelector(aSelector: Selector) {
//    NSLog("\(#function): \(aSelector)");

    // FIXME: handle when ㅎ -> delete

    if self.respondsToSelector(aSelector) {
      Swift.print("\(#function): calling \(aSelector)")
      self.performSelector(aSelector, withObject: self)
      self.keyDownDone = true
      return
    }

//    NSLog("\(#function): "\(aSelector) not implemented, forwarding input to vim")
    self.keyDownDone = false
  }

  public func setMarkedText(aString: AnyObject, selectedRange: NSRange, replacementRange: NSRange) {
    if self.markedText == nil {
      self.markedPosition = self.grid.putPosition
    }
    
    // eg 하 -> hanja popup, cf comment for self.lastMarkedText
    if replacementRange.length > 0 {
      self.agent.deleteCharacters(replacementRange.length)
    }

    switch aString {
    case let string as String:
      self.markedText = string
    case let attributedString as NSAttributedString:
      self.markedText = attributedString.string
    default:
      self.markedText = String(aString) // should not occur
    }
    
//    NSLog("\(#function): \(self.markedText), \(selectedRange), \(replacementRange)")

    self.agent.vimInputMarkedText(self.markedText!)
    self.keyDownDone = true
  }

  public func unmarkText() {
//    NSLog("\(#function): ")
    self.markedText = nil
    self.markedPosition = Position.null
    self.keyDownDone = true
    
    // TODO: necessary?
    self.setNeedsDisplayInRect(self.cellRectFor(row: self.grid.putPosition.row, column: self.grid.putPosition.column))
  }

  /// Return the current selection (or the position of the cursor with empty-length range). For example when you enter
  /// "Cmd-Ctrl-Return" you'll get the Emoji-popup at the rect by firstRectForCharacterRange(actualRange:) where the
  /// first range is the result of this method.
  public func selectedRange() -> NSRange {
    // When the app starts and the Hangul input method is selected, this method gets called very early...
    guard self.grid.hasData else {
//      NSLog("\(#function): not found")
      return NSRange(location: NSNotFound, length: 0)
    }

    let result = NSRange(location: self.grid.singleIndexFrom(self.grid.putPosition), length: 0)
//    NSLog("\(#function): \(result)")
    return result
  }

  public func markedRange() -> NSRange {
    // FIXME: do we have to handle positions at the column borders?
    if let markedText = self.markedText {
      let result = NSRange(location: self.grid.singleIndexFrom(self.markedPosition),
                           length: markedText.characters.count)
//      NSLog("\(#function): \(result)")
      return result
    }

    NSLog("\(#function): returning empty range")
    return NSRange(location: NSNotFound, length: 0)
  }

  public func hasMarkedText() -> Bool {
//    NSLog("\(#function)")
    return self.markedText != nil
  }

  // FIXME: take into account the "return nil"-case
  // FIXME: just fix me, PLEASE...
  public func attributedSubstringForProposedRange(aRange: NSRange, actualRange: NSRangePointer) -> NSAttributedString? {
//    NSLog("\(#function): \(aRange), \(actualRange[0])")
    if aRange.location == NSNotFound {
//      NSLog("\(#function): range not found: returning nil")
      return nil
    }
    
    guard let lastMarkedText = self.lastMarkedText else {
//      NSLog("\(#function): no last marked text: returning nil")
      return nil
    }
    
    // we only support last marked text, thus fill dummy characters when Cocoa asks for more characters than marked...
    let fillCount = aRange.length - lastMarkedText.characters.count
    guard fillCount >= 0 else {
      return nil
    }

    let fillChars = Array(0..<fillCount).reduce("") { (result, _) in return result + " " }
    
//    NSLog("\(#function): \(aRange), \(actualRange[0]): \(fillChars + lastMarkedText)")
    return NSAttributedString(string: fillChars + lastMarkedText)
  }

  public func validAttributesForMarkedText() -> [String] {
    return []
  }

  public func firstRectForCharacterRange(aRange: NSRange, actualRange: NSRangePointer) -> NSRect {
    let position = self.grid.positionFromSingleIndex(aRange.location)
    
//    NSLog("\(#function): \(aRange),\(actualRange[0]) -> \(position.row):\(position.column)")

    let resultInSelf = self.cellRectFor(row: position.row, column: position.column)
    let result = self.window?.convertRectToScreen(self.convertRect(resultInSelf, toView: nil))

    return result!
  }

  public func characterIndexForPoint(aPoint: NSPoint) -> Int {
//    NSLog("\(#function): \(aPoint)")
    return 1
  }
  
  private func vimModifierFlags(modifierFlags: NSEventModifierFlags) -> String? {
    var result = ""
    
    let control = modifierFlags.contains(.ControlKeyMask)
    let option = modifierFlags.contains(.AlternateKeyMask)
    let command = modifierFlags.contains(.CommandKeyMask)

    if control {
      result += "C-"
    }
    
    if option {
      result += "M-"
    }
    
    if command {
      result += "D-"
    }

    if result.characters.count > 0 {
      return result
    }

    return nil
  }
}

// MARK: - Mouse Events
extension NeoVimView {

  override public func mouseDown(event: NSEvent) {
    self.mouse(event: event, vimName:"LeftMouse")
  }

  override public func mouseUp(event: NSEvent) {
    self.mouse(event: event, vimName:"LeftRelease")
  }

  override public func mouseDragged(event: NSEvent) {
    self.mouse(event: event, vimName:"LeftDrag")
  }

  override public func scrollWheel(event: NSEvent) {
    let (deltaX, deltaY) = (event.scrollingDeltaX, event.scrollingDeltaY)
    if deltaX == 0 && deltaY == 0 {
      return
    }
    
    let cellPosition = self.cellPositionFor(event: event)
    let (vimInputX, vimInputY) = self.vimScrollInputFor(deltaX: deltaX, deltaY: deltaY,
                                                    modifierFlags: event.modifierFlags,
                                                    cellPosition: cellPosition)
    
    let (absDeltaX, absDeltaY) = (abs(deltaX), abs(deltaY))
    
    // The absolute delta values can get very very big when you use two finger scrolling on the trackpad:
    // Cap them using heuristic values...
    let numX = deltaX != 0 ? max(1, min(Int(absDeltaX / self.scrollLimiterX), self.maxScrollDeltaX)) : 0
    let numY = deltaY != 0 ? max(1, min(Int(absDeltaY / self.scrollLimiterY), self.maxScrollDeltaY)) : 0

    for i in 0..<max(numX, numY) {
      if i < numX {
        self.throttleScrollX(absDelta: absDeltaX, vimInput: vimInputX)
      }
      
      if i < numY {
        self.throttleScrollY(absDelta: absDeltaY, vimInput: vimInputY)
      }
    }
  }

  private func cellPositionFor(event event: NSEvent) -> Position {
    let location = self.convertPoint(event.locationInWindow, fromView: nil)
    let cellPosition = Position(
      row: min(Int(floor(location.x / self.cellSize.width)), self.grid.size.width - 1),
      column: min(Int(floor((self.bounds.height - location.y) / self.cellSize.height)), self.grid.size.height - 1)
    )

    return cellPosition
  }

  private func mouse(event event: NSEvent, vimName: String) {
    let cellPosition = self.cellPositionFor(event: event)
    guard self.shouldFireVimInputFor(event: event, newCellPosition: cellPosition) else {
      return
    }

    let vimMouseLocation = self.wrapNamedKeys("\(cellPosition.row),\(cellPosition.column)")
    let vimClickCount = self.vimClickCountFrom(event: event)

    let result: String
    if let vimModifiers = self.vimModifierFlags(event.modifierFlags) {
      result = self.wrapNamedKeys("\(vimModifiers)\(vimClickCount)\(vimName)") + vimMouseLocation
    } else {
      result = self.wrapNamedKeys("\(vimClickCount)\(vimName)") + vimMouseLocation
    }

//    NSLog("\(#function): \(result)")
    self.agent.vimInput(result)
  }

  private func shouldFireVimInputFor(event event:NSEvent, newCellPosition: Position) -> Bool {
    let type = event.type
    guard type == .LeftMouseDragged || type == .RightMouseDragged || type == .OtherMouseDragged  else {
      self.lastClickedCellPosition = newCellPosition
      return true
    }

    if self.lastClickedCellPosition == newCellPosition {
      return false
    }

    self.lastClickedCellPosition = newCellPosition
    return true
  }

  private func vimClickCountFrom(event event: NSEvent) -> String {
    let clickCount = event.clickCount

    guard 2 <= clickCount && clickCount <= 4 else {
      return ""
    }

    switch event.type {
    case .LeftMouseDown, .LeftMouseUp, .RightMouseDown, .RightMouseUp:
      return "\(clickCount)-"
    default:
      return ""
    }
  }
  
  private func vimScrollEventNamesFor(deltaX deltaX: CGFloat, deltaY: CGFloat) -> (String, String) {
    let typeY: String
    if deltaY > 0 {
      typeY = "ScrollWheelUp"
    } else {
      typeY = "ScrollWheelDown"
    }

    let typeX: String
    if deltaX < 0 {
      typeX = "ScrollWheelRight"
    } else {
      typeX = "ScrollWheelLeft"
    }
    
    return (typeX, typeY)
  }
  
  private func vimScrollInputFor(deltaX deltaX: CGFloat, deltaY: CGFloat,
                                        modifierFlags: NSEventModifierFlags,
                                        cellPosition: Position) -> (String, String)
  {
    let vimMouseLocation = self.wrapNamedKeys("\(cellPosition.row),\(cellPosition.column)")

    let (typeX, typeY) = self.vimScrollEventNamesFor(deltaX: deltaX, deltaY: deltaY)
    let resultX: String
    let resultY: String
    if let vimModifiers = self.vimModifierFlags(modifierFlags) {
      resultX = self.wrapNamedKeys("\(vimModifiers)\(typeX)") + vimMouseLocation
      resultY = self.wrapNamedKeys("\(vimModifiers)\(typeY)") + vimMouseLocation
    } else {
      resultX = self.wrapNamedKeys("\(typeX)") + vimMouseLocation
      resultY = self.wrapNamedKeys("\(typeY)") + vimMouseLocation
    }
    
    return (resultX, resultY)
  }
  
  private func throttleScrollX(absDelta absDeltaX: CGFloat, vimInput: String) {
    if absDeltaX == 0 {
      self.scrollGuardCounterX = self.scrollGuardYield - 1
    } else if absDeltaX <= 2 {
      // Poor man's throttle for scroll value = 1 or 2
      if self.scrollGuardCounterX % self.scrollGuardYield == 0  {
        self.agent.vimInput(vimInput)
        self.scrollGuardCounterX = 1
      } else {
        self.scrollGuardCounterX += 1
      }
    } else {
      self.agent.vimInput(vimInput)
    }
  }
  
  private func throttleScrollY(absDelta absDeltaY: CGFloat, vimInput: String) {
    if absDeltaY == 0 {
      self.scrollGuardCounterY = self.scrollGuardYield - 1
    } else if absDeltaY <= 2 {
      // Poor man's throttle for scroll value = 1 or 2
      if self.scrollGuardCounterY % self.scrollGuardYield == 0  {
        self.agent.vimInput(vimInput)
        self.scrollGuardCounterY = 1
      } else {
        self.scrollGuardCounterY += 1
      }
    } else {
      self.agent.vimInput(vimInput)
    }
  }
}

// MARK: - NeoVimUiBridgeProtocol
extension NeoVimView: NeoVimUiBridgeProtocol {

  public func neoVimUiIsReady() {
    DispatchUtils.gui {
      self.resizeNeoVimUiTo(size: self.frame.size)
      self.delegate?.neoVimReady()
    }
  }

  public func resizeToWidth(width: Int32, height: Int32) {
    DispatchUtils.gui {
      NSLog("\(#function): \(width):\(height)")
      self.grid.resize(Size(width: Int(width), height: Int(height)))
      self.needsDisplay = true
    }
  }
  
  public func clear() {
    DispatchUtils.gui {
      self.grid.clear()
      self.needsDisplay = true
    }
  }
  
  public func eolClear() {
    DispatchUtils.gui {
      self.grid.eolClear()

      let origin = self.pointInViewFor(position: self.grid.putPosition)
      let size = CGSize(
        width: CGFloat(self.grid.region.right - self.grid.putPosition.column + 1) * self.cellSize.width,
        height: self.cellSize.height
      )
      let rect = CGRect(origin: origin, size: size)
      self.setNeedsDisplayInRect(rect)
    }
  }
  
  public func gotoPosition(position: Position, screenCursor: Position) {
    DispatchUtils.gui {
//      NSLog("\(#function): \(position), \(screenCursor)")

      // Because neovim fills blank space with "Space" and when we enter "Space" we don't get the puts.
      self.setNeedsDisplay(cellPosition: self.grid.putPosition)
      self.setNeedsDisplay(cellPosition: self.grid.nextCellPosition(self.grid.putPosition))
      self.setNeedsDisplay(screenCursor: position)

      self.grid.goto(position)
      self.grid.moveCursor(screenCursor)
    }
  }
  
  public func updateMenu() {
  }
  
  public func busyStart() {
  }
  
  public func busyStop() {
  }
  
  public func mouseOn() {
  }
  
  public func mouseOff() {
  }
  
  public func modeChange(mode: Int32) {
  }
  
  public func setScrollRegionToTop(top: Int32, bottom: Int32, left: Int32, right: Int32) {
    DispatchUtils.gui {
      let region = Region(top: Int(top), bottom: Int(bottom), left: Int(left), right: Int(right))
      self.grid.setScrollRegion(region)
      self.setNeedsDisplay(region: region)
    }
  }
  
  public func scroll(count: Int32) {
    DispatchUtils.gui {
      self.grid.scroll(Int(count))
      self.setNeedsDisplay(region: self.grid.region)
    }
  }

  public func highlightSet(attrs: CellAttributes) {
    DispatchUtils.gui {
      self.grid.attrs = attrs
    }
  }
  
  public func put(string: String) {
    DispatchUtils.gui {
      let curPos = self.grid.putPosition
//      NSLog("\(#function): \(curPos) -> \(string)")
      self.grid.put(string)
      self.setNeedsDisplay(cellPosition: curPos)
      // When the cursor is in the command line, then we need this...
      self.setNeedsDisplay(cellPosition: self.grid.nextCellPosition(curPos))

      self.setNeedsDisplay(screenCursor: self.grid.screenCursor)
    }
  }

  public func putMarkedText(markedText: String) {
    DispatchUtils.gui {
      NSLog("\(#function): '\(markedText)'")
      let curPos = self.grid.putPosition
      self.grid.putMarkedText(markedText)

      self.setNeedsDisplay(position: curPos)
      // When the cursor is in the command line, then we need this...
      self.setNeedsDisplay(cellPosition: self.grid.nextCellPosition(curPos))
      if markedText.characters.count == 0 {
        self.setNeedsDisplay(position: self.grid.previousCellPosition(curPos))
      }
      self.setNeedsDisplay(screenCursor: self.grid.screenCursor)
    }
  }

  public func unmarkRow(row: Int32, column: Int32) {
    DispatchUtils.gui {
      let position = Position(row: Int(row), column: Int(column))

      NSLog("\(#function): \(position)")

      self.grid.unmarkCell(position)
      self.setNeedsDisplay(position: position)
      
      self.setNeedsDisplay(screenCursor: self.grid.screenCursor)
    }
  }

  public func bell() {
    DispatchUtils.gui {
      NSBeep()
    }
  }
  
  public func visualBell() {
  }
  
  public func flush() {
//    NSLog("\(#function)")
  }
  
  public func updateForeground(fg: Int32) {
    DispatchUtils.gui {
      self.grid.foreground = UInt32(bitPattern: fg)
    }
  }
  
  public func updateBackground(bg: Int32) {
    DispatchUtils.gui {
      self.grid.background = UInt32(bitPattern: bg)
      self.layer?.backgroundColor = ColorUtils.colorIgnoringAlpha(self.grid.background).CGColor
    }
  }
  
  public func updateSpecial(sp: Int32) {
    DispatchUtils.gui {
      self.grid.special = UInt32(bitPattern: sp)
    }
  }
  
  public func suspend() {
  }
  
  public func setTitle(title: String) {
    DispatchUtils.gui {
      self.delegate?.setNeoVimTitle(title)
    }
  }
  
  public func setIcon(icon: String) {
  }
  
  public func stop() {
    DispatchUtils.gui {
      self.delegate?.neoVimStopped()
    }
  }
  
  private func setNeedsDisplay(region region: Region) {
    self.setNeedsDisplayInRect(self.regionRectFor(region: region))
  }
  
  private func setNeedsDisplay(cellPosition position: Position) {
    self.setNeedsDisplay(position: position)
    
    if self.grid.isCellEmpty(position) {
      self.setNeedsDisplay(position: self.grid.previousCellPosition(position))
    }
    
    if self.grid.isNextCellEmpty(position) {
      self.setNeedsDisplay(position: self.grid.nextCellPosition(position))
    }
  }

  private func setNeedsDisplay(position position: Position) {
    self.setNeedsDisplay(row: position.row, column: position.column)
  }

  private func setNeedsDisplay(row row: Int, column: Int) {
//    Swift.print("\(#function): \(row):\(column)")
    self.setNeedsDisplayInRect(self.cellRectFor(row: row, column: column))
  }

  private func setNeedsDisplay(screenCursor position: Position) {
    self.setNeedsDisplay(position: position)
    if self.grid.isNextCellEmpty(position) {
      self.setNeedsDisplay(position: self.grid.nextCellPosition(position))
    }
  }
}