/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import NvimView
import PureLayout
import Tabs

@MainActor
final class ViewDelegate: NvimViewDelegate, Sendable {
  var doc: Document?

  func isMenuItemKeyEquivalent(_: NSEvent) -> Bool {
    false
  }

  func nextEvent(_ event: NvimView.Event) {
    Swift.print("EVENT: ", event)
    switch event {
    case .neoVimStopped:
      self.doc?.close()
    default: break
    }
  }
}

class Document: NSDocument, NSWindowDelegate {
  private let nvimView = NvimView(forAutoLayout: ())
  private let viewDelegate = ViewDelegate()

  override init() {
    super.init()

    self.viewDelegate.doc = self
    self.nvimView.delegate = self.viewDelegate
    self.nvimView.font = NSFont(name: "Iosevka", size: 13)
      ?? NSFont.userFixedPitchFont(ofSize: 13)!
    self.nvimView.usesLigatures = true
  }

  func quitWithoutSaving() async {
    await self.nvimView.quitNeoVimWithoutSaving()
    await self.nvimView.stop()
  }

  func windowShouldClose(_: NSWindow) -> Bool {
    Task {
      await self.quitWithoutSaving()
      await self.nvimView.stop()
    }
    
    self.close()
    return true
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
