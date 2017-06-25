/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import RxSwift
import PureLayout
import SwiftNeoVim

class OpenedFileList: NSView,
                      UiComponent,
                      NSTableViewDataSource,
                      NSTableViewDelegate,
                      ThemedView {

  typealias StateType = MainWindow.State

  enum Action {

    case open(NeoVimBuffer)
  }

  fileprivate(set) var theme = NeoVimView.Theme.default

  required init(source: Observable<StateType>, emitter: ActionEmitter, state: StateType) {
    self.emit = emitter.typedEmit()
    self.uuid = state.uuid

    self.genericIcon = FileUtils.icon(forType: "public.data")

    super.init(frame: .zero)

    self.bufferList.dataSource = self
    self.bufferList.allowsEmptySelection = true
    self.bufferList.delegate = self
    self.bufferList.target = self
    self.bufferList.doubleAction = #selector(OpenedFileList.doubleClickAction)

    self.addViews()

    source
      .observeOn(MainScheduler.instance)
      .subscribe(onNext: { state in
        let buffers = state.buffers.removingDuplicatesPreservingFromBeginning()
        if self.buffers == buffers && self.lastThemeMark == state.appearance.theme.mark {
          return
        }

        self.lastThemeMark = state.appearance.theme.mark
        self.theme = state.appearance.theme.payload
        self.buffers = buffers
        self.bufferList.reloadData()
        self.adjustFileViewWidth()
      })
      .disposed(by: self.disposeBag)
  }

  fileprivate let emit: (UuidAction<Action>) -> Void
  fileprivate let disposeBag = DisposeBag()

  fileprivate let uuid: String
  fileprivate var lastThemeMark = Token()

  fileprivate let bufferList = NSTableView.standardTableView()
  fileprivate let genericIcon: NSImage

  fileprivate var buffers = [NeoVimBuffer]()

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  fileprivate func addViews() {
    let scrollView = NSScrollView.standardScrollView()
    scrollView.borderType = .noBorder
    scrollView.documentView = self.bufferList

    self.addSubview(scrollView)
    scrollView.autoPinEdgesToSuperviewEdges()
  }

  fileprivate func adjustFileViewWidth() {
    let maxWidth = self.buffers.reduce(CGFloat(0)) { (curMaxWidth, buffer) in
      return max(self.text(for: buffer).size().width, curMaxWidth)
    }

    let column = self.bufferList.tableColumns[0]
    column.minWidth = maxWidth + ThemedTableCell.widthWithoutText
    column.maxWidth = column.minWidth
  }
}

// MARK: - Actions
extension OpenedFileList {

  func doubleClickAction(_ sender: Any?) {
    let clickedRow = self.bufferList.clickedRow
    guard clickedRow >= 0 && clickedRow < self.buffers.count else {
      return
    }

    self.emit(UuidAction(uuid: self.uuid, action: .open(self.buffers[clickedRow])))
  }
}

// MARK: - NSTableViewDataSource
extension OpenedFileList {

  @objc(numberOfRowsInTableView:)
  func numberOfRows(in tableView: NSTableView) -> Int {
    return self.buffers.count
  }
}

// MARK: - NSTableViewDelegate
extension OpenedFileList {

  public func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
    return tableView.make(withIdentifier: "buffer-row-view", owner: self) as? ThemedTableRow
           ?? ThemedTableRow(withIdentifier: "buffer-row-view", themedView: self)
  }

  func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
    let cachedCell = (tableView.make(withIdentifier: "buffer-cell-view", owner: self) as? ThemedTableCell)?.reset()
    let cell = cachedCell ?? ThemedTableCell(withIdentifier: "buffer-cell-view")

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
                         range: NSRange(location: name.characters.count, length: pathInfo.characters.count + 3))

    return rowText
  }

  fileprivate func icon(for buffer: NeoVimBuffer) -> NSImage? {
    if let url = buffer.url {
      return FileUtils.icon(forUrl: url)
    }

    return self.genericIcon
  }
}
