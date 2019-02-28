/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import RxSwift

// MARK: - File Menu Item Actions
extension MainWindow {

  @IBAction func newTab(_ sender: Any?) {
    self.neoVimView
      .newTab()
      .trigger()
  }

  @IBAction func openDocument(_ sender: Any?) {
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
        .trigger()
    }
  }

  @IBAction func openQuickly(_ sender: Any?) {
    self.emit(self.uuidAction(for: .openQuickly))
  }

  @IBAction func saveDocument(_ sender: Any?) {
    self.neoVimView
      .currentBuffer()
      .observeOn(MainScheduler.instance)
      .flatMapCompletable { curBuf -> Completable in
        if curBuf.url == nil {
          self.savePanelSheet {
            self.neoVimView
              .saveCurrentTab(url: $0)
              .trigger()
          }
          return Completable.empty()
        }

        return self.neoVimView.saveCurrentTab()
      }
      .trigger()
  }

  @IBAction func saveDocumentAs(_ sender: Any?) {
    self.neoVimView
      .currentBuffer()
      .observeOn(MainScheduler.instance)
      .value(onSuccess: { curBuf in
        self.savePanelSheet { url in
          self.neoVimView
            .saveCurrentTab(url: url)
            .andThen(
              curBuf.isDirty ? self.neoVimView.openInNewTab(urls: [url]) : self.neoVimView.openInCurrentTab(url: url)
            )
            .trigger()
        }
      })
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
        alert.informativeText = "The file name you have entered cannot be used. Please use a different name."
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

  @IBAction func toggleAllTools(_ sender: Any?) {
    self.workspace.toggleAllTools()
    self.focusNvimView(self)

    self.emit(self.uuidAction(for: .toggleAllTools(self.workspace.isAllToolsVisible)))
  }

  @IBAction func toggleToolButtons(_ sender: Any?) {
    self.workspace.toggleToolButtons()
    self.emit(self.uuidAction(for: .toggleToolButtons(self.workspace.isToolButtonsVisible)))
  }

  @IBAction func toggleFileBrowser(_ sender: Any?) {
    guard let fileBrowser = self.fileBrowserContainer else { return }
    self.toggle(tool: fileBrowser, toolType: .fileBrowser)
  }

  @IBAction func toggleBufferList(_ sender: Any?) {
    guard let bufferList = self.buffersListContainer else { return }
    self.toggle(tool: bufferList, toolType: .bufferList)
  }

  @IBAction func toggleMarkdownPreview(_ sender: Any?) {
    guard let markdownPreview = self.previewContainer else { return }
    self.toggle(tool: markdownPreview, toolType: .markdownPreview)
  }

  @IBAction func toggleHtmlPreview(_ sender: Any?) {
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

    case #selector(toggleAllTools(_:)), #selector(toggleToolButtons(_:)):
      return canToggleTools

    case #selector(toggleFileBrowser(_:)):
      return canToggleFileBrowser

    case #selector(focusNvimView(_:)):
      return canFocusNvimView

    case #selector(openDocument(_:)):
      return canOpen

    case #selector(openQuickly(_:)):
      return canOpenQuickly

    case #selector(saveDocument(_:)):
      return canSave

    case #selector(saveDocumentAs(_:)):
      return canSaveAs

    default:
      return true

    }
  }
}
