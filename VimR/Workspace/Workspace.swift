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

protocol WorkspaceDelegate: class {

  func resizeWillStart(workspace: Workspace)
  func resizeDidEnd(workspace: Workspace)
}

class Workspace: NSView, WorkspaceBarDelegate {

  struct Config {
    let mainViewMinimumSize: CGSize
  }

  fileprivate(set) var isBarVisible = true {
    didSet {
      self.relayout()
    }
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - API
  let mainView: NSView
  let bars: [WorkspaceBarLocation: WorkspaceBar]
  let config: Config

  weak var delegate: WorkspaceDelegate?

  init(mainView: NSView, config: Config = Config(mainViewMinimumSize: CGSize(width: 100, height: 100))) {
    self.config = config
    self.mainView = mainView

    self.bars = [
      .top: WorkspaceBar(location: .top),
      .right: WorkspaceBar(location: .right),
      .bottom: WorkspaceBar(location: .bottom),
      .left: WorkspaceBar(location: .left)
    ]

    super.init(frame: CGRect.zero)
    self.translatesAutoresizingMaskIntoConstraints = false

    self.bars.values.forEach { [unowned self] in $0.delegate = self }

    self.relayout()
  }

  func append(tool: WorkspaceTool, location: WorkspaceBarLocation) {
    self.bars[location]?.append(tool: tool)
  }

  func toggleAllTools() {
    self.isBarVisible = !self.isBarVisible
  }

  func toggleToolButtons() {
    self.bars.values.forEach { $0.isButtonVisible = !$0.isButtonVisible }
  }
}

// MARK: - WorkspaceBarDelegate
extension Workspace {

  func resizeWillStart(workspaceBar: WorkspaceBar) {
    self.delegate?.resizeWillStart(workspace: self)
  }

  func resizeDidEnd(workspaceBar: WorkspaceBar) {
    self.delegate?.resizeDidEnd(workspace: self)
  }
}

// MARK: - Layout
extension Workspace {

  fileprivate func relayout() {
    // FIXME: I did not investigate why toggleButtons does not work correctly if we store all constraints in an array
    // and remove them here by self.removeConstraints(${all constraints). The following seems to work...
    self.subviews.forEach { $0.removeAllConstraints() }
    self.removeAllSubviews()

    let mainView = self.mainView
    self.addSubview(mainView)

    mainView.autoSetDimension(.width, toSize: self.config.mainViewMinimumSize.width, relation: .greaterThanOrEqual)
    mainView.autoSetDimension(.height, toSize: self.config.mainViewMinimumSize.height, relation: .greaterThanOrEqual)

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

    topBar.autoPinEdge(toSuperviewEdge: .top)
    topBar.autoPinEdge(toSuperviewEdge: .right)
    topBar.autoPinEdge(toSuperviewEdge: .left)

    rightBar.autoPinEdge(.top, to: .bottom, of: topBar)
    rightBar.autoPinEdge(toSuperviewEdge: .right)
    rightBar.autoPinEdge(.bottom, to: .top, of: bottomBar)

    bottomBar.autoPinEdge(toSuperviewEdge: .right)
    bottomBar.autoPinEdge(toSuperviewEdge: .bottom)
    bottomBar.autoPinEdge(toSuperviewEdge: .left)

    leftBar.autoPinEdge(.top, to: .bottom, of: topBar)
    leftBar.autoPinEdge(toSuperviewEdge: .left)
    leftBar.autoPinEdge(.bottom, to: .top, of: bottomBar)

    NSLayoutConstraint.autoSetPriority(NSLayoutPriorityDragThatCannotResizeWindow) {
      topBar.dimensionConstraint = topBar.autoSetDimension(.height, toSize: 50)
      rightBar.dimensionConstraint = rightBar.autoSetDimension(.width, toSize: 50)
      bottomBar.dimensionConstraint = bottomBar.autoSetDimension(.height, toSize: 50)
      leftBar.dimensionConstraint = leftBar.autoSetDimension(.width, toSize: 50)
    }

    self.bars.values.forEach { $0.relayout() }

    mainView.autoPinEdge(.top, to: .bottom, of: topBar)
    mainView.autoPinEdge(.right, to: .left, of: rightBar)
    mainView.autoPinEdge(.bottom, to: .top, of: bottomBar)
    mainView.autoPinEdge(.left, to: .right, of: leftBar)
    
    self.needsDisplay = true
  }
}
