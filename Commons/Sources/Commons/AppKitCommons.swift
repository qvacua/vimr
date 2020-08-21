/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import AppKit

public extension NSAttributedString {
  
  func draw(at point: CGPoint, angle: CGFloat) {
    var translation = AffineTransform.identity
    var rotation = AffineTransform.identity

    translation.translate(x: point.x, y: point.y)
    rotation.rotate(byRadians: angle)

    (translation as NSAffineTransform).concat()
    (rotation as NSAffineTransform).concat()

    self.draw(at: CGPoint.zero)

    rotation.invert()
    translation.invert()

    (rotation as NSAffineTransform).concat()
    (translation as NSAffineTransform).concat()
  }

  var wholeRange: NSRange { NSRange(location: 0, length: self.length) }
}

public extension NSColor {

  static var random: NSColor {
    NSColor(
      calibratedRed: .random(in: 0...1),
      green: .random(in: 0...1),
      blue: .random(in: 0...1),
      alpha: 1.0
    )
  }

  var int: Int {
    if let color = self.usingColorSpace(.sRGB) {
      let a = Int(color.alphaComponent * 255)
      let r = Int(color.redComponent * 255)
      let g = Int(color.greenComponent * 255)
      let b = Int(color.blueComponent * 255)
      return a << 24 | r << 16 | g << 8 | b
    } else {
      return 0
    }
  }

  var hex: String { String(String(format: "%06X", self.int).suffix(6)) }

  convenience init(rgb: Int) {
    // @formatter:off
    let red =   ((rgb >> 16) & 0xFF).cgf / 255.0;
    let green = ((rgb >>  8) & 0xFF).cgf / 255.0;
    let blue =  ((rgb      ) & 0xFF).cgf / 255.0;
    // @formatter:on

    self.init(srgbRed: red, green: green, blue: blue, alpha: 1.0)
  }

  convenience init?(hex: String) {
    var result: UInt32 = 0
    guard hex.count == 6, Scanner(string: hex).scanHexInt32(&result) else { return nil }

    let r = (result & 0xFF0000) >> 16
    let g = (result & 0x00FF00) >> 8
    let b = (result & 0x0000FF)

    self.init(srgbRed: r.cgf / 255, green: g.cgf / 255, blue: b.cgf / 255, alpha: 1)
  }

  func brightening(by factor: CGFloat) -> NSColor {
    guard let color = self.usingColorSpace(.sRGB) else { return self }

    let h = color.hueComponent
    let s = color.saturationComponent
    let b = color.brightnessComponent
    let a = color.alphaComponent

    return NSColor(hue: h, saturation: s, brightness: b * factor, alpha: a)
  }
}

public extension NSImage {

  func tinting(with color: NSColor) -> NSImage {
    let result = self.copy() as! NSImage

    result.lockFocus()
    color.set()
    CGRect(origin: .zero, size: self.size).fill(using: .sourceAtop)
    result.unlockFocus()

    return result
  }
}

public extension NSButton {

  var boolState: Bool {
    get { self.state == .on ? true : false }
    set { self.state = newValue ? .on : .off }
  }
}

public extension NSMenuItem {

  var boolState: Bool {
    get { self.state == .on ? true : false }
    set { self.state = newValue ? .on : .off }
  }
}

public extension NSView {

  func removeAllSubviews() { self.subviews.forEach { $0.removeFromSuperview() } }

  func removeAllConstraints() { self.removeConstraints(self.constraints) }

  func beFirstResponder() { self.window?.makeFirstResponder(self) }
  
  /// - Returns: Rects currently being drawn
  /// - Warning: Call only in drawRect()
  func rectsBeingDrawn() -> [CGRect] {
    var rectsPtr: UnsafePointer<CGRect>? = nil
    var count: Int = 0
    self.getRectsBeingDrawn(&rectsPtr, count: &count)

    return Array(UnsafeBufferPointer(start: rectsPtr, count: count))
  }
}

public extension NSEvent.ModifierFlags {

  // Values are from https://github.com/SFML/SFML/blob/master/src/SFML/Window/OSX/SFKeyboardModifiersHelper.mm
  // @formatter:off
  static let rightShift   = NSEvent.ModifierFlags(rawValue: 0x020004)
  static let leftShift    = NSEvent.ModifierFlags(rawValue: 0x020002)
  static let rightCommand = NSEvent.ModifierFlags(rawValue: 0x100010)
  static let leftCommand  = NSEvent.ModifierFlags(rawValue: 0x100008)
  static let rightOption  = NSEvent.ModifierFlags(rawValue: 0x080040)
  static let leftOption   = NSEvent.ModifierFlags(rawValue: 0x080020)
  static let rightControl = NSEvent.ModifierFlags(rawValue: 0x042000)
  static let leftControl  = NSEvent.ModifierFlags(rawValue: 0x040001)
  // @formatter:on
}
