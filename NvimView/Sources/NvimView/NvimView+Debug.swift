/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa

public extension NvimView {
  @IBAction func debug1(_: Any?) {
    do {
      try self.ugrid.dump()
      self.logger.debug("dumped ugrid")
    } catch {
      self.logger.error("Could not dump UGrid: \(error)")
    }
  }

  @IBAction func debug2(_: Any?) {
    self.logger.error("nothing yet")
  }

  internal func draw(cellGridIn context: CGContext) {
    context.saveGState()
    defer { context.restoreGState() }

    let color = NSColor.magenta.cgColor
    context.setFillColor(color)

    let discreteSize = self.discreteSize(size: self.bounds.size)
    var lines = [
      CGRect(x: 0 + self.offset.x, y: 0, width: 1, height: self.bounds.height),
      CGRect(
        x: self.bounds.width - 1 + self.offset.x,
        y: 0,
        width: 1,
        height: self.bounds.height
      ),
      CGRect(
        x: 0,
        y: self.bounds.height - 1 - self.offset.y,
        width: self.bounds.width,
        height: 1
      ),
      CGRect(
        x: 0,
        y: self.bounds.height - 1 - self.offset.y
          - discreteSize.height.cgf * self.self.cellSize.height,
        width: self.bounds.width,
        height: 1
      ),
    ]

    for row in 0...discreteSize.height {
      for col in 0...discreteSize.width {
        lines.append(contentsOf: [
          CGRect(
            x: col.cgf * self.cellSize.width + self.offset.x - 1,
            y: 0,
            width: 1,
            height: self.bounds.height
          ),
          CGRect(
            x: 0,
            y: self.bounds.height - 1
              - self.offset.y - row.cgf * self.self.cellSize.height,
            width: self.bounds.width,
            height: 1
          ),
        ])
      }
    }

    context.fill(lines)
  }
}
