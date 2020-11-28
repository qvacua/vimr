/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import PureLayout

public class TabBar: NSView {
  public private(set) var tabs = [Tab]()
  
  public init() {
    super.init(frame: .zero)
    self.configureForAutoLayout()
    self.wantsLayer = true

    #if DEBUG
      self.layer?.backgroundColor = NSColor.yellow.cgColor
    #endif

    self.addViews()
    self.addTestTabs()
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) { fatalError("init(coder:) has not been implemented") }

  private let scrollView = HorizontalOnlyScrollView(forAutoLayout: ())
  private let stackView = DraggingSingleRowStackView(forAutoLayout: ())

  private func addViews() {
    #if DEBUG
      self.scrollView.backgroundColor = .brown
    #endif

    self.scrollView.hasHorizontalScroller = false
    
    self.addSubview(self.scrollView)
    self.scrollView.autoPinEdgesToSuperviewEdges()
    
    self.scrollView.documentView = self.stackView
    
    self.stackView.autoPinEdge(toSuperviewEdge: .top)
    self.stackView.autoPinEdge(toSuperviewEdge: .left)
    self.stackView.autoPinEdge(toSuperviewEdge: .bottom)
    
    self.stackView.spacing = Defs.tabPadding
  }

  private func addTestTabs() {
    let tab1 = Tab(withTitle: "Test 1")
    let tab2 = Tab(withTitle: "Test 2")
    let tab3 = Tab(withTitle: "Test 3")
    let tab4 = Tab(withTitle: "Test 4")
    
    tab1.layer?.backgroundColor = NSColor.red.cgColor
    tab2.layer?.backgroundColor = NSColor.blue.cgColor
    tab3.layer?.backgroundColor = NSColor.green.cgColor
    tab4.layer?.backgroundColor = NSColor.white.cgColor
    
    self.stackView.addArrangedSubview(tab1)
    self.stackView.addArrangedSubview(tab2)
    self.stackView.addArrangedSubview(tab3)
    self.stackView.addArrangedSubview(tab4)
  }
}
