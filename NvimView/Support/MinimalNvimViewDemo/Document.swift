/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import NvimView
import PureLayout
import RxSwift
import Tabs

class Document: NSDocument, NSWindowDelegate {
  private let nvimView = NvimView(forAutoLayout: ())
  private let disposeBag = DisposeBag()

  override init() {
    super.init()

    self.nvimView.font = NSFont(name: "Fira Code", size: 13)
      ?? NSFont.userFixedPitchFont(ofSize: 13)!
    self.nvimView.usesLigatures = true

    self.nvimView
      .events
      .observe(on: MainScheduler.instance)
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

    // FIXME: Find out why we have to add tabBar after adding ws, otherwise tabBar is not visible
    // With deployment target 10_15, adding first tabBar worked fine.
    view.addSubview(nvimView)
    view.addSubview(tabBar)

    tabBar.autoPinEdge(toSuperviewEdge: .left)
    tabBar.autoPinEdge(toSuperviewEdge: .top)
    tabBar.autoPinEdge(toSuperviewEdge: .right)
    tabBar.autoSetDimension(.height, toSize: Tabs.Theme().tabBarHeight)

    nvimView.autoPinEdge(.top, to: .bottom, of: tabBar)
    nvimView.autoPinEdge(toSuperviewEdge: .left)
    nvimView.autoPinEdge(toSuperviewEdge: .right)
    nvimView.autoPinEdge(toSuperviewEdge: .bottom)
  }

  override var windowNibName: NSNib.Name? { NSNib.Name("Document") }

  override func data(ofType _: String) throws -> Data {
    throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
  }

  override func read(from _: Data, ofType _: String) throws {
    throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
  }
}

extension Document {
  @IBAction public func debug3(_: Any?) {
    self.nvimView.toggleFramerateView()
  }
}
