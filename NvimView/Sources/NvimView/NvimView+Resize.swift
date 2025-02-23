/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import MessagePack
import NvimApi

extension NvimView {
  override public func setFrameSize(_ newSize: NSSize) {
    self.log.debug("setFrameSize: \(newSize)")

    super.setFrameSize(newSize)
    self.resizeNeoVimUi(to: newSize)
  }

  override public func viewDidEndLiveResize() {
    super.viewDidEndLiveResize()
    self.resizeNeoVimUi(to: self.bounds.size)
  }

  func discreteSize(size: CGSize) -> Size {
    Size(
      width: Int(floor(size.width / self.cellSize.width)),
      height: Int(floor(size.height / self.cellSize.height))
    )
  }

  func resizeNeoVimUi(to size: CGSize) {
    let discreteSize = self.discreteSize(size: size)
    if discreteSize == self.ugrid.size {
      self.markForRenderWholeView()
      return
    }

    self.offset.x = floor((size.width - self.cellSize.width * discreteSize.width.cgf) / 2)
    self.offset.y = floor((size.height - self.cellSize.height * discreteSize.height.cgf) / 2)

    Task {
      await self.api
        .nvimUiTryResize(width: discreteSize.width, height: discreteSize.height)
        .cauterize()
    }
  }
}
