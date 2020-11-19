/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import Commons
import MessagePack
import RxSwift
import Workspace

// MARK: - RpcEvent Actions

extension MainWindow {
  func rpcEventAction(params rawParams: [MessagePackValue]) {
    guard rawParams.count > 0 else { return }

    guard let strEvent = rawParams[0].stringValue,
          let event = RpcEvent(rawValue: "\(RpcEvent.prefix).\(strEvent)")
    else {
      return
    }
    let params = Array(rawParams.suffix(from: 1))

    switch event {
    case .makeSessionTemporary:
      self.emit(self.uuidAction(for: .makeSessionTemporary))

    case .maximizeWindow:
      guard let screen = self.window.screen else { return }
      self.window.setFrame(screen.frame, display: true)

    case .toggleTools:
      guard params.count == 1 else { return }

      let param = params[0].int64Value

      if params.isEmpty || param == 0 {
        self.toggleAllTools(self)
      } else if param == -1 {
        self.hideAllTools()
      } else if param == 1 {
        self.showAllTools()
      }

    case .toggleToolButtons:
      guard params.count == 1 else { return }

      let param = params[0].int64Value

      if params.isEmpty || param == 0 {
        self.toggleToolButtons(self)
      } else if param == -1 {
        self.hideToolButtons()
      } else if param == 1 {
        self.showToolButtons()
      }

    case .toggleFullScreen:
      self.window.toggleFullScreen(self)

    case .setFont:
      guard params.count == 2 else { return }
      guard let fontName = params[0].stringValue,
            let fontSize = params[1].int64Value,
            let font = NSFont(name: fontName, size: fontSize.cgf)
      else {
        return
      }

      self.emit(self.uuidAction(for: .setFont(font)))

    case .setLinespacing:
      guard params.count == 1 else { return }
      guard let linespacing = params[0].floatValue else { return }

      self.emit(self.uuidAction(for: .setLinespacing(linespacing.cgf)))

    case .setCharacterspacing:
      guard params.count == 1 else { return }
      guard let characterspacing = params[0].floatValue else { return }

      self.emit(self.uuidAction(for: .setCharacterspacing(characterspacing.cgf)))
    }
  }

  private func hideToolButtons() {
    self.workspace.hideToolButtons()
    self.focusNvimView(self)
    self.emit(self.uuidAction(
      for: .toggleToolButtons(self.workspace.isToolButtonsVisible)
    ))
  }

  private func showToolButtons() {
    self.workspace.showToolButtons()
    self.focusNvimView(self)
    self.emit(self.uuidAction(
      for: .toggleToolButtons(self.workspace.isToolButtonsVisible)
    ))
  }

  private func hideAllTools() {
    self.workspace.hideAllTools()
    self.focusNvimView(self)
    self.emit(self.uuidAction(
      for: .toggleAllTools(self.workspace.isAllToolsVisible)
    ))
  }

  private func showAllTools() {
    self.workspace.showAllTools()
    self.focusNvimView(self)
    self.emit(self.uuidAction(
      for: .toggleAllTools(self.workspace.isAllToolsVisible)
    ))
  }
}

// MARK: - File Menu Item Actions

extension MainWindow {
  @IBAction func newTab(_: Any?) {
    self.neoVimView
      .newTab()
      .subscribe()
      .disposed(by: self.disposeBag)
  }

  @IBAction func openDocument(_: Any?) {
    let panel = NSOpenPanel()
    panel.canChooseDirectories = true
    panel.allowsMultipleSelection = true
    panel.beginSheetModal(for: self.window) { result in
      guard result == .OK else {
        return
      }

      let urls = panel.urls
      self.neoVimView
        .allBuffers()
        .flatMapCompletable { bufs -> Completable in
          if bufs.count == 1 {
            let isTransient = bufs.first?.isTransient ?? false

            if isTransient {
              self.neoVimView.cwd = FileUtils.commonParent(of: urls)
            }
          }
          return self.neoVimView.open(urls: urls)
        }
        .subscribe()
        .disposed(by: self.disposeBag)
    }
  }

  @IBAction func openQuickly(_: Any?) {
    self.emit(self.uuidAction(for: .openQuickly))
  }

  @IBAction func closeWindow(_: Any?) {
    self.closeWindow = true
    self.window.performClose(nil)
  }

  @IBAction func saveDocument(_: Any?) {
    self.neoVimView
      .currentBuffer()
      .observeOn(MainScheduler.instance)
      .flatMapCompletable { curBuf -> Completable in
        if curBuf.url == nil {
          self.savePanelSheet {
            self.neoVimView
              .saveCurrentTab(url: $0)
              .subscribe()
              .disposed(by: self.disposeBag)
          }
          return Completable.empty()
        }

        return self.neoVimView.saveCurrentTab()
      }
      .subscribe()
      .disposed(by: self.disposeBag)
  }

