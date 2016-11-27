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
        .subscribe(onNext: { [unowned self] action in
          switch action {

          case let .changeBufferList(mainWindow:_, buffers:buffers):
            self.buffers = buffers
            self.bufferList.reloadData()
            self.adjustFileViewWidth()

          default:
            return

          }
        })
  }

  fileprivate func adjustFileViewWidth() {
    let maxWidth = self.buffers.reduce(CGFloat(0)) { (curMaxWidth, buffer) in
      return max(self.text(for: buffer).size().width, curMaxWidth)
    }

    let column = self.bufferList.tableColumns[0]
    column.minWidth = maxWidth + ImageAndTextTableCell.widthWithoutText
    column.maxWidth = column.minWidth
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
    let cachedCell = (tableView.make(withIdentifier: "buffer-list-row", owner: self) as? ImageAndTextTableCell)?.reset()
    let cell = cachedCell ?? ImageAndTextTableCell(withIdentifier: "buffer-list-row")

    let buffer = self.buffers[row]
    cell.attributedText = self.text(for: buffer)
    cell.image = self.icon(for: buffer)

    return cell
  }

  fileprivate func text(for buffer: NeoVimBuffer) -> NSAttributedString {
    guard let name = buffer.name else {
      return NSAttributedString(string: "No Name")
    }

    guard let url = buffer.url else {
      return NSAttributedString(string: name)
    }

    let pathInfo = url.pathComponents.dropFirst().dropLast().reversed().joined(separator: " / ") + " /"
    let rowText = NSMutableAttributedString(string: "\(name) — \(pathInfo)")
    rowText.addAttribute(NSForegroundColorAttributeName,
                         value: NSColor.lightGray,
                         range: NSRange(location:name.characters.count, length: pathInfo.characters.count + 3))

    return rowText
  }

  fileprivate func icon(for buffer: NeoVimBuffer) -> NSImage? {
    if let url = buffer.url {
      return self.fileItemService.icon(forUrl: url)
    }

    return self.genericIcon
  }
}
