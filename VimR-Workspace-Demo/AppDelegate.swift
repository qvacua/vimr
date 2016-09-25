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
    let workspace = Workspace(mainView: self.view(NSColor.yellow))
    self.workspace = workspace

    contentView.addSubview(workspace)
    workspace.autoPinEdgesToSuperviewEdges()
    
    workspace.append(tool: WorkspaceTool(title: "Top-1", view: self.view(NSColor.white)), location: .top)
    workspace.append(tool: WorkspaceTool(title: "Right-1", view: self.view(NSColor.white)), location: .right)
    workspace.append(tool: WorkspaceTool(title: "Right-2", view: self.view(NSColor.green)), location: .right)
    workspace.append(tool: WorkspaceTool(title: "Left-1", view: self.view(NSColor.white)), location: .left)
    workspace.append(tool: WorkspaceTool(title: "Left-2", view: self.view(NSColor.green)), location: .left)
    workspace.append(tool: WorkspaceTool(title: "Left-3", view: self.view(NSColor.magenta)), location: .left)
    workspace.append(tool: WorkspaceTool(title: "Bottom-1", view: self.view(NSColor.white)), location: .bottom)
    workspace.append(tool: WorkspaceTool(title: "Bottom-2", view: self.view(NSColor.green)), location: .bottom)
  }

  fileprivate func view(_ color: NSColor) -> NSView {
    let view = NSView(forAutoLayout: ())
    view.wantsLayer = true
    view.layer?.backgroundColor = color.cgColor
    return view
  }
}
