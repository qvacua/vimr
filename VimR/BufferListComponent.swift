/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import RxSwift
import PureLayout

class BufferListComponent: ViewComponent, NSTableViewDataSource, NSTableViewDelegate {

  let dummy = [ "a", "b", "c" ]
  var buffers: [NeoVimBuffer] = []

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
    return source
        .filter { $0 is MainWindowAction }
        .map { $0 as! MainWindowAction }
        .subscribe(onNext: { action in
          switch action {

          case let .changeBufferList(mainWindow:_, buffers:buffers):
            self.buffers = buffers
            self.bufferList.reloadData()

          default:
            return

          }
        })
  }
}

// MARK: - NSTableViewDataSource
extension BufferListComponent {

  @objc(numberOfRowsInTableView:)
  func numberOfRows(in tableView: NSTableView) -> Int {
    return self.buffers.count
  }

  @objc(tableView:objectValueForTableColumn:row:)
  func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
    return self.buffers[row].name ?? "No Name"
  }
}

// MARK: - NSTableViewDelegate
extension BufferListComponent {

}
