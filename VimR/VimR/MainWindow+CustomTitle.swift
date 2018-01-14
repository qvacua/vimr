/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import PureLayout

// MARK: - Custom title
extension MainWindow {

  func themeTitlebar(grow: Bool) {
    if self.window.styleMask.contains(.fullScreen) {
      return
    }

    let prevFirstResponder = self.window.firstResponder

    self.window.titlebarAppearsTransparent = true

    self.workspace.removeFromSuperview()

    self.set(repUrl: self.window.representedURL, themed: true)

    self.window.contentView?.addSubview(self.workspace)
    self.workspace.autoPinEdge(toSuperviewEdge: .top, withInset: 22)
    self.workspace.autoPinEdge(toSuperviewEdge: .right)
    self.workspace.autoPinEdge(toSuperviewEdge: .bottom)
    self.workspace.autoPinEdge(toSuperviewEdge: .left)

    self.titlebarThemed = true

    self.window.makeFirstResponder(prevFirstResponder)
  }

  func unthemeTitlebar(dueFullScreen: Bool) {
    // NSWindow becomes the first responder at the end of this method.
    let firstResponder = self.window.firstResponder

    self.clearCustomTitle()

    guard let contentView = self.window.contentView else {
      return
    }

    let prevFrame = window.frame

    self.window.titlebarAppearsTransparent = false

    self.workspace.removeFromSuperview()

    self.window.titleVisibility = .visible
    self.window.styleMask.remove(.fullSizeContentView)

    self.set(repUrl: self.window.representedURL, themed: false)

    contentView.addSubview(self.workspace)
    self.workspace.autoPinEdgesToSuperviewEdges()

    if !dueFullScreen {
      self.window.setFrame(prevFrame, display: true, animate: false)
      self.titlebarThemed = false
    }

    self.window.makeFirstResponder(firstResponder)
  }

  func set(repUrl url: URL?, themed: Bool) {
    if self.window.styleMask.contains(NSWindow.StyleMask.fullScreen) || themed == false {
      self.internalSetRepUrl(url)
      return
    }

    let prevFirstResponder = self.window.firstResponder
    let prevFrame = self.window.frame

    self.clearCustomTitle()

    self.window.titleVisibility = .visible
    self.internalSetRepUrl(url)

    guard let contentView = self.window.contentView else {
      return
    }

    self.window.titleVisibility = .hidden
    self.window.styleMask.insert(.fullSizeContentView)

    let title = NSTextField(forAutoLayout: ())
    title.isEditable = false
    title.isSelectable = false
    title.isBordered = false
    title.isBezeled = false
    title.backgroundColor = .clear
    title.textColor = self.theme.foreground
    title.stringValue = self.window.title
    contentView.addSubview(title)
    title.autoPinEdge(toSuperviewEdge: .top, withInset: 3)

    self.titleView = title

    if let button = self.window.standardWindowButton(.documentIconButton) {
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
                                                   constant: repIconToTitleGap))
      contentView.addConstraint(
        // Here we use title.intrinsicContentSize instead of title.frame because title.frame is still zero.
        NSLayoutConstraint(
          item: title, attribute: .right,
          relatedBy: .equal,
          toItem: contentView, attribute: .centerX,
          multiplier: 1,
          constant: -4 + (button.frame.width + repIconToTitleGap + title.intrinsicContentSize.width) / 2
        )
      )

      self.repIcon = button
    } else {
      title.autoAlignAxis(toSuperviewAxis: .vertical)
    }

    self.window.setFrame(prevFrame, display: true, animate: false)
    self.window.makeFirstResponder(prevFirstResponder)
  }

  private func clearCustomTitle() {
    self.titleView?.removeFromSuperview()
    self.repIcon?.removeFromSuperview()

    self.titleView = nil
    self.repIcon = nil
  }

  private func internalSetRepUrl(_ url: URL?) {
    self.window.representedURL = nil
    self.window.representedURL = url
  }
}

private let repIconToTitleGap = CGFloat(4.0)
