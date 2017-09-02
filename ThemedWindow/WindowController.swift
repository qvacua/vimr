import Cocoa
import PureLayout

class WindowController: NSWindowController, NSWindowDelegate {

  fileprivate var titlebarThemed = false
  fileprivate var repIcon: NSButton?
  fileprivate let root = ColorView(bg: .green)

  @IBAction func themeTitlebar(_: Any?) {
    guard let window = self.window else {
      return
    }

    if window.styleMask.contains(.fullScreen) {
      return
    }

    self.repIcon?.removeFromSuperview()
    self.root.removeFromSuperview()

    window.titleVisibility = .visible
    window.representedURL = URL(fileURLWithPath: "/Users/hat/greek.tex")

    guard let button = window.standardWindowButton(.documentIconButton) else {
      NSLog("No button!")
      return
    }

    guard let contentView = window.contentView else {
      return
    }

    self.repIcon = button

    window.titleVisibility = .hidden
    window.styleMask.insert(.fullSizeContentView)

    contentView.addSubview(button)
    button.autoPinEdge(toSuperviewEdge: .right, withInset: 24)
    button.autoPinEdge(toSuperviewEdge: .top, withInset: 3)
    button.autoSetDimension(.width, toSize: 16)
    button.autoSetDimension(.height, toSize: 16)

    contentView.addSubview(self.root)
    self.root.autoPinEdge(toSuperviewEdge: .top, withInset: 22)
    self.root.autoPinEdge(toSuperviewEdge: .right)
    self.root.autoPinEdge(toSuperviewEdge: .bottom)
    self.root.autoPinEdge(toSuperviewEdge: .left)

    self.titlebarThemed = true
  }

  @IBAction func unthemeTitlebar(_: Any?) {
    self.unthemeTitlebar(dueFullScreen: false)
  }

  fileprivate func unthemeTitlebar(dueFullScreen: Bool) {
    self.repIcon?.removeFromSuperview()
    self.repIcon = nil

    self.root.removeFromSuperview()

    guard let window = self.window else {
      return
    }

    window.titleVisibility = .visible
    window.styleMask.remove(.fullSizeContentView)
    window.representedURL = URL(fileURLWithPath: "/Users/hat/big.txt")

    guard let contentView = window.contentView else {
      return
    }

    contentView.addSubview(self.root)
    self.root.autoPinEdgesToSuperviewEdges()

    if !dueFullScreen {
      self.titlebarThemed = false
    }
  }

  func windowWillEnterFullScreen(_: Notification) {
    self.unthemeTitlebar(dueFullScreen: true)
  }

  func windowDidExitFullScreen(_: Notification) {
    if self.titlebarThemed {
      self.themeTitlebar(nil)
    }
  }

  override func windowDidLoad() {
    super.windowDidLoad()

    guard let window = self.window else {
      return
    }

    window.delegate = self
    window.backgroundColor = .yellow
    window.titlebarAppearsTransparent = true

    guard let contentView = window.contentView else {
      return
    }

    contentView.addSubview(self.root)
    self.root.autoPinEdgesToSuperviewEdges()
  }
}

class ColorView: NSView {

  fileprivate let color: NSColor

  init(bg: NSColor) {
    self.color = bg

    super.init(frame: .zero)
    self.configureForAutoLayout()

    self.wantsLayer = true
    self.layer?.backgroundColor = bg.cgColor
  }

  override func draw(_ dirtyRect: NSRect) {
    super.draw(dirtyRect)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

