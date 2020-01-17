/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import RxSwift
import RxCocoa
import PureLayout

class OpenQuicklyWindow: NSObject,
                         UiComponent,
                         NSWindowDelegate,
                         NSTextFieldDelegate,
                         NSTableViewDelegate, NSTableViewDataSource {

  typealias StateType = AppState

  enum Action {

    case open(URL)
    case close
  }

  required init(source: Observable<StateType>, emitter: ActionEmitter, state: StateType) {
    self.emit = emitter.typedEmit()
    self.windowController = NSWindowController(windowNibName: NSNib.Name("OpenQuicklyWindow"))

    self.searchStream = self.searchField.rx
      .text.orEmpty
      .throttle(.milliseconds(2 * 500), latest: true, scheduler: MainScheduler.instance)
      .distinctUntilChanged()

    super.init()

    self.window.delegate = self

    self.addViews()

    source
      .observeOn(MainScheduler.instance)
      .subscribe(onNext: { state in
        guard state.openQuickly.open else {
          self.windowController.close()
          return
        }

        if self.window.isKeyWindow {
          // already open, so do nothing
          return
        }

        self.cwd = state.openQuickly.cwd
        self.cwdPathCompsCount = self.cwd.pathComponents.count
        self.cwdControl.url = self.cwd

        self.searchStream
          .subscribe(onNext: { pattern in
            self.pattern = pattern
          })
          .disposed(by: self.disposeBag)

        self.windowController.showWindow(self)
      })
      .disposed(by: self.disposeBag)
  }

  func startProgress() {
    self.progressIndicator.startAnimation(self)
  }

  func endProgress() {
    self.progressIndicator.stopAnimation(self)
  }

  private let emit: (Action) -> Void
  private let disposeBag = DisposeBag()

  private(set) var cwd = FileUtils.userHomeUrl
  private var cwdPathCompsCount = 0

  // FIXME: migrate to State later...
  private(set) var pattern = ""
  private(set) var fileViewItems = [ScoredFileItem]()
  private var count = 0

  private let windowController: NSWindowController

  private let searchField = NSTextField(forAutoLayout: ())
  private let progressIndicator = NSProgressIndicator(forAutoLayout: ())
  private let cwdControl = NSPathControl(forAutoLayout: ())
  private let countField = NSTextField(forAutoLayout: ())
  private let fileView = NSTableView.standardTableView()

  private let searchStream: Observable<String>

  private var window: NSWindow {
    return self.windowController.window!
  }

  private func addViews() {
    let searchField = self.searchField
    searchField.rx.delegate.setForwardToDelegate(self, retainDelegate: false)

    let progressIndicator = self.progressIndicator
    progressIndicator.isIndeterminate = true
    progressIndicator.isDisplayedWhenStopped = false
    progressIndicator.style = .spinning
    progressIndicator.controlSize = .small

    let fileView = self.fileView
    fileView.intercellSpacing = CGSize(width: 4, height: 4)
    fileView.dataSource = self
    fileView.delegate = self

    let fileScrollView = NSScrollView.standardScrollView()
    fileScrollView.autoresizesSubviews = true
    fileScrollView.documentView = fileView

    let cwdControl = self.cwdControl
    cwdControl.pathStyle = .standard
    cwdControl.backgroundColor = NSColor.clear
    cwdControl.refusesFirstResponder = true
    cwdControl.cell?.controlSize = .small
    cwdControl.cell?.font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
    cwdControl.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

    let countField = self.countField
    countField.isEditable = false
    countField.isBordered = false
    countField.alignment = .right
    countField.backgroundColor = NSColor.clear
    countField.stringValue = "0 items"

    let contentView = self.window.contentView!
    contentView.addSubview(searchField)
    contentView.addSubview(progressIndicator)
    contentView.addSubview(fileScrollView)
    contentView.addSubview(cwdControl)
    contentView.addSubview(countField)

    searchField.autoPinEdge(toSuperviewEdge: .top, withInset: 8)
    searchField.autoPinEdge(toSuperviewEdge: .right, withInset: 8)
    searchField.autoPinEdge(toSuperviewEdge: .left, withInset: 8)

    progressIndicator.autoAlignAxis(.horizontal, toSameAxisOf: searchField)
    progressIndicator.autoPinEdge(.right, to: .right, of: searchField, withOffset: -4)

    fileScrollView.autoPinEdge(.top, to: .bottom, of: searchField, withOffset: 8)
    fileScrollView.autoPinEdge(toSuperviewEdge: .left, withInset: -1)
    fileScrollView.autoPinEdge(toSuperviewEdge: .right, withInset: -1)
    fileScrollView.autoSetDimension(.height, toSize: 200, relation: .greaterThanOrEqual)

    cwdControl.autoPinEdge(.top, to: .bottom, of: fileScrollView, withOffset: 4)
//    cwdControl.autoPinEdge(toSuperviewEdge: .bottom)
    cwdControl.autoPinEdge(toSuperviewEdge: .left, withInset: 2)
    cwdControl.autoPinEdge(toSuperviewEdge: .bottom, withInset: 4)

//    countField.autoPinEdge(toSuperviewEdge: .bottom)
    countField.autoPinEdge(.top, to: .bottom, of: fileScrollView, withOffset: 4)
    countField.autoPinEdge(toSuperviewEdge: .right, withInset: 2)
    countField.autoPinEdge(.left, to: .right, of: cwdControl, withOffset: 4)
  }
}

