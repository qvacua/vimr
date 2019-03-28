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

    nvimView
      .events
      .observeOn(MainScheduler.instance)
      .subscribe(onNext: { event in
        switch event {

        case .neoVimStopped: self.close()

        default: break //Swift.print("Event received: \(event)")

        }
      })
      .disposed(by: self.disposeBag)
  }

  func quitWithoutSaving() {
    try? self.nvimView.quitNeoVimWithoutSaving().wait()
    self.nvimView.waitTillNvimExits()
  }

  func windowShouldClose(_ sender: NSWindow) -> Bool {
    self.quitWithoutSaving()
    return false
  }

  override func windowControllerDidLoadNib(_ windowController: NSWindowController) {
    super.windowControllerDidLoadNib(windowController)

    let window = windowController.window!
    window.delegate = self

    let view = window.contentView!
    view.addSubview(self.nvimView)
    self.nvimView.autoPinEdgesToSuperviewEdges()
  }

  override var windowNibName: NSNib.Name? {
    // Returns the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this property and override -makeWindowControllers instead.
    return NSNib.Name("Document")
  }

  override func data(ofType typeName: String) throws -> Data {
    // Insert code here to write your document to data of the specified type, throwing an error in case of failure.
    // Alternatively, you could remove this method and override fileWrapper(ofType:), write(to:ofType:), or write(to:ofType:for:originalContentsURL:) instead.
    throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
  }

  override func read(from data: Data, ofType typeName: String) throws {
    // Insert code here to read your document from the given data of the specified type, throwing an error in case of failure.
    // Alternatively, you could remove this method and override read(from:ofType:) instead.
    // If you do, you should also override isEntireFileLoaded to return false if the contents are lazily loaded.
    throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
  }
}
