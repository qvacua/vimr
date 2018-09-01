/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa

#if DEBUG
extension NvimView {

  private func draw(cellGridIn context: CGContext) {
    context.saveGState()
    defer { context.restoreGState() }

    let color = NSColor.magenta.cgColor
    context.setFillColor(color)

    let discreteSize = self.discreteSize(size: self.bounds.size)
    var lines = [
      CGRect(x: 0 + self.xOffset, y: 0, width: 1, height: self.bounds.height),
      CGRect(
        x: self.bounds.width - 1 + self.xOffset,
        y: 0,
        width: 1,
        height: self.bounds.height
      ),
      CGRect(
        x: 0,
        y: self.bounds.height - 1 - self.yOffset,
        width: self.bounds.width,
        height: 1
      ),
      CGRect(
        x: 0,
        y: self.bounds.height - 1 - self.yOffset
          - CGFloat(discreteSize.height) * self.self.cellSize.height,
        width: self.bounds.width,
        height: 1
      ),
    ]

    for row in 0...discreteSize.height {
      for col in 0...discreteSize.width {
        lines.append(contentsOf: [
          CGRect(
            x: CGFloat(col) * self.cellSize.width + self.xOffset - 1,
            y: 0,
            width: 1,
            height: self.bounds.height
          ),
          CGRect(
            x: 0,
            y: self.bounds.height - 1
              - self.yOffset - CGFloat(row) * self.self.cellSize.height,
            width: self.bounds.width,
            height: 1
          ),
        ])
      }
    }

    context.fill(lines)
  }
}
#endif
