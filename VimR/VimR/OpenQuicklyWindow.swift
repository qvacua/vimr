/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import Commons
import os
import PureLayout
import RxCocoa
import RxSwift

final class OpenQuicklyWindow: NSObject,
  UiComponent,
  NSWindowDelegate,
  NSTextFieldDelegate,
  NSTableViewDelegate
{
  typealias StateType = AppState

  enum Action {
    case setUsesVcsIgnores(Bool)
    case open(URL)
    case close
  }

  @objc private(set) dynamic var unsortedScoredUrls = [ScoredUrl]()

  // Call this only when quitting
  func cleanUp() {
    self.searchServicePerRootUrl.values.forEach { $0.cleanUp() }
    self.searchServicePerRootUrl.removeAll()
  }

  @objc func useVcsAction(_: Any?) {
    self.scanToken = Token()
    self.currentSearchService?.stopScanScore()
    self.endProgress()
    self.unsortedScoredUrls.removeAll()

    self.emit(.setUsesVcsIgnores(self.useVcsIgnoresCheckBox.boolState))
  }

  required init(source: Observable<StateType>, emitter: ActionEmitter, state: StateType) {
    self.emit = emitter.typedEmit()
    self.windowController = NSWindowController(windowNibName: NSNib.Name("OpenQuicklyWindow"))
    self.searchStream = self.searchField.rx
      .text.orEmpty
      .throttle(.milliseconds(1 * 500), latest: true, scheduler: MainScheduler.instance)
      .distinctUntilChanged()

    super.init()

    self.configureWindow()
    self.addViews()

    source
      .observe(on: MainScheduler.instance)
      .subscribe(onNext: { [weak self] state in self?.subscription(state) })
      .disposed(by: self.disposeBag)
  }

  // MARK: - Private

  private let emit: (Action) -> Void
  private let disposeBag = DisposeBag()

  private let searchStream: Observable<String>
  private var perSessionDisposeBag = DisposeBag()
  private var cwdPathCompsCount = 0
  private var usesVcsIgnores = true
  private var scanToken = Token()

  private var searchServicePerRootUrl: [URL: FuzzySearchService] = [:]
  private var currentSearchService: FuzzySearchService?
  private let scoredUrlsController = NSArrayController()

  private let windowController: NSWindowController
  private let titleField = NSTextField.defaultTitleTextField()
  private let useVcsIgnoresCheckBox = NSButton(forAutoLayout: ())
  private let searchField = NSTextField(forAutoLayout: ())
  private let progressIndicator = NSProgressIndicator(forAutoLayout: ())
  private let cwdControl = NSPathControl(forAutoLayout: ())
  private let fileView = NSTableView.standardTableView()

  private let log = OSLog(
    subsystem: Defs.loggerSubsystem,
    category: Defs.LoggerCategory.ui
  )

  private var window: NSWindow { self.windowController.window! }

  private func configureWindow() {
    [
      NSWindow.ButtonType.closeButton,
      NSWindow.ButtonType.miniaturizeButton,
      NSWindow.ButtonType.zoomButton,
    ].forEach { self.window.standardWindowButton($0)?.isHidden = true }
    self.window.delegate = self
  }

  private func subscription(_ state: StateType) {
    self.updateRootUrls(state: state)

    guard state.openQuickly.open, let curWinState = state.currentMainWindow else {
      self.windowController.close()
      return
    }

    let windowIsOpen = self.window.isKeyWindow

    // The window is open and the user changed the setting
    if self.usesVcsIgnores != curWinState.usesVcsIgnores, windowIsOpen {
      self.usesVcsIgnores = curWinState.usesVcsIgnores
      self.useVcsIgnoresCheckBox.boolState = curWinState.usesVcsIgnores

      self.scanToken = Token()
      self.currentSearchService?.usesVcsIgnores = self.usesVcsIgnores
      self.unsortedScoredUrls.removeAll()

      let pattern = self.searchField.stringValue
      if pattern.count >= 2 { self.scanAndScore(pattern) }

      return
    }

    // already open, so do nothing
    if windowIsOpen { return }

    self.usesVcsIgnores = curWinState.usesVcsIgnores

    // TODO: read global vcs ignores
    self.prepareSearch(curWinState: curWinState)
    self.windowController.showWindow(nil)
    self.searchField.beFirstResponder()
  }

  private func prepareSearch(curWinState: MainWindow.State) {
    self.usesVcsIgnores = curWinState.usesVcsIgnores
    self.useVcsIgnoresCheckBox.boolState = curWinState.usesVcsIgnores

    let cwd = curWinState.cwd
    self.currentSearchService = self.searchServicePerRootUrl[cwd]
    self.cwdPathCompsCount = cwd.pathComponents.count
    self.cwdControl.url = cwd

    self.searchStream
      .observe(on: MainScheduler.instance)
      .subscribe(onNext: { [weak self] pattern in
        self?.scanAndScore(pattern)
      })
      .disposed(by: self.perSessionDisposeBag)
  }

  private func reset() {
    self.scanToken = Token()
    self.currentSearchService?.stopScanScore()
    self.currentSearchService = nil

    self.endProgress()
    self.unsortedScoredUrls.removeAll()
    self.searchField.stringValue = ""
    self.perSessionDisposeBag = DisposeBag()
  }

  private func scanAndScore(_ pattern: String) {
    self.currentSearchService?.stopScanScore()

    guard pattern.count >= 2 else {
      self.unsortedScoredUrls.removeAll()
      return
    }

    self.scanToken = Token()
    let localToken = self.scanToken

    self.unsortedScoredUrls.removeAll()
    self.currentSearchService?.scanScore(
      for: pattern,
      beginCallback: { self.startProgress() },
      endCallback: { self.endProgress() }
    ) { scoredUrls in
      DispatchQueue.main.async {
        guard localToken == self.scanToken else { return }
        self.unsortedScoredUrls.append(contentsOf: scoredUrls)
      }
    }
  }

  private func startProgress() {
    DispatchQueue.main.async { self.progressIndicator.startAnimation(self) }
  }

  private func endProgress() {
    DispatchQueue.main.async { self.progressIndicator.stopAnimation(self) }
  }

  private func updateRootUrls(state: AppState) {
    let urlsToMonitor = Set(state.mainWindows.map { $1.cwd })
    let currentUrls = Set(self.searchServicePerRootUrl.map { url, _ in url })

    let newUrls = urlsToMonitor.subtracting(currentUrls)
    let obsoleteUrls = currentUrls.subtracting(urlsToMonitor)

    for url in newUrls {
      self.log.info("Adding \(url) and its service.")
      guard let service = try? FuzzySearchService(root: url) else {
        self.log.error("Could not create FileService for \(url)")
        continue
      }

      self.searchServicePerRootUrl[url] = service
    }

    for url in obsoleteUrls {
      self.log.info("Removing \(url) and its service.")
      self.searchServicePerRootUrl.removeValue(forKey: url)
    }
  }

  private func addViews() {
    let useVcsIg = self.useVcsIgnoresCheckBox
    useVcsIg.setButtonType(.switch)
    useVcsIg.controlSize = .mini
    useVcsIg.title = "Use VCS Ignores"
    useVcsIg.target = self
    useVcsIg.action = #selector(OpenQuicklyWindow.useVcsAction)

    let title = self.titleField
    title.font = .boldSystemFont(ofSize: 11)
    title.stringValue = "Open Quickly"

    let searchField = self.searchField
    searchField.rx.delegate.setForwardToDelegate(self, retainDelegate: false)

    let progressIndicator = self.progressIndicator
    progressIndicator.isIndeterminate = true
    progressIndicator.isDisplayedWhenStopped = false
    progressIndicator.style = .spinning
    progressIndicator.controlSize = .small

    let fileView = self.fileView
    fileView.intercellSpacing = CGSize(width: 4, height: 4)

    let c = self.scoredUrlsController
    c.avoidsEmptySelection = false
    c.preservesSelection = true
    c.objectClass = ScoredUrl.self
    c.sortDescriptors = [NSSortDescriptor(key: "score", ascending: false)]
    c.automaticallyRearrangesObjects = true
    c.bind(.contentArray, to: self, withKeyPath: "unsortedScoredUrls")

    fileView.bind(.content, to: c, withKeyPath: "arrangedObjects")
    fileView.bind(.selectionIndexes, to: c, withKeyPath: "selectionIndexes")
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

    let contentView = self.window.contentView!
    contentView.addSubview(title)
    contentView.addSubview(useVcsIg)
    contentView.addSubview(searchField)
    contentView.addSubview(progressIndicator)
    contentView.addSubview(fileScrollView)
    contentView.addSubview(cwdControl)

    title.autoPinEdge(toSuperviewEdge: .left, withInset: 8)
    title.autoPinEdge(toSuperviewEdge: .top, withInset: 8)

    useVcsIg.autoAlignAxis(.horizontal, toSameAxisOf: title)
    useVcsIg.autoPinEdge(toSuperviewEdge: .right, withInset: 8)

    searchField.autoPinEdge(.top, to: .bottom, of: useVcsIg, withOffset: 8)
    searchField.autoPinEdge(.left, to: .left, of: title)
    searchField.autoPinEdge(.right, to: .right, of: useVcsIg)

    fileScrollView.autoPinEdge(.top, to: .bottom, of: searchField, withOffset: 8)
    fileScrollView.autoPinEdge(toSuperviewEdge: .left, withInset: -1)
    fileScrollView.autoPinEdge(toSuperviewEdge: .right, withInset: -1)
    fileScrollView.autoSetDimension(.height, toSize: 200, relation: .greaterThanOrEqual)

    cwdControl.autoPinEdge(.top, to: .bottom, of: fileScrollView, withOffset: 4)
    cwdControl.autoPinEdge(toSuperviewEdge: .left, withInset: 2)
    cwdControl.autoPinEdge(toSuperviewEdge: .bottom, withInset: 4)

    progressIndicator.autoAlignAxis(.horizontal, toSameAxisOf: cwdControl)
    progressIndicator.autoPinEdge(.left, to: .right, of: cwdControl, withOffset: 4)
    progressIndicator.autoPinEdge(toSuperviewEdge: .right, withInset: 8)
  }
}

