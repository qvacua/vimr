/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import PureLayout
import RxSwift

final class PrefWindow: NSObject,
  UiComponent,
  NSWindowDelegate,
  NSTableViewDataSource, NSTableViewDelegate
{
  typealias StateType = AppState

  enum Action {
    case close
  }

  weak var shortcutService: ShortcutService? {
    didSet {
      let shortcutsPref = self.panes.first { pane in pane is ShortcutsPref } as? ShortcutsPref
      shortcutsPref?.shortcutService = self.shortcutService
    }
  }

  required init(source: Observable<StateType>, emitter: ActionEmitter, state: StateType) {
    self.emit = emitter.typedEmit()
    self.openStatusMark = state.preferencesOpen.mark

    self.windowController = NSWindowController(windowNibName: NSNib.Name("PrefWindow"))

    self.panes = [
      GeneralPref(source: source, emitter: emitter, state: state),
      ToolsPref(source: source, emitter: emitter, state: state),
      AppearancePref(source: source, emitter: emitter, state: state),
      KeysPref(source: source, emitter: emitter, state: state),
      ShortcutsPref(source: source, emitter: emitter, state: state),
      AdvancedPref(source: source, emitter: emitter, state: state),
    ]

    super.init()

    self.window.delegate = self

    self.addViews()

    source
      .observe(on: MainScheduler.instance)
      .subscribe(onNext: { state in
        if state.preferencesOpen.payload == false {
          self.openStatusMark = state.preferencesOpen.mark
          self.windowController.close()
          return
        }

        if state.preferencesOpen.mark == self.openStatusMark {
          return
        }

        self.openStatusMark = state.preferencesOpen.mark
        self.windowController.showWindow(self)
      })
      .disposed(by: self.disposeBag)
  }

  private let emit: (Action) -> Void
  private let disposeBag = DisposeBag()

  private var openStatusMark: Token

  private let windowController: NSWindowController
  private var window: NSWindow {
    self.windowController.window!
  }

  private let categoryView = NSTableView.standardSourceListTableView()
  private let categoryScrollView = NSScrollView.standardScrollView()
  private let paneContainer = NSScrollView(forAutoLayout: ())

  private let panes: [PrefPane]
  private var currentPane: PrefPane {
    get {
      self.paneContainer.documentView as! PrefPane
    }

    set {
      self.paneContainer.documentView = newValue

      // Auto-layout seems to be smart enough not to add redundant constraints.
      if newValue.pinToContainer {
        newValue.autoPinEdgesToSuperviewEdges()
      }
    }
  }

  private func addViews() {
    let categoryView = self.categoryView
    categoryView.dataSource = self
    categoryView.delegate = self

    let categoryScrollView = self.categoryScrollView
    categoryScrollView.documentView = categoryView

    let paneContainer = self.paneContainer
    paneContainer.hasVerticalScroller = true
    paneContainer.hasHorizontalScroller = true
    paneContainer.autohidesScrollers = true
    paneContainer.borderType = .noBorder
    paneContainer.autoresizesSubviews = false
    paneContainer.backgroundColor = NSColor.windowBackgroundColor

    self.window.contentView?.addSubview(categoryScrollView)
    self.window.contentView?.addSubview(paneContainer)

    categoryScrollView.autoSetDimension(.width, toSize: 150)
    categoryScrollView.autoPinEdge(toSuperviewEdge: .top, withInset: -1)
    categoryScrollView.autoPinEdge(toSuperviewEdge: .bottom, withInset: -1)
    categoryScrollView.autoPinEdge(toSuperviewEdge: .left, withInset: -1)

    paneContainer.autoSetDimension(.width, toSize: 200, relation: .greaterThanOrEqual)
    paneContainer.autoPinEdge(toSuperviewEdge: .top)
    paneContainer.autoPinEdge(toSuperviewEdge: .right)
    paneContainer.autoPinEdge(toSuperviewEdge: .bottom)
    paneContainer.autoPinEdge(.left, to: .right, of: categoryScrollView)

    self.currentPane = self.panes[0]
  }
}

// MARK: - NSWindowDelegate

extension PrefWindow {
  func windowShouldClose(_: NSWindow) -> Bool {
    self.emit(.close)

    return false
  }

  func windowWillClose(_: Notification) {
    self.panes.forEach { $0.windowWillClose() }
  }
}

// MARK: - NSTableViewDataSource

extension PrefWindow {
  @objc(numberOfRowsInTableView:) func numberOfRows(in _: NSTableView) -> Int {
    self.panes.count
  }

  @objc(tableView: objectValueForTableColumn:row:) func tableView(
    _: NSTableView,
    objectValueFor _: NSTableColumn?,
    row: Int
  ) -> Any? {
    self.panes[row].displayName
  }
}

// MARK: - NSTableViewDelegate

extension PrefWindow {
  func tableViewSelectionDidChange(_: Notification) {
    let idx = self.categoryView.selectedRow
    self.panes[idx].paneWillAppear()
    self.currentPane = self.panes[idx]
  }
}
