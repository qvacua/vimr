/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import PureLayout

public protocol TabRepresentative: Hashable, Equatable {
  var title: String { get }
}

public class TabBar<Entry: TabRepresentative>: NSView {
  public var theme: Theme { self._theme }

  public init(withTheme theme: Theme) {
    self._theme = theme

    super.init(frame: .zero)
    self.configureForAutoLayout()
    self.wantsLayer = true
    self.layer?.backgroundColor = theme.backgroundColor.cgColor

    self.addViews()
  }

//  public func update(tabRepresentatives _: [Entry]) {}

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
    self.stackView.arrangedSubviews.forEach { ($0 as? Tab<Entry>)?.isSelected = false }
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
        guard let tab = view as? Tab<Entry> else { return }

        if index == 0 { tab.position = .first }
        else if index == endIndex { tab.position = .last }
        else { tab.position = .inBetween }
      }
    }
  }
}
