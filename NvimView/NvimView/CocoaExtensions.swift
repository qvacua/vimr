/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa

extension NSColor {

  var hex: String {
    if let color = self.usingColorSpace(.sRGB) {
      return "#" +
             String(format: "%X", Int(color.redComponent * 255)) +
             String(format: "%X", Int(color.greenComponent * 255)) +
             String(format: "%X", Int(color.blueComponent * 255)) +
             String(format: "%X", Int(color.alphaComponent * 255))
    } else {
      return self.description
    }
  }
}

extension CGRect {

  public var hashValue: Int {
    let o = Int(self.origin.x) << 10 ^ Int(self.origin.y)
    let s = Int(self.size.width) << 10 ^ Int(self.size.height)
    return o + s
  }
}

extension CGSize {

  func scaling(_ factor: CGFloat) -> CGSize {
    return CGSize(width: self.width * factor, height: self.height * factor)
  }
}

extension NSView {

  /// - Returns: Rects currently being drawn
  /// - Warning: Call only in drawRect()
  func rectsBeingDrawn() -> [CGRect] {
    var rectsPtr: UnsafePointer<CGRect>? = nil
    var count: Int = 0
    self.getRectsBeingDrawn(&rectsPtr, count: &count)

    return Array(UnsafeBufferPointer(start: rectsPtr, count: count))
  }
}

extension NSEvent {

  struct Modifier: OptionSet {

    let rawValue: UInt

    // Values are from https://github.com/SFML/SFML/blob/master/src/SFML/Window/OSX/SFKeyboardModifiersHelper.mm
    // @formatter:off
    static let rightShift   = Modifier(rawValue: 0x020004)
    static let leftShift    = Modifier(rawValue: 0x020002)
    static let rightCommand = Modifier(rawValue: 0x100010)
    static let leftCommand  = Modifier(rawValue: 0x100008)
    static let rightOption  = Modifier(rawValue: 0x080040)
    static let leftOption   = Modifier(rawValue: 0x080020)
    static let rightControl = Modifier(rawValue: 0x042000)
    static let leftControl  = Modifier(rawValue: 0x040001)

    static let shift   = Modifier(rawValue: NSEvent.ModifierFlags.shift.rawValue)
    static let command = Modifier(rawValue: NSEvent.ModifierFlags.command.rawValue)
    static let option  = Modifier(rawValue: NSEvent.ModifierFlags.option.rawValue)
    static let control = Modifier(rawValue: NSEvent.ModifierFlags.control.rawValue)

    static let all: Array<Modifier> = Array(arrayLiteral:
      .rightShift, .leftShift, .rightCommand, .leftCommand, .rightOption, .leftOption, .rightControl, .leftControl,
      .shift, .command, .option, .control
    )
    // @formatter:on
  }

  var modifiers: Modifier {
    var result: Modifier = []

    Modifier.all
      .compactMap { modifier in
        if (self.modifierFlags.rawValue & modifier.rawValue) == modifier.rawValue {
          return modifier
        }

        return nil
      }
      .forEach { result.insert($0) }

    return result
  }
}
