/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import SwiftNeoVim
import PureLayout

class ViewController: NSViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    self.addViews()
  }

  override var representedObject: Any? {
    didSet {
      // Update the view, if already loaded.
    }
  }

  public required init?(coder: NSCoder) {
    self.neoVimView = NeoVimView(frame: .zero, config: NeoVimView.Config(useInteractiveZsh: false))

    super.init(coder: coder)
  }

  fileprivate let neoVimView: NeoVimView

  fileprivate func addViews() {
    self.neoVimView.configureForAutoLayout()
    self.view.addSubview(self.neoVimView)
    self.neoVimView.autoPinEdgesToSuperviewEdges()
  }
}
