/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import RxNeovimApi
import RxSwift

extension NvimView {

  override public func setFrameSize(_ newSize: NSSize) {
    super.setFrameSize(newSize)

    if self.isInitialResize {
      self.isInitialResize = false
      self.launchNeoVim(self.discreteSize(size: newSize))
      return
    }

    if self.usesLiveResize {
      self.resizeNeoVimUi(to: newSize)
      return
    }

    if self.inLiveResize || self.currentlyResizing {
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
    if discreteSize == self.ugrid.size {
      self.markForRenderWholeView()
      return
    }

    self.offset.x = floor(
      (size.width - self.cellSize.width * CGFloat(discreteSize.width)) / 2
    )
    self.offset.y = floor(
      (size.height - self.cellSize.height * CGFloat(discreteSize.height)) / 2
    )

    self.bridge
      .resize(width: discreteSize.width, height: discreteSize.height)
      .trigger()
  }

  private func launchNeoVim(_ size: Size) {
    logger.info("=== Starting neovim...")
    let sockPath = URL(
      fileURLWithPath: NSTemporaryDirectory()
    ).appendingPathComponent("vimr_\(self.uuid).sock").path

    self.api.msgpackRawStream
      .subscribe(onNext: { msg in
        switch msg {
        case let .notification(method, params):
          logger.debug("NOTIFICATION: \(method): \(params)")
          guard self.subscribedEvents.contains(method) else { return }
          self.eventsSubject.onNext(.rpcEvent(method, params))
        case let .error(_, msg):
          logger.debug("MSG ERROR: \(msg)")
        default:
          logger.debug("???: This should not happen")
          break
        }
      }, onError: { print("ERROR: \($0)") })
      .disposed(by: self.disposeBag)

    // We wait here, since the user of NvimView cannot subscribe
    // on the Completable. We could demand that the user call launchNeoVim()
    // by themselves, but...
    try? self.bridge
      .runLocalServerAndNvim(width: size.width, height: size.height)
      .andThen(self.api.run(at: sockPath))
      .andThen(
        self.subscribedEvents.reduce(Completable.empty()) { prev, event in
          prev.andThen(self.api.subscribe(event: event))
        }
      )
      .andThen(
        self.sourceFileUrls.reduce(Completable.empty()) { prev, url in
          prev.andThen(self.api.command(command: "source \(url.path)"))
        }
      )
      .andThen(self.bridge.notifyReadinessForRpcEvents())
      .wait()
  }

  private func randomEmoji() -> String {
    let idx = Int(arc4random_uniform(UInt32(emojis.count)))
    guard let scalar = UnicodeScalar(emojis[idx]) else {
      return "😎"
    }

    return String(scalar)
  }
}

private let emojis: [UInt32] = [
  0x1F600...0x1F64F,
  0x1F910...0x1F918,
  0x1F980...0x1F984,
  0x1F9C0...0x1F9C0
].flatMap { $0 }
