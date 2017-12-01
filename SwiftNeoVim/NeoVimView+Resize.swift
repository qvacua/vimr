/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa

extension NeoVimView {

  override public func setFrameSize(_ newSize: NSSize) {
    super.setFrameSize(newSize)

    if self.isInitialResize {
      self.isInitialResize = false
      self.launchNeoVim(self.discreteSize(size: newSize))
      return
    }

    if self.inLiveResize || self.currentlyResizing {
      // TODO: Turn off live resizing for now.
      // self.resizeNeoVimUi(to: newSize)
      return
    }

    // There can be cases where the frame is resized not by live resizing,
    // eg when the window is resized by window management tools.
    // Thus, we make sure that the resize call is made when this happens.
    self.resizeNeoVimUi(to: newSize)
  }

  override public func viewDidEndLiveResize() {
    super.viewDidEndLiveResize()
    self.resizeNeoVimUi(to: self.bounds.size)
  }

  func discreteSize(size: CGSize) -> Size {
    return Size(width: Int(floor(size.width / self.cellSize.width)),
                height: Int(floor(size.height / self.cellSize.height)))
  }

  func resizeNeoVimUi(to size: CGSize) {
    self.currentEmoji = self.randomEmoji()

    let discreteSize = self.discreteSize(size: size)
    if discreteSize == self.grid.size {
      self.markForRenderWholeView()
      return
    }

    self.xOffset = floor((size.width - self.cellSize.width * CGFloat(discreteSize.width)) / 2)
    self.yOffset = floor((size.height - self.cellSize.height * CGFloat(discreteSize.height)) / 2)

    self.agent.resize(toWidth: Int32(discreteSize.width), height: Int32(discreteSize.height))
  }

  fileprivate func launchNeoVim(_ size: Size) {
    self.logger.info("=== Starting neovim...")
    let noErrorDuringInitialization = self.agent.runLocalServerAndNeoVim(withWidth: size.width, height: size.height)

    self.nvim.connect()

    self.nvim.setOption(name: "mouse", value: .string("a"))
    self.nvim.setOption(name: "title", value: .bool(true))
    self.nvim.setOption(name: "termguicolors", value: .bool(true))

    if noErrorDuringInitialization == false {
      self.logger.fault("There was an error launching neovim.")

      let alert = NSAlert()
      alert.alertStyle = .warning
      alert.messageText = "Error during initialization"
      alert.informativeText = "There was an error during the initialization of NeoVim. " +
                              "Use :messages to view the error messages."
      alert.runModal()
    }
  }

  fileprivate func randomEmoji() -> String {
    let idx = Int(arc4random_uniform(UInt32(emojis.count)))
    guard let scalar = UnicodeScalar(emojis[idx]) else {
      return "😎"
    }

    return String(scalar)
  }
}

fileprivate let emojis: [UInt32] = [
  0x1F600...0x1F64F,
  0x1F910...0x1F918,
  0x1F980...0x1F984,
  0x1F9C0...0x1F9C0
].flatMap { $0 }