// MARK: - NSTableViewDelegate

extension OpenQuicklyWindow {
  func tableView(_: NSTableView, rowViewForRow _: Int) -> NSTableRowView? {
    OpenQuicklyFileViewRow()
  }

  func tableView(_ tableView: NSTableView, viewFor _: NSTableColumn?, row: Int) -> NSView? {
    let cachedCell = (
      tableView.makeView(
        withIdentifier: NSUserInterfaceItemIdentifier("file-view-row"),
        owner: self
      ) as? ImageAndTextTableCell
    )?.reset()
    let cell = cachedCell ?? ImageAndTextTableCell(withIdentifier: "file-view-row")

    guard let sortedUrls = self.scoredUrlsController.arrangedObjects as? [ScoredUrl] else {
      self.log.error("Could not convert arranged objects to [ScoredUrl].")
      return nil
    }

    let url = sortedUrls[row].url
    cell.attributedText = self.rowText(for: url as URL)
    cell.image = FileUtils.icon(forUrl: url)

    return cell
  }

  private func rowText(for url: URL) -> NSAttributedString {
    let pathComps = url.pathComponents
    let truncatedPathComps = pathComps[self.cwdPathCompsCount..<pathComps.count]
    let name = truncatedPathComps.last!

    if truncatedPathComps.dropLast().isEmpty { return NSMutableAttributedString(string: name) }

    let rowText: NSMutableAttributedString
    let pathInfo = truncatedPathComps.dropLast().reversed().joined(separator: " / ")
    rowText = NSMutableAttributedString(string: "\(name) — \(pathInfo)")
    rowText.addAttribute(
      NSAttributedString.Key.foregroundColor,
      value: NSColor.textColor,
      range: NSRange(location: 0, length: name.count)
    )
    rowText.addAttribute(
      NSAttributedString.Key.foregroundColor,
      value: NSColor.lightGray,
      range: NSRange(location: name.count, length: pathInfo.count + 3)
    )

    return rowText
  }
}

// MARK: - NSTextFieldDelegate

extension OpenQuicklyWindow {
  func control(
    _: NSControl,
    textView _: NSTextView,
    doCommandBy commandSelector: Selector
  ) -> Bool {
    switch commandSelector {
    case NSSelectorFromString("cancelOperation:"):
      self.window.performClose(self)
      return true

    case NSSelectorFromString("insertNewline:"):
      guard let sortedUrls = self.scoredUrlsController.arrangedObjects as? [ScoredUrl] else {
        self.log.error("Could not convert arranged objects to [ScoredUrl].")
        return true
      }

      let selectedRow = self.fileView.selectedRow
      guard selectedRow >= 0, selectedRow < sortedUrls.count else { return false }

      self.emit(.open(sortedUrls[selectedRow].url))
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
    let targetIdx: Int = if selectedRow + delta < 0 {
      0
    } else if selectedRow + delta > lastIdx {
      lastIdx
    } else {
      selectedRow + delta
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

  func windowWillClose(_: Notification) { self.reset() }

  func windowDidResignKey(_: Notification) { self.window.performClose(self) }
}
