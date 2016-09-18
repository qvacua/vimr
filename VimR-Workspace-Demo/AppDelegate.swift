/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import PureLayout

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

  @IBOutlet weak var window: NSWindow!

  private var workspace: Workspace = Workspace(mainView: NSView())

  @IBAction func toggleBars(sender: AnyObject!) {
    workspace.toggleAllTools()
  }

  @IBAction func toggleButtons(sender: AnyObject!) {
    workspace.toggleToolButtons()
  }

  func applicationDidFinishLaunching(aNotification: NSNotification) {
    let contentView = self.window.contentView!
    let workspace = Workspace(mainView: self.view(NSColor.yellowColor()))
    self.workspace = workspace

    contentView.addSubview(workspace)
    workspace.autoPinEdgesToSuperviewEdges()
    
    workspace.append(tool: WorkspaceTool(title: "Top-1", view: self.view(NSColor.whiteColor())), location: .top)
    workspace.append(tool: WorkspaceTool(title: "Right-1", view: self.view(NSColor.whiteColor())), location: .right)
    workspace.append(tool: WorkspaceTool(title: "Right-2", view: self.view(NSColor.greenColor())), location: .right)
    workspace.append(tool: WorkspaceTool(title: "Left-1", view: self.view(NSColor.whiteColor())), location: .left)
    workspace.append(tool: WorkspaceTool(title: "Left-2", view: self.view(NSColor.greenColor())), location: .left)
    workspace.append(tool: WorkspaceTool(title: "Left-3", view: self.view(NSColor.magentaColor())), location: .left)
    workspace.append(tool: WorkspaceTool(title: "Bottom-1", view: self.view(NSColor.whiteColor())), location: .bottom)
    workspace.append(tool: WorkspaceTool(title: "Bottom-2", view: self.view(NSColor.greenColor())), location: .bottom)
  }

  private func view(color: NSColor) -> NSView {
    let view = NSView(forAutoLayout: ())
    view.wantsLayer = true
    view.layer?.backgroundColor = color.CGColor
    return view
  }
}
