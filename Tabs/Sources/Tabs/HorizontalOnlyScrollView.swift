/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa

class HorizontalOnlyScrollView: NSScrollView {
  // Needed to be able to override scrollWheel(with:)
  // https://stackoverflow.com/a/31201614
  override static var isCompatibleWithResponsiveScrolling: Bool { true }

  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)

    self.hasVerticalScroller = false
    self.verticalScrollElasticity = .none
  }

  override public func scrollWheel(with event: NSEvent) {
    guard let cgEvent = event.cgEvent?.copy() else {
      super.scrollWheel(with: event)
      return
    }

    if event.scrollingDeltaX != 0 {
      cgEvent.setDoubleValueField(.scrollWheelEventDeltaAxis1, value: 0)
    } else {
      cgEvent.setDoubleValueField(.scrollWheelEventDeltaAxis2, value: Double(event.scrollingDeltaY))
    }

    guard let eventToForward = NSEvent(cgEvent: cgEvent) else {
      super.scrollWheel(with: event)
      return
    }

    super.scrollWheel(with: eventToForward)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
