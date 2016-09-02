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

  private var cwd = NSURL(fileURLWithPath: NSHomeDirectory(), isDirectory: true) {
    didSet {
      self.cwdControl.URL = self.cwd
    }
  }

  init(source: Observable<Any>) {
    super.init(source: source, nibName: "OpenQuicklyWindow")

    self.window.delegate = self
  }

  override func addViews() {
    let searchField = self.searchField

    let fileView = NSTableView.standardSourceListTableView()
    fileView.setDataSource(self)
    fileView.setDelegate(self)

    let fileScrollView = NSScrollView.standardScrollView()
    fileScrollView.documentView = fileView

    let cwdControl = self.cwdControl
    cwdControl.pathStyle = .Standard
    cwdControl.backgroundColor = NSColor.clearColor()
    cwdControl.refusesFirstResponder = true
    cwdControl.cell?.controlSize = .SmallControlSize
    cwdControl.cell?.font = NSFont.systemFontOfSize(NSFont.smallSystemFontSize())
    cwdControl.setContentCompressionResistancePriority(NSLayoutPriorityDefaultLow, forOrientation:.Horizontal)

    let contentView = self.window.contentView!
    contentView.addSubview(searchField)
    contentView.addSubview(fileScrollView)
    contentView.addSubview(cwdControl)

    searchField.autoPinEdgeToSuperviewEdge(.Top, withInset: 18)
    searchField.autoPinEdgeToSuperviewEdge(.Right, withInset: 18)
    searchField.autoPinEdgeToSuperviewEdge(.Left, withInset: 18)

    fileScrollView.autoPinEdge(.Top, toEdge: .Bottom, ofView: searchField, withOffset: 18)
    fileScrollView.autoPinEdge(.Right, toEdge: .Right, ofView: searchField)
    fileScrollView.autoPinEdge(.Left, toEdge: .Left, ofView: searchField)
    fileScrollView.autoSetDimension(.Height, toSize: 300)

    cwdControl.autoPinEdge(.Top, toEdge: .Bottom, ofView: fileView, withOffset: 18)
    cwdControl.autoPinEdge(.Right, toEdge: .Right, ofView: searchField)
    cwdControl.autoPinEdge(.Left, toEdge: .Left, ofView: searchField)
    cwdControl.autoPinEdgeToSuperviewEdge(.Bottom, withInset: 18)
  }

  override func subscription(source source: Observable<Any>) -> Disposable {
    return NopDisposable.instance
  }
  
  func show(forMainWindow mainWindow: MainWindowComponent) {
    self.cwd = mainWindow.cwd
    self.show()
    
    self.searchField.becomeFirstResponder()
  }
}

// MARK: - NSTableViewDataSource
extension OpenQuicklyWindowComponent {

  func numberOfRowsInTableView(_: NSTableView) -> Int {
    return 2
  }

  func tableView(_: NSTableView, objectValueForTableColumn _: NSTableColumn?, row: Int) -> AnyObject? {
    return "!!!"
  }
}

// MARK: - NSTableViewDelegate
extension OpenQuicklyWindowComponent {

  func tableViewSelectionDidChange(_: NSNotification) {
    Swift.print("selection changed")
  }
}
