/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import PureLayout

enum WorkspaceBarLocation {
  case top
  case right
  case bottom
  case left
}

class Workspace: NSView {

  var mainView: NSView
  private(set) var isBarVisible = true {
    didSet {
      self.needsDisplay = true
    }
  }

  private let bars: [WorkspaceBarLocation: WorkspaceBar]

  init(mainView: NSView) {
    self.mainView = mainView
    self.bars = [
      .top: WorkspaceBar(location: .top),
      .right: WorkspaceBar(location: .right),
      .bottom: WorkspaceBar(location: .bottom),
      .left: WorkspaceBar(location: .left)
    ]

    super.init(frame: CGRect.zero)
    self.translatesAutoresizingMaskIntoConstraints = false

    self.relayout()
  }

  private func relayout() {
    // FIXME: I did not investigate why toggleButtons does not work correctly if we store all constraints in an array
    // and remove them here by self.removeConstraints(${all constraints). The following seems to work...
    self.subviews.forEach { $0.removeAllConstraints() }
    self.removeAllSubviews()

    let mainView = self.mainView
    self.addSubview(mainView)

    guard self.isBarVisible else {
      mainView.autoPinEdgesToSuperviewEdges()
      return
    }

    let topBar = self.bars[.top]!
    let rightBar = self.bars[.right]!
    let bottomBar = self.bars[.bottom]!
    let leftBar = self.bars[.left]!

    self.addSubview(topBar)
    self.addSubview(rightBar)
    self.addSubview(bottomBar)
    self.addSubview(leftBar)

      topBar.autoPinEdgeToSuperviewEdge(.Top)
      topBar.autoPinEdgeToSuperviewEdge(.Right)
      topBar.autoPinEdgeToSuperviewEdge(.Left)

      rightBar.autoPinEdge(.Top, toEdge: .Bottom, ofView: topBar)
      rightBar.autoPinEdgeToSuperviewEdge(.Right)
      rightBar.autoPinEdge(.Bottom, toEdge: .Top, ofView: bottomBar)

      bottomBar.autoPinEdgeToSuperviewEdge(.Right)
      bottomBar.autoPinEdgeToSuperviewEdge(.Bottom)
      bottomBar.autoPinEdgeToSuperviewEdge(.Left)

      leftBar.autoPinEdge(.Top, toEdge: .Bottom, ofView: topBar)
      leftBar.autoPinEdgeToSuperviewEdge(.Left)
      leftBar.autoPinEdge(.Bottom, toEdge: .Top, ofView: bottomBar)

    NSLayoutConstraint.autoSetPriority(NSLayoutPriorityDragThatCannotResizeWindow) {
      topBar.dimensionConstraint = topBar.autoSetDimension(.Height, toSize: 50)
      rightBar.dimensionConstraint = rightBar.autoSetDimension(.Width, toSize: 50)
      bottomBar.dimensionConstraint = bottomBar.autoSetDimension(.Height, toSize: 50)
      leftBar.dimensionConstraint = leftBar.autoSetDimension(.Width, toSize: 50)
    }

    self.bars.values.forEach { $0.relayout() }

    mainView.autoPinEdge(.Top, toEdge: .Bottom, ofView: topBar)
    mainView.autoPinEdge(.Right, toEdge: .Left, ofView: rightBar)
    mainView.autoPinEdge(.Bottom, toEdge: .Top, ofView: bottomBar)
    mainView.autoPinEdge(.Left, toEdge: .Right, ofView: leftBar)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

// MARK: - API
extension Workspace {

  func append(tool tool: WorkspaceTool, location: WorkspaceBarLocation) {
    self.bars[location]?.append(tool: tool)
  }

  func toggleAllTools() {
    self.isBarVisible = !self.isBarVisible
    self.relayout()
  }

  func toggleToolButtons() {
    self.bars.values.forEach { $0.isButtonVisible = !$0.isButtonVisible }
  }
}
