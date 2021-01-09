/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import NvimView
import PureLayout
import RxSwift

class Document: NSDocument, NSWindowDelegate {
  private var nvimView = NvimView(forAutoLayout: ())
  private let disposeBag = DisposeBag()

  override init() {
    super.init()

    self.nvimView.font = NSFont(name: "Fira Code", size: 13)
      ?? NSFont.userFixedPitchFont(ofSize: 13)!
    self.nvimView.usesLigatures = true
    self.nvimView.drawsParallel = true

    self.nvimView
      .events
      .observeOn(MainScheduler.instance)
      .subscribe(onNext: { event in
        switch event {
        case .neoVimStopped: self.close()
        default: break
        }
      })
      .disposed(by: self.disposeBag)
  }

  func quitWithoutSaving() {
    try? self.nvimView.quitNeoVimWithoutSaving().wait()
    self.nvimView.waitTillNvimExits()
  }

  func windowShouldClose(_: NSWindow) -> Bool {
    self.quitWithoutSaving()
    return false
  }

  override func windowControllerDidLoadNib(_ windowController: NSWindowController) {
    super.windowControllerDidLoadNib(windowController)

    let window = windowController.window!
    window.delegate = self

    let view = window.contentView!
    let nvimView = self.nvimView
    // We know that we use custom tabs.
    let tabBar = nvimView.tabBar!

    view.addSubview(tabBar)
    view.addSubview(nvimView)

    tabBar.autoPinEdge(toSuperviewEdge: .left)
    tabBar.autoPinEdge(toSuperviewEdge: .top)
    tabBar.autoPinEdge(toSuperviewEdge: .right)
    nvimView.autoPinEdge(.top, to: .bottom, of: tabBar)
    nvimView.autoPinEdge(toSuperviewEdge: .left)
    nvimView.autoPinEdge(toSuperviewEdge: .right)
    nvimView.autoPinEdge(toSuperviewEdge: .bottom)
  }

  override var windowNibName: NSNib.Name? {
    NSNib.Name("Document")
  }

  override func data(ofType _: String) throws -> Data {
    throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
  }

  override func read(from _: Data, ofType _: String) throws {
    throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
  }
}