// MARK: - NSTableViewDataSource
extension OpenQuicklyWindow {

  @objc(numberOfRowsInTableView:)
  func numberOfRows(in _: NSTableView) -> Int {
    return self.fileViewItems.count
  }
}

// MARK: - NSTableViewDelegate
extension OpenQuicklyWindow {

  func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
    return OpenQuicklyFileViewRow()
  }

  @objc(tableView: viewForTableColumn:row:)
  func tableView(_ tableView: NSTableView, viewFor _: NSTableColumn?, row: Int) -> NSView? {
    let cachedCell = (tableView.makeView(
      withIdentifier: NSUserInterfaceItemIdentifier("file-view-row"), owner: self) as? ImageAndTextTableCell
    )?.reset()
    let cell = cachedCell ?? ImageAndTextTableCell(withIdentifier: "file-view-row")

    let url = self.fileViewItems[row].url
    cell.attributedText = self.rowText(for: url as URL)
    cell.image = FileUtils.icon(forUrl: url)

    return cell
  }

  private func rowText(for url: URL) -> NSAttributedString {
    let pathComps = url.pathComponents
    let truncatedPathComps = pathComps[self.cwdPathCompsCount..<pathComps.count]
    let name = truncatedPathComps.last!

    if truncatedPathComps.dropLast().isEmpty {
      return NSMutableAttributedString(string: name)
    }

    let rowText: NSMutableAttributedString
    let pathInfo = truncatedPathComps.dropLast().reversed().joined(separator: " / ")
    rowText = NSMutableAttributedString(string: "\(name) — \(pathInfo)")
    rowText.addAttribute(NSAttributedString.Key.foregroundColor,
                         value: NSColor.lightGray,
                         range: NSRange(location: name.count, length: pathInfo.count + 3))

    return rowText
  }
}

// MARK: - NSTextFieldDelegate
extension OpenQuicklyWindow {

  @objc(control: textView:doCommandBySelector:)
  func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
    switch commandSelector {
    case NSSelectorFromString("cancelOperation:"):
      self.window.performClose(self)
      return true

    case NSSelectorFromString("insertNewline:"):
      // TODO open the url
      self.emit(.open(self.fileViewItems[self.fileView.selectedRow].url))
      self.window.performClose(self)
      return true

    case NSSelectorFromString("moveUp:"):
      self.moveSelection(ofTableView: self.fileView, byDelta: -1)
      return true

    case NSSelectorFromString("moveDown:"):
      self.moveSelection(ofTableView: self.fileView, byDelta: 1)
      return true

    default:
      return false
    }
  }

  private func moveSelection(ofTableView tableView: NSTableView, byDelta delta: Int) {
    let selectedRow = tableView.selectedRow
    let lastIdx = tableView.numberOfRows - 1
    let targetIdx: Int

    if selectedRow + delta < 0 {
      targetIdx = 0
    } else if selectedRow + delta > lastIdx {
      targetIdx = lastIdx
    } else {
      targetIdx = selectedRow + delta
    }

    tableView.selectRowIndexes(IndexSet(integer: targetIdx), byExtendingSelection: false)
    tableView.scrollRowToVisible(targetIdx)
  }
}

// MARK: - NSWindowDelegate
extension OpenQuicklyWindow {

  func windowShouldClose(_: NSWindow) -> Bool {
    self.emit(.close)

    return false
  }

  func windowWillClose(_: Notification) {
    self.endProgress()

    self.count = 0

    self.pattern = ""
    self.fileViewItems = []
    self.fileView.reloadData()

    self.searchField.stringValue = ""
    self.countField.stringValue = "0 items"
  }

  func windowDidResignKey(_: Notification) {
    self.window.performClose(self)
  }
}
