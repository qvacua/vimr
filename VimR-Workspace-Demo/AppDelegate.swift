/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import PureLayout

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

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
    let workspace = Workspace(mainView: DummyView(NSColor.yellow))
    self.workspace = workspace

    contentView.addSubview(workspace)
    workspace.autoPinEdgesToSuperviewEdges()

    workspace.append(tool: WorkspaceTool(title: "Top-1", view: DummyView(NSColor.white)), location: .top)
    workspace.append(tool: WorkspaceTool(title: "Right-1", view: DummyView(NSColor.white)), location: .right)
    workspace.append(tool: WorkspaceTool(title: "Right-2", view: DummyView(NSColor.green)), location: .right)
    workspace.append(tool: WorkspaceTool(title: "Left-1", view: DummyView(NSColor.white)), location: .left)
    workspace.append(tool: WorkspaceTool(title: "Left-2", view: DummyView(NSColor.green)), location: .left)
    workspace.append(tool: WorkspaceTool(title: "Left-3", view: DummyView(NSColor.magenta)), location: .left)
    workspace.append(tool: WorkspaceTool(title: "Bottom-1", view: DummyView(NSColor.white)), location: .bottom)
    workspace.append(tool: WorkspaceTool(title: "Bottom-2", view: DummyView(NSColor.green)), location: .bottom)
  }
}

class DummyView: NSView {

  init(_ color: NSColor) {
    super.init(frame: .zero)
    self.configureForAutoLayout()
    self.wantsLayer = true
    self.layer?.backgroundColor = color.cgColor
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func mouseDown(with event: NSEvent) {
    NSLog("mouse down")
  }
}
