/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import PureLayout

protocol WorkspaceToolDelegate: class {

  func toggle(_ tool: WorkspaceTool)
}

class WorkspaceTool: NSView {

  private var innerToolbar: InnerToolBar?

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  static func ==(left: WorkspaceTool, right: WorkspaceTool) -> Bool {
    return left.uuid == right.uuid
  }

  // MARK: - API
  override var hashValue: Int {
    return self.uuid.hashValue
  }
  /**
   This UUID is only memory-persistent. It's generated when the tool is instantiated.
   */
  let uuid = UUID().uuidString
  let title: String
  let view: NSView
  let button: WorkspaceToolButton
  var location = WorkspaceBarLocation.left {
    didSet {
      self.button.location = self.location
    }
  }

  var isSelected = false {
    didSet {
      if self.isSelected {
        self.button.highlight()
      } else {
        self.button.dehighlight()
      }
    }
  }

  var theme: Workspace.Theme {
    return self.bar?.theme ?? Workspace.Theme.default
  }

  weak var delegate: WorkspaceToolDelegate?
  weak var bar: WorkspaceBar?

  var workspace: Workspace? {
    return self.bar?.workspace
  }

  let minimumDimension: CGFloat
  var dimension: CGFloat

  var customInnerToolbar: CustomToolBar? {
    get {
      return self.innerToolbar?.customToolbar
    }

    set {
      DispatchQueue.main.async {
        self.innerToolbar?.customToolbar = newValue
      }
    }
  }
  var customInnerMenuItems: [NSMenuItem]? {
    get {
      return self.innerToolbar?.customMenuItems
    }

    set {
      self.innerToolbar?.customMenuItems = newValue
    }
  }

  struct Config {

    let title: String
    let view: NSView
    let minimumDimension: CGFloat

    let isWithInnerToolbar: Bool

    let customToolbar: CustomToolBar?
    let customMenuItems: [NSMenuItem]

    init(title: String,
         view: NSView,
         minimumDimension: CGFloat = 50,
         withInnerToolbar: Bool = true,
         customToolbar: CustomToolBar? = nil,
         customMenuItems: [NSMenuItem] = []) {
      self.title = title
      self.view = view
      self.minimumDimension = minimumDimension

      self.isWithInnerToolbar = withInnerToolbar

      self.customToolbar = customToolbar
      self.customMenuItems = customMenuItems
    }
  }

  init(_ config: Config) {
    self.title = config.title
    self.view = config.view
    self.minimumDimension = config.minimumDimension
    self.dimension = minimumDimension

    self.button = WorkspaceToolButton(title: title)

    super.init(frame: .zero)
    self.configureForAutoLayout()

    self.button.tool = self
    if config.isWithInnerToolbar {
      self.innerToolbar = InnerToolBar(customToolbar: config.customToolbar, customMenuItems: config.customMenuItems)
      self.innerToolbar?.tool = self
    }

    self.addViews()
  }

  func toggle() {
    self.isSelected = !self.isSelected
    self.delegate?.toggle(self)
  }

  func repaint() {
    self.button.repaint()
    self.innerToolbar?.repaint()

    self.needsDisplay = true
  }

  private func addViews() {
    let view = self.view
    self.addSubview(view)

    if let innerToolbar = self.innerToolbar {
      self.addSubview(innerToolbar)

      innerToolbar.autoPinEdge(toSuperviewEdge: .top)
      innerToolbar.autoPinEdge(toSuperviewEdge: .right)
      innerToolbar.autoPinEdge(toSuperviewEdge: .left)

      view.autoPinEdge(.top, to: .bottom, of: innerToolbar)
      view.autoPinEdge(toSuperviewEdge: .right)
      view.autoPinEdge(toSuperviewEdge: .bottom)
      view.autoPinEdge(toSuperviewEdge: .left)

      return
    }

    view.autoPinEdgesToSuperviewEdges()
  }
}
