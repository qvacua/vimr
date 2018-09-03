/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa

extension NvimView {

  func draw(cellGridIn context: CGContext) {
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
          - CGFloat(discreteSize.height) * self.self.cellSize.height,
        width: self.bounds.width,
        height: 1
      ),
    ]

    for row in 0...discreteSize.height {
      for col in 0...discreteSize.width {
        lines.append(contentsOf: [
          CGRect(
            x: CGFloat(col) * self.cellSize.width + self.offset.x - 1,
            y: 0,
            width: 1,
            height: self.bounds.height
          ),
          CGRect(
            x: 0,
            y: self.bounds.height - 1
              - self.offset.y - CGFloat(row) * self.self.cellSize.height,
            width: self.bounds.width,
            height: 1
          ),
        ])
      }
    }

    lines.forEach { $0.fill() }
  }

  func name(ofCursorMode mode: CursorModeShape) -> String {
    switch mode {
      // @formatter:off
    case .normal:                  return "Normal"
    case .visual:                  return "Visual"
    case .insert:                  return "Insert"
    case .replace:                 return "Replace"
    case .cmdline:                 return "Cmdline"
    case .cmdlineInsert:           return "CmdlineInsert"
    case .cmdlineReplace:          return "CmdlineReplace"
    case .operatorPending:         return "OperatorPending"
    case .visualExclusive:         return "VisualExclusive"
    case .onCmdline:               return "OnCmdline"
    case .onStatusLine:            return "OnStatusLine"
    case .draggingStatusLine:      return "DraggingStatusLine"
    case .onVerticalSepLine:       return "OnVerticalSepLine"
    case .draggingVerticalSepLine: return "DraggingVerticalSepLine"
    case .more:                    return "More"
    case .moreLastLine:            return "MoreLastLine"
    case .showingMatchingParen:    return "ShowingMatchingParen"
    case .termFocus:               return "TermFocus"
    case .count:                   return "Count"
    // @formatter:on
    }
  }
}
