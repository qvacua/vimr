/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import PureLayout

public class TabBar: NSView {
  public var theme: Theme { self._theme }

  public init(withTheme theme: Theme) {
    self._theme = theme

    super.init(frame: .zero)
    self.configureForAutoLayout()
    self.wantsLayer = true
    self.layer?.backgroundColor = theme.backgroundColor.cgColor

    self.addViews()
    self.addTestTabs()
  }

  override public func draw(_: NSRect) {
    self.drawSeparator()
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) { fatalError("init(coder:) has not been implemented") }

  var tabs = [Tab]()

  private var _theme: Theme
  private let scrollView = HorizontalOnlyScrollView(forAutoLayout: ())
  private let stackView = DraggingSingleRowStackView(forAutoLayout: ())
}

extension TabBar: TabDelegate {
  func select(tab: Tab) {
    self.stackView.arrangedSubviews.forEach { ($0 as? Tab)?.isSelected = false }
    tab.isSelected = true
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
    stack.postDraggingAction = { stackView in
      let endIndex = stackView.arrangedSubviews.endIndex - 1
      stackView.arrangedSubviews.enumerated().forEach { index, view in
        guard let tab = view as? Tab else { return }

        if index == 0 { tab.position = .first }
        else if index == endIndex { tab.position = .last }
        else { tab.position = .inBetween }
      }
    }
  }

  private func addTestTabs() {
    let tab1 = Tab(withTitle: "Test 1", in: self)
    let tab2 = Tab(withTitle: "Test 2 Some", in: self)
    let tab3 = Tab(withTitle: "Test 3", in: self)
    let tab4 = Tab(
      withTitle: "Test 4 More Text More Less Really??? More Text How long should it be?",
      in: self
    )

    tab1.delegate = self
    tab2.delegate = self
    tab3.delegate = self
    tab4.delegate = self

    tab1.position = .first
    tab4.position = .last
    tab2.isSelected = true

    self.stackView.addArrangedSubview(tab1)
    self.stackView.addArrangedSubview(tab2)
    self.stackView.addArrangedSubview(tab3)
    self.stackView.addArrangedSubview(tab4)
  }
}