  @IBAction func saveDocumentAs(_: Any?) {
    self.neoVimView
      .currentBuffer()
      .observeOn(MainScheduler.instance)
      .subscribe(onSuccess: { curBuf in
        self.savePanelSheet { url in
          self.neoVimView
            .saveCurrentTab(url: url)
            .andThen(
              curBuf.isDirty ? self.neoVimView.openInNewTab(urls: [url]) : self.neoVimView
                .openInCurrentTab(url: url)
            )
            .subscribe()
            .disposed(by: self.disposeBag)
        }
      })
      .disposed(by: self.disposeBag)
  }

  fileprivate func savePanelSheet(action: @escaping (URL) -> Void) {
    let panel = NSSavePanel()
    panel.beginSheetModal(for: self.window) { result in
      guard result == .OK else {
        return
      }

      let showAlert: () -> Void = {
        let alert = NSAlert()
        alert.addButton(withTitle: "OK")
        alert.messageText = "Invalid File Name"
        alert
          .informativeText =
          "The file name you have entered cannot be used. Please use a different name."
        alert.alertStyle = .warning

        alert.runModal()
      }

      guard let url = panel.url else {
        showAlert()
        return
      }

      action(url)
    }
  }
}

// MARK: - Tools Menu Item Actions

extension MainWindow {
  @IBAction func toggleAllTools(_: Any?) {
    self.workspace.toggleAllTools()
    self.focusNvimView(self)

    self.emit(self.uuidAction(for: .toggleAllTools(self.workspace.isAllToolsVisible)))
  }

  @IBAction func toggleToolButtons(_: Any?) {
    self.workspace.toggleToolButtons()
    self.emit(self.uuidAction(for: .toggleToolButtons(self.workspace.isToolButtonsVisible)))
  }

  @IBAction func toggleFileBrowser(_: Any?) {
    guard let fileBrowser = self.fileBrowserContainer else { return }
    self.toggle(tool: fileBrowser, toolType: .fileBrowser)
  }

  @IBAction func toggleBufferList(_: Any?) {
    guard let bufferList = self.buffersListContainer else { return }
    self.toggle(tool: bufferList, toolType: .bufferList)
  }

  @IBAction func toggleMarkdownPreview(_: Any?) {
    guard let markdownPreview = self.previewContainer else { return }
    self.toggle(tool: markdownPreview, toolType: .markdownPreview)
  }

  @IBAction func toggleHtmlPreview(_: Any?) {
    guard let htmlPreview = self.htmlPreviewContainer else { return }
    self.toggle(tool: htmlPreview, toolType: .htmlPreview)
  }

  @IBAction func focusNvimView(_: Any?) {
    self.emit(self.uuidAction(for: .focus(.neoVimView)))
  }

  private func toggle(tool: WorkspaceTool, toolType: FocusableView) {
    if tool.isSelected == true {
      if tool.view.isFirstResponder == true {
        tool.toggle()
        self.focusNvimView(self)
      } else {
        self.emit(self.uuidAction(for: .focus(toolType)))
      }

      return
    }

    tool.toggle()
    self.emit(self.uuidAction(for: .focus(toolType)))
  }
}

// MARK: - NSUserInterfaceValidationsProtocol

extension MainWindow {
  func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
    let canSave = self.neoVimView.currentBuffer().syncValue()?.type == ""
    let canSaveAs = canSave
    let canOpen = canSave
    let canOpenQuickly = canSave
    let canFocusNvimView = self.window.firstResponder != self.neoVimView
    let canToggleFileBrowser = self.tools.keys.contains(.fileBrowser)
    let canToggleTools = !self.tools.isEmpty

    guard let action = item.action else {
      return true
    }

    switch action {
    case #selector(self.toggleAllTools(_:)), #selector(self.toggleToolButtons(_:)):
      return canToggleTools

    case #selector(self.toggleFileBrowser(_:)):
      return canToggleFileBrowser

    case #selector(self.focusNvimView(_:)):
      return canFocusNvimView

    case #selector(self.openDocument(_:)):
      return canOpen

    case #selector(self.openQuickly(_:)):
      return canOpenQuickly

    case #selector(self.saveDocument(_:)):
      return canSave

    case #selector(self.saveDocumentAs(_:)):
      return canSaveAs

    default:
      return true
    }
  }
}
