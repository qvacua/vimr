/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import PureLayout

protocol WorkspaceToolDelegate: class {

  func toggle(_ tool: WorkspaceTool)
}

public class WorkspaceTool: NSView {

  public var dimension: CGFloat

  // MARK: - Public
  override public var hash: Int { self.uuid.hashValue }

  /**
   This UUID is only memory-persistent. It's generated when the tool is instantiated.
   */
  public let uuid = UUID().uuidString
  public let title: String
  public let view: NSView
  public let button: WorkspaceToolButton
  public var location = WorkspaceBarLocation.left {
    didSet {
      self.button.location = self.location
    }
  }

  public var isSelected = false {
    didSet {
      if self.isSelected {
        self.button.highlight()
      } else {
        self.button.dehighlight()
      }
    }
  }

  public struct Config {

    let title: String
    let view: NSView
    let minimumDimension: CGFloat

    let isWithInnerToolbar: Bool

    let customToolbar: CustomToolBar?
    let customMenuItems: [NSMenuItem]

    public init(title: String,
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

  public init(_ config: Config) {
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

  public func toggle() {
    self.isSelected = !self.isSelected
    self.delegate?.toggle(self)
  }

  // MARK: - Internal and private
  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  private var innerToolbar: InnerToolBar?

  static func ==(left: WorkspaceTool, right: WorkspaceTool) -> Bool {
    return left.uuid == right.uuid
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
