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

  static let all = [ top, right, bottom, left ]
}

protocol WorkspaceDelegate: class {

  func resizeWillStart(workspace: Workspace)
  func resizeDidEnd(workspace: Workspace)
}

class Workspace: NSView, WorkspaceBarDelegate {

  struct Config {
    let mainViewMinimumSize: CGSize
  }

  fileprivate(set) var isAllToolsVisible = true {
    didSet {
      self.relayout()
    }
  }
  fileprivate(set) var isToolButtonsVisible = true {
    didSet {
      self.bars.values.forEach { $0.isButtonVisible = !$0.isButtonVisible }
    }
  }

  fileprivate var tools = [WorkspaceTool]()

  fileprivate var isDragOngoing = false
  fileprivate var draggedOnBarLocation: WorkspaceBarLocation?
  fileprivate let proxyBar = ProxyWorkspaceBar(forAutoLayout: ())

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
    self.configureForAutoLayout()

    self.register(forDraggedTypes: [WorkspaceToolButton.toolUti])
    self.bars.values.forEach { [unowned self] in $0.delegate = self }

    self.relayout()
  }

  func append(tool: WorkspaceTool, location: WorkspaceBarLocation) {
    if self.tools.contains(tool) {
      return
    }

    self.tools.append(tool)
    self.bars[location]?.append(tool: tool)
  }

  func toggleAllTools() {
    self.isAllToolsVisible = !self.isAllToolsVisible
  }

  func toggleToolButtons() {
    self.isToolButtonsVisible = !self.isToolButtonsVisible
  }
}

// MARK: - NSDraggingDestination
extension Workspace {

  override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
    self.isDragOngoing = true
    return .move
  }

  override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
    let loc = self.convert(sender.draggingLocation(), from: nil)
    let currentBarLoc = self.barLocation(inPoint: loc)

    if currentBarLoc == self.draggedOnBarLocation {
      return .move
    }

    self.draggedOnBarLocation = currentBarLoc
    self.relayout()
    return .move
  }

  override func draggingExited(_ sender: NSDraggingInfo?) {
    self.endDrag()
  }

  override func draggingEnded(_ sender: NSDraggingInfo?) {
    self.endDrag()
  }

  fileprivate func endDrag() {
    self.isDragOngoing = false
    self.draggedOnBarLocation = nil
    self.proxyBar.removeFromSuperview()
    self.proxyBar.removeAllConstraints()
  }

  override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
    let loc = self.convert(sender.draggingLocation(), from: nil)
    guard let barLoc = self.barLocation(inPoint: loc) else {
      return false
    }

    guard let toolButton = sender.draggingSource() as? WorkspaceToolButton else {
      return false
    }

    guard let tool = toolButton.tool else {
      return false
    }

    tool.bar?.remove(tool: tool)
    self.bars[barLoc]?.append(tool: tool)

    return true
  }

  fileprivate func barLocation(inPoint loc: CGPoint) -> WorkspaceBarLocation? {
    for barLoc in WorkspaceBarLocation.all {
      if rect(forBar: barLoc).contains(loc) {
        return barLoc
      }
    }

    return nil
  }

  // We copy and pasted WorkspaceBar.barFrame() since we need the rect for the proxy bars.
  fileprivate func rect(forBar location: WorkspaceBarLocation) -> CGRect {
    let size = self.bounds.size
    let dimension = self.bars[location]!.dimensionWithoutTool()

    switch location {
    case .top:
      return CGRect(x: 0, y: size.height - dimension, width: size.width, height: dimension)
    case .right:
      return CGRect(x: size.width - dimension, y: 0, width: dimension, height: size.height)
    case .bottom:
      return CGRect(x: 0, y: 0, width: size.width, height: dimension)
    case .left:
      return CGRect(x: 0, y: 0, width: dimension, height: size.height)
    }
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

    guard self.isAllToolsVisible else {
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

    if let barLoc = self.draggedOnBarLocation {
      let proxyBar = self.proxyBar
      self.addSubview(proxyBar)

      let barRect = self.rect(forBar: barLoc)
      switch barLoc {

      case .top:
        proxyBar.autoPinEdge(toSuperviewEdge: .top)
        proxyBar.autoPinEdge(toSuperviewEdge: .right)
        proxyBar.autoPinEdge(toSuperviewEdge: .left)
        proxyBar.autoSetDimension(.height, toSize: barRect.height)

      case .right:
        proxyBar.autoPinEdge(.top, to: .bottom, of: topBar)
        proxyBar.autoPinEdge(toSuperviewEdge: .right)
        proxyBar.autoPinEdge(.bottom, to: .top, of: bottomBar)
        proxyBar.autoSetDimension(.width, toSize: barRect.width)

      case .bottom:
        proxyBar.autoPinEdge(toSuperviewEdge: .right)
        proxyBar.autoPinEdge(toSuperviewEdge: .bottom)
        proxyBar.autoPinEdge(toSuperviewEdge: .left)
        proxyBar.autoSetDimension(.height, toSize: barRect.height)

      case .left:
        proxyBar.autoPinEdge(.top, to: .bottom, of: topBar)
        proxyBar.autoPinEdge(toSuperviewEdge: .left)
        proxyBar.autoPinEdge(.bottom, to: .top, of: bottomBar)
        proxyBar.autoSetDimension(.width, toSize: barRect.width)

      }
    }

    self.needsDisplay = true
  }
}
