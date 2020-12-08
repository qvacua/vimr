//
//  DraggingStackView.swift
//  Analysis
//
//  Created by Mark Onyschuk on 2017-02-02.
//  Copyright © 2017 Mark Onyschuk. All rights reserved.
//

// From https://stackoverflow.com/a/42024401
// Slightly modified and reformatted.

import Cocoa

class DraggingSingleRowStackView: NSStackView {
  var postDraggingHandler: ((NSStackView, NSView) -> Void)?

  override func mouseDragged(with event: NSEvent) {
    let location = convert(event.locationInWindow, from: nil)
    if let dragged = views.first(where: { $0.hitTest(location) != nil }) {
      self.reorder(view: dragged, event: event)
      self.postDraggingHandler?(self, dragged)
    }
  }

  func update(views: [NSView]) {
    self.views.forEach { self.removeView($0) }
    views.forEach { self.addView($0, in: .leading) }
  }

  private func reorder(view: NSView, event: NSEvent) {
    guard let layer = self.layer else { return }
    guard let cached = try? self.cacheViews() else { return }

    let container = CALayer()
    container.frame = layer.bounds
    container.zPosition = 1
    container.backgroundColor = NSColor.underPageBackgroundColor.cgColor

    cached
      .filter { $0.view !== view }
      .forEach { container.addSublayer($0) }

    layer.addSublayer(container)
    defer { container.removeFromSuperlayer() }

    let dragged = cached.first(where: { $0.view === view })!

    dragged.zPosition = 2
    layer.addSublayer(dragged)
    defer { dragged.removeFromSuperlayer() }

    let d0 = view.frame.origin
    let p0 = convert(event.locationInWindow, from: nil)

    window!.trackEvents(
      matching: [.leftMouseDragged, .leftMouseUp],
      timeout: 1e6,
      mode: RunLoop.Mode.eventTracking
    ) { optionalEvent, stop in
      guard let event = optionalEvent else { return }

      if event.type == .leftMouseDragged {
        self.autoscroll(with: event)

        let p1 = self.convert(event.locationInWindow, from: nil)

        let dx = (self.orientation == .horizontal) ? p1.x - p0.x : 0
        let dy = (self.orientation == .vertical) ? p1.y - p0.y : 0

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        dragged.frame.origin.x = d0.x + dx
        dragged.frame.origin.y = d0.y + dy
        CATransaction.commit()

        let reordered = self.views
          .map { (
            view: $0,
            position: $0 !== view
              ? CGPoint(x: $0.frame.midX, y: $0.frame.midY)
              : CGPoint(x: dragged.frame.midX, y: dragged.frame.midY)
          ) }
          .sorted {
            switch self.orientation {
            case .vertical: return $0.position.y > $1.position.y
            case .horizontal: return $0.position.x < $1.position.x
            @unknown default: fatalError()
            }
          }
          .map(\.view)

        let nextIndex = reordered.firstIndex(of: view)!
        let prevIndex = self.views.firstIndex(of: view)!

        if nextIndex != prevIndex {
          self.update(views: reordered)
          self.layoutSubtreeIfNeeded()

          CATransaction.begin()
          CATransaction.setAnimationDuration(0.15)
          CATransaction.setAnimationTimingFunction(
            CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
          )

          for layer in cached {
            layer.position = CGPoint(x: layer.view.frame.midX, y: layer.view.frame.midY)
          }

          CATransaction.commit()
        }
      } else {
        view.mouseUp(with: event)
        stop.pointee = true
      }
    }
  }

  private class CachedViewLayer: CALayer {
    let view: NSView!

    enum CacheError: Error {
      case bitmapCreationFailed
    }

    override init(layer: Any) {
      self.view = (layer as! CachedViewLayer).view
      super.init(layer: layer)
    }

    init(view: NSView) throws {
      self.view = view

      super.init()

      guard let bitmap = view.bitmapImageRepForCachingDisplay(in: view.bounds) else {
        throw CacheError.bitmapCreationFailed
      }
      view.cacheDisplay(in: view.bounds, to: bitmap)

      frame = view.frame
      contents = bitmap.cgImage
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) { fatalError("init(coder:) has not been implemented") }
  }

  private func cacheViews() throws -> [CachedViewLayer] {
    try views.map { try cacheView(view: $0) }
  }

  private func cacheView(view: NSView) throws -> CachedViewLayer {
    try CachedViewLayer(view: view)
  }
}
