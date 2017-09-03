import Cocoa
import PureLayout

fileprivate let gap = CGFloat(4.0)

class WindowController: NSWindowController, NSWindowDelegate {

  func windowWillEnterFullScreen(_: Notification) {
    self.unthemeTitlebar(dueFullScreen: true)
  }

  func windowDidExitFullScreen(_: Notification) {
    if self.titlebarThemed {
      self.themeTitlebar(grow: true)
    }
  }

  fileprivate var titlebarThemed = false
  fileprivate var repIcon: NSButton?
  fileprivate var titleView: NSTextField?

  fileprivate func themeTitlebar(grow: Bool) {
    guard let window = self.window else {
      return
    }

    if window.styleMask.contains(.fullScreen) {
      return
    }

    window.titlebarAppearsTransparent = true

    self.root.removeFromSuperview()

    self.set(repUrl: window.representedURL, themed: true, grow: grow)

    window.contentView?.addSubview(self.root)
    self.root.autoPinEdge(toSuperviewEdge: .top, withInset: 22)
    self.root.autoPinEdge(toSuperviewEdge: .right)
    self.root.autoPinEdge(toSuperviewEdge: .bottom)
    self.root.autoPinEdge(toSuperviewEdge: .left)

    self.titlebarThemed = true
  }

  fileprivate func unthemeTitlebar(dueFullScreen: Bool) {
    self.clearCustomTitle()

    guard let window = self.window, let contentView = window.contentView else {
      return
    }

    let prevFrame = window.frame

    window.titlebarAppearsTransparent = false

    self.root.removeFromSuperview()

    window.titleVisibility = .visible
    window.styleMask.remove(.fullSizeContentView)

    self.set(repUrl: window.representedURL, themed: false, grow: false)

    contentView.addSubview(self.root)
    self.root.autoPinEdgesToSuperviewEdges()

    if !dueFullScreen {
      if self.titlebarThemed {
        self.growWindow(by: -22)
        let dy = prevFrame.origin.y - window.frame.origin.y
        if dy != 0 {
          window.setFrame(window.frame.offsetBy(dx: 0, dy: dy), display: true, animate: false)
        }
      }

      self.titlebarThemed = false
    }
  }


  fileprivate func clearCustomTitle() {
    self.titleView?.removeFromSuperview()
    self.repIcon?.removeFromSuperview()

    self.titleView = nil
    self.repIcon = nil
  }

  fileprivate func internalSetRepUrl(_ url: URL?) {
    self.window?.representedURL = nil
    self.window?.representedURL = url
    self.window?.title = url?.lastPathComponent ?? "Title"
  }

  fileprivate func set(repUrl url: URL?, themed: Bool, grow: Bool) {
    guard let window = self.window else {
      return
    }

    if window.styleMask.contains(.fullScreen) || themed == false {
      self.internalSetRepUrl(url)
      return
    }

    self.clearCustomTitle()

    window.titleVisibility = .visible
    self.internalSetRepUrl(url)

    guard let contentView = window.contentView else {
      return
    }

    window.titleVisibility = .hidden
    window.styleMask.insert(.fullSizeContentView)

    if grow {
      self.growWindow(by: 22)
    }

    let title = NSTextField(labelWithString: window.title)
    title.configureForAutoLayout()
    contentView.addSubview(title)
    title.autoPinEdge(toSuperviewEdge: .top, withInset: 2)

    self.titleView = title

    if let button = window.standardWindowButton(.documentIconButton) {
      button.removeFromSuperview() // remove the rep icon from the original superview and add it to content view
      contentView.addSubview(button)
      button.autoSetDimension(.width, toSize: 16)
      button.autoSetDimension(.height, toSize: 16)
      button.autoPinEdge(toSuperviewEdge: .top, withInset: 3)

      // Center the rep icon and the title side by side in the content view:
      // rightView.left = leftView.right + gap
      // rightView.right = parentView.centerX + (leftView.width + gap + rightView.width) / 2 - 4
      // The (-4) at the end is an empirical value...
      contentView.addConstraint(NSLayoutConstraint(item: title, attribute: .left,
                                                   relatedBy: .equal,
                                                   toItem: button, attribute: .right,
                                                   multiplier: 1,
                                                   constant: gap))
      contentView.addConstraint(NSLayoutConstraint(item: title, attribute: .right,
                                                   relatedBy: .equal,
                                                   toItem: contentView, attribute: .centerX,
                                                   multiplier: 1,
                                                   constant: -4 + (button.frame.width + gap + title.frame.width) / 2))

      self.repIcon = button
    } else {
      title.autoAlignAxis(toSuperviewAxis: .vertical)
    }
  }

  fileprivate func growWindow(by dy: CGFloat) {
    guard let window = self.window else {
      return
    }

    let frame = window.frame
    window.setFrame(
      CGRect(origin: frame.origin, size: CGSize(width: frame.width, height: frame.height + dy)),
      display: true,
      animate: false
    )
  }

  // ====== >8 ======

  fileprivate let root = ColorView(bg: .green)

  override func windowDidLoad() {
    super.windowDidLoad()

    guard let window = self.window else {
      return
    }

    window.delegate = self
    window.backgroundColor = .yellow

    guard let contentView = window.contentView else {
      return
    }

    contentView.addSubview(self.root)
    self.root.autoPinEdgesToSuperviewEdges()
  }

  @IBAction func setRepUrl1(_: Any?) {
    self.set(repUrl: URL(fileURLWithPath: "/Users/hat/big.txt"), themed: self.titlebarThemed, grow: !self.titlebarThemed)
  }

  @IBAction func setRepUrl2(_: Any?) {
    self.set(repUrl: URL(fileURLWithPath: "/Users/hat/greek.tex"), themed: self.titlebarThemed, grow: !self.titlebarThemed)
  }

  @IBAction func themeTitlebar(_: Any?) {
    self.themeTitlebar(grow: !self.titlebarThemed)
  }

  @IBAction func unthemeTitlebar(_: Any?) {
    self.unthemeTitlebar(dueFullScreen: false)
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

