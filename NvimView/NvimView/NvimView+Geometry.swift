/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa

extension NvimView {

  func cursorRegion(for cursorPosition: Position) -> Region {
    var cursorRegion = Region(
      top: cursorPosition.row,
      bottom: cursorPosition.row,
      left: cursorPosition.column,
      right: cursorPosition.column
    )

    if self.ugrid.isNextCellEmpty(cursorPosition) {
      cursorRegion.right += 1
    }

    return cursorRegion
  }

  func region(for rect: CGRect) -> Region {
    let cellWidth = self.cellSize.width
    let cellHeight = self.cellSize.height

    let rowStart = max(
      0,
      Int(floor(
        (self.bounds.height - self.yOffset
          - (rect.origin.y + rect.size.height)) / cellHeight
      ))
    )
    let rowEnd = min(
      self.ugrid.size.height - 1,
      Int(ceil(
        (self.bounds.height - self.yOffset - rect.origin.y) / cellHeight
      )) - 1
    )
    let columnStart = max(
      0,
      Int(floor((rect.origin.x - self.xOffset) / cellWidth))
    )
    let columnEnd = min(
      self.ugrid.size.width - 1,
      Int(ceil(
        (rect.origin.x - self.xOffset + rect.size.width) / cellWidth
      )) - 1
    )

    return Region(
      top: rowStart, bottom: rowEnd, left: columnStart, right: columnEnd
    )
  }

  func pointInView(forRow row: Int, column: Int) -> CGPoint {
    return CGPoint(
      x: self.xOffset + CGFloat(column) * self.cellSize.width,
      y: self.bounds.size.height - self.yOffset
        - CGFloat(row) * self.cellSize.height - self.cellSize.height
    )
  }

  func rect(forRow row: Int, column: Int) -> CGRect {
    return CGRect(
      origin: self.pointInView(forRow: row, column: column), size: self.cellSize
    )
  }

  func rect(for region: Region) -> CGRect {
    let top = CGFloat(region.top)
    let bottom = CGFloat(region.bottom)
    let left = CGFloat(region.left)
    let right = CGFloat(region.right)

    let width = right - left + 1
    let height = bottom - top + 1

    let cellWidth = self.cellSize.width
    let cellHeight = self.cellSize.height

    return CGRect(
      x: self.xOffset + left * cellWidth,
      y: self.bounds.size.height - self.yOffset
        - top * cellHeight - height * cellHeight,
      width: width * cellWidth,
      height: height * cellHeight
    )
  }
}
