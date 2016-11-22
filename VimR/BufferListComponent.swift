/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import RxSwift
import PureLayout

class BufferListComponent: ViewComponent, NSTableViewDataSource, NSTableViewDelegate {

  let dummy = [ "a", "b", "c" ]

  let bufferList = NSTableView.standardTableView()

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override init(source: Observable<Any>) {
    super.init(source: source)

    self.bufferList.dataSource = self
    self.bufferList.delegate = self
  }

  override func addViews() {
    let scrollView = NSScrollView.standardScrollView()
    scrollView.borderType = .noBorder
    scrollView.documentView = self.bufferList

    self.addSubview(scrollView)
    scrollView.autoPinEdgesToSuperviewEdges()
  }

  override func subscription(source: Observable<Any>) -> Disposable {
    return Disposables.create()
  }
}

// MARK: - NSTableViewDataSource
extension BufferListComponent {

  @objc(numberOfRowsInTableView:)
  func numberOfRows(in tableView: NSTableView) -> Int {
    return dummy.count
  }

  @objc(tableView:objectValueForTableColumn:row:)
  func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
    return dummy[row]
  }
}

// MARK: - NSTableViewDelegate
extension BufferListComponent {

}
