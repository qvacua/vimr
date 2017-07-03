/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import PureLayout

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, WorkspaceDelegate {

  @IBOutlet weak var window: NSWindow!

  fileprivate var workspace: Workspace = Workspace(mainView: NSView())

  @IBAction func toggleBars(_ sender: AnyObject!) {
    workspace.toggleAllTools()
  }

  @IBAction func toggleButtons(_ sender: AnyObject!) {
    workspace.toggleToolButtons()
  }

  func applicationDidFinishLaunching(_ aNotification: Notification) {
    let contentView = self.window.contentView!
    let workspace = Workspace(mainView: DummyView(NSColor.white))
    self.workspace = workspace

    contentView.addSubview(workspace)
    workspace.autoPinEdgesToSuperviewEdges()

//    workspace.append(tool: dummyTool(title: "Top-1", color: .yellow), location: .top)

    workspace.append(tool: dummyTool(title: "Right-1", color: .magenta), location: .right)
    workspace.append(tool: dummyTool(title: "Right-2", color: .black), location: .right)

    let menuItems = [
      NSMenuItem(title: "First", action: nil, keyEquivalent: ""),
      NSMenuItem(title: "Second", action: nil, keyEquivalent: ""),
      NSMenuItem(title: "Third", action: nil, keyEquivalent: ""),
      NSMenuItem(title: "Fourth", action: nil, keyEquivalent: ""),
      NSMenuItem(title: "Fifth", action: nil, keyEquivalent: ""),
    ]

    let tool = dummyTool(title: "Left-1", color: .blue, customToolbar: DummyView(.orange), customMenu: menuItems)

    workspace.append(tool: tool, location: .left)
    workspace.append(tool: dummyTool(title: "Left-2", color: .red), location: .left)
    workspace.append(tool: dummyTool(title: "Left-3", color: .gray), location: .left)

    workspace.append(tool: dummyTool(title: "Bottom-1", color: .cyan), location: .bottom)
    workspace.append(tool: dummyTool(title: "Bottom-2", color: .blue), location: .bottom)

    tool.toggle()

    // FIXME: GH-422
    workspace.delegate = self
  }

  fileprivate func dummyTool(title: String,
                             color: NSColor,
                             customToolbar: CustomToolBar? = nil,
                             customMenu: [NSMenuItem] = []) -> WorkspaceTool
  {
    let config = WorkspaceTool.Config(title: title,
                                      view: DummyView(color),
                                      minimumDimension: 150,
                                      withInnerToolbar: true,
                                      customToolbar: customToolbar,
                                      customMenuItems: customMenu)

    return WorkspaceTool(config)
  }

  func resizeWillStart(workspace: Workspace, tool: WorkspaceTool?) {
    NSLog("\(#function)")
  }

  func resizeDidEnd(workspace: Workspace, tool: WorkspaceTool?) {
    NSLog("\(#function)")
  }

  func toggled(tool: WorkspaceTool) {
    NSLog("\(#function)")
  }

  func moved(tool: WorkspaceTool) {
    NSLog("\(#function)")
  }
}

class DummyView: CustomToolBar {

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  init(_ color: NSColor) {
    super.init(frame: .zero)
    self.configureForAutoLayout()
    self.wantsLayer = true
    self.layer?.backgroundColor = color.cgColor
  }

  override func mouseDown(with event: NSEvent) {
    NSLog("mouse down")
  }
}
