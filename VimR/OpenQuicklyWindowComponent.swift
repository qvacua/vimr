/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import PureLayout
import RxSwift

class OpenQuicklyWindowComponent: WindowComponent, NSWindowDelegate, NSTableViewDelegate, NSTableViewDataSource {
  
  private let searchField = NSTextField(forAutoLayout: ())
  private let cwdControl = NSPathControl(forAutoLayout: ())

  init(source: Observable<Any>) {
    super.init(source: source, nibName: "OpenQuicklyWindow")

    self.window.delegate = self
  }

  override func addViews() {
    let cwdControl = self.cwdControl
    cwdControl.pathStyle = .Standard
    cwdControl.backgroundColor = NSColor.clearColor()
    cwdControl.refusesFirstResponder = true
    cwdControl.cell?.controlSize = .SmallControlSize
    cwdControl.cell?.font = NSFont.systemFontOfSize(NSFont.smallSystemFontSize())
    cwdControl.setContentCompressionResistancePriority(NSLayoutPriorityDefaultLow, forOrientation:.Horizontal)

    let searchField = self.searchField

    self.window.contentView?.addSubview(searchField)
    self.window.contentView?.addSubview(cwdControl)

    searchField.autoPinEdgeToSuperviewEdge(.Top, withInset: 18)
    searchField.autoPinEdgeToSuperviewEdge(.Right, withInset: 18)
    searchField.autoPinEdgeToSuperviewEdge(.Left, withInset: 18)

    cwdControl.autoPinEdge(.Top, toEdge: .Bottom, ofView: searchField, withOffset: 18)
    cwdControl.autoPinEdge(.Right, toEdge: .Right, ofView: searchField)
    cwdControl.autoPinEdge(.Left, toEdge: .Left, ofView: searchField)
    cwdControl.autoPinEdgeToSuperviewEdge(.Bottom, withInset: 18)
  }

  override func subscription(source source: Observable<Any>) -> Disposable {
    return NopDisposable.instance
  }
  
  func show(forMainWindow mainWindow: MainWindowComponent) {
    self.cwdControl.URL = mainWindow.cwd
    self.show()
    
    self.searchField.becomeFirstResponder()
  }
}
