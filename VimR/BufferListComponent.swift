/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import RxSwift
import PureLayout

enum BufferListAction {

  case open(buffer: NeoVimBuffer)
}

class BufferListComponent: ViewComponent, NSTableViewDataSource, NSTableViewDelegate {

  fileprivate var buffers: [NeoVimBuffer] = []
  fileprivate let bufferList = NSTableView.standardTableView()

  fileprivate let fileItemService: FileItemService
  fileprivate let genericIcon: NSImage

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  init(source: Observable<Any>, fileItemService: FileItemService) {
    self.fileItemService = fileItemService
    self.genericIcon = fileItemService.icon(forType: "public.data")

    super.init(source: source)

    self.bufferList.dataSource = self
    self.bufferList.delegate = self
    self.bufferList.doubleAction = #selector(BufferListComponent.doubleClickAction)
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

// MARK: - Actions
extension BufferListComponent {

  func doubleClickAction(_ sender: Any?) {
    let clickedRow = self.bufferList.clickedRow
    guard clickedRow >= 0 && clickedRow < self.buffers.count else {
      return
    }

    self.publish(event: BufferListAction.open(buffer: self.buffers[clickedRow]))
  }
}

// MARK: - NSTableViewDataSource
extension BufferListComponent {

  @objc(numberOfRowsInTableView:)
  func numberOfRows(in tableView: NSTableView) -> Int {
    return self.buffers.count
  }
}

// MARK: - NSTableViewDelegate
extension BufferListComponent {

  @objc(tableView:viewForTableColumn:row:)
  func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
    let cachedCell = tableView.make(withIdentifier: "buffer-list-row", owner: self)
    let cell = cachedCell as? ImageAndTextTableCell ?? ImageAndTextTableCell(withIdentifier: "buffer-list-row")

    let buffer = self.buffers[row]
    cell.text = buffer.name ?? "No Name"
    cell.image = self.icon(forBuffer: buffer)

    return cell
  }

  fileprivate func icon(forBuffer buffer: NeoVimBuffer) -> NSImage? {
    if let fileName = buffer.fileName {

      if let url = URL(string: fileName) {
        return self.fileItemService.icon(forUrl: url)
      } else {
        return self.genericIcon
      }

    } else {
      return self.genericIcon
    }
  }
}
