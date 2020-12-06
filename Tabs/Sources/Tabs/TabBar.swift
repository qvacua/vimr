/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import PureLayout

public protocol TabRepresentative: Hashable {
  var title: String { get }
  var isSelected: Bool { get }
}

public class TabBar<Entry: TabRepresentative>: NSView {
  public var theme: Theme { self._theme }
  public var selectHandler: ((Int, Entry) -> Void)?
  public var reorderHandler: ((Int, Entry) -> Void)?

  public init(withTheme theme: Theme) {
    self._theme = theme

    super.init(frame: .zero)
    self.configureForAutoLayout()
    self.wantsLayer = true
    self.layer?.backgroundColor = theme.backgroundColor.cgColor

    self.addViews()
  }

  public func update(tabRepresentatives entries: [Entry]) {
    var result = [Tab<Entry>]()
    entries.forEach { entry in
      if let existingTab = self.tabs.first(where: { $0.tabRepresentative == entry }) {
        existingTab.tabRepresentative = entry
        result.append(existingTab)
      } else {
        result.append(Tab(withTabRepresentative: entry, in: self))
      }
    }

    result.forEach { $0.position = [] }
    result.first?.position.insert(.first)
    result.last?.position.insert(.last)

    self.stackView.update(views: result)
    self.tabs = result
  }

  override public func draw(_: NSRect) {
    self.drawSeparator()
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) { fatalError("init(coder:) has not been implemented") }

  var tabs = [Tab<Entry>]()

  private var _theme: Theme
  private let scrollView = HorizontalOnlyScrollView(forAutoLayout: ())
  private let stackView = DraggingSingleRowStackView(forAutoLayout: ())
}

extension TabBar {
  func select(tab: Tab<Entry>) {
    guard let index = self.tabs.firstIndex(where: { $0 == tab }) else { return }
    self.selectHandler?(index, tab.tabRepresentative)
  }
}

extension TabBar {
  private func drawSeparator() {
    let b = self.bounds
    let rect = CGRect(x: 0, y: 0, width: b.width, height: self._theme.separatorThickness)

    guard let context = NSGraphicsContext.current?.cgContext else { return }
    context.saveGState()
    defer { context.restoreGState() }
    self._theme.separatorColor.set()

    rect.fill()
  }

  private func addViews() {
    let scroll = self.scrollView
    let stack = self.stackView

    self.addSubview(scroll)
    scroll.autoPinEdgesToSuperviewEdges()

    scroll.drawsBackground = false
    scroll.hasHorizontalScroller = false
    scroll.documentView = stack

    stack.autoPinEdge(toSuperviewEdge: .top)
    stack.autoPinEdge(toSuperviewEdge: .left)
    stack.autoPinEdge(toSuperviewEdge: .bottom)

    stack.spacing = self._theme.tabSpacing
    stack.postDraggingHandler = { stackView, draggedView in
      self.tabs = stackView.arrangedSubviews.compactMap { $0 as? Tab<Entry> }

      if let draggedTab = draggedView as? Tab<Entry>,
         let indexOfDraggedTab = self.tabs.firstIndex(where: { $0 == draggedTab })
      {
        self.reorderHandler?(indexOfDraggedTab, draggedTab.tabRepresentative)
      }

      let endIndex = stackView.arrangedSubviews.endIndex - 1
      self.tabs.enumerated().forEach { index, tab in
        tab.position = []
        if index == 0 { tab.position.insert(.first) }
        if index == endIndex { tab.position.insert(.last) }
      }
    }
  }
}
