//
// Created by Tae Won Ha on 02.09.18.
// Copyright (c) 2018 Tae Won Ha. All rights reserved.
//

import Cocoa

extension NvimView {

  var bufferLayer: CGLayer? {
    if self._bufferLayer == nil && self.lockFocusIfCanDraw(),
       let current = NSGraphicsContext.current?.cgContext {

      self._bufferLayer = CGLayer(
        current, size: self.bounds.size.scaling(self.scaleFactor),
        auxiliaryInfo: nil
      )
      self.unlockFocus()
    }

    return self._bufferLayer
  }

  var bufferContext: CGContext? {
    if self._bufferContext == nil {
      self._bufferContext = self.bufferLayer?.context

      self._bufferContext?.scaleBy(x: self.scaleFactor, y: self.scaleFactor)

      // When both anti-aliasing and font smoothing is turned on,
      // then the "Use LCD font smoothing when available" setting is used
      // to render texts, cf. chapter 11 from "Programming with Quartz".
      self._bufferContext?.setShouldSmoothFonts(true);
      self._bufferContext?.setTextDrawingMode(.fill);
    }

    return self._bufferContext
  }

  func resetBuffer() {
    self._bufferLayer = nil
    self._bufferContext = nil
  }

  override public func viewDidChangeBackingProperties() {
    self.scaleFactor = self.window?.screen?.backingScaleFactor ?? 1
    self.scaleMatrix = CGAffineTransform.identity.scaledBy(
      x: self.scaleFactor, y: self.scaleFactor
    )
  }
}
