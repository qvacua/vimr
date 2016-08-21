/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import PureLayout
import RxSwift

class MainWindowComponent: NSObject, NSWindowDelegate, NeoVimViewDelegate, Component {

  private let source: Observable<Any>
  private let disposeBag = DisposeBag()

  private let subject = PublishSubject<Any>()
  var sink: Observable<Any> {
    return self.subject.asObservable()
  }

  private weak var mainWindowManager: MainWindowManager?
  private let fontManager = NSFontManager.sharedFontManager()

  private let windowController = NSWindowController(windowNibName: "MainWindow")
  private let window: NSWindow

  private var defaultEditorFont: NSFont
  private var usesLigatures: Bool

  var uuid: String {
    return self.neoVimView.uuid
  }

  private let neoVimView = NeoVimView(forAutoLayout: ())

  init(source: Observable<Any>, manager: MainWindowManager, urls: [NSURL] = [], initialData: PrefData) {
    self.source = source
    self.mainWindowManager = manager
    self.window = self.windowController.window!
    self.defaultEditorFont = initialData.appearance.editorFont
    self.usesLigatures = initialData.appearance.editorUsesLigatures

    super.init()

    self.window.delegate = self
    self.neoVimView.delegate = self

    self.addViews()
    self.addReactions()
    
    self.neoVimView.font = self.defaultEditorFont
    self.neoVimView.usesLigatures = self.usesLigatures
    self.neoVimView.open(urls: urls)

    self.window.makeFirstResponder(self.neoVimView)
    self.windowController.showWindow(self)
  }

  deinit {
    self.subject.onCompleted()
  }

  func isDirty() -> Bool {
    return self.neoVimView.hasDirtyDocs()
  }

  func closeAllNeoVimWindows() {
    self.neoVimView.closeAllWindows()
  }

  func closeAllNeoVimWindowsWithoutSaving() {
    self.neoVimView.closeAllWindowsWithoutSaving()
  }

  private func addViews() {
    self.window.contentView?.addSubview(self.neoVimView)
    self.neoVimView.autoPinEdgesToSuperviewEdges()
  }

  private func addReactions() {
    self.source
      .filter { $0 is PrefData }
      .map { ($0 as! PrefData).appearance }
      .filter { [unowned self] appearanceData in
        !appearanceData.editorFont.isEqualTo(self.neoVimView.font)
          || appearanceData.editorUsesLigatures != self.neoVimView.usesLigatures
      }
      .subscribeNext { [unowned self] appearance in
        self.neoVimView.usesLigatures = appearance.editorUsesLigatures
        self.neoVimView.font = appearance.editorFont
      }
      .addDisposableTo(self.disposeBag)
  }
}

// MARK: - File Menu Items
extension MainWindowComponent {
  
  @IBAction func newTab(sender: AnyObject!) {
    self.neoVimView.newTab()
  }

  @IBAction func openDocument(sender: AnyObject!) {
    let panel = NSOpenPanel()
    panel.canChooseDirectories = true
    panel.beginSheetModalForWindow(self.window) { result in
      guard result == NSFileHandlingPanelOKButton else {
        return
      }
      
      // The open panel can choose only one file.
      self.neoVimView.open(urls: panel.URLs)
    }
  }

  @IBAction func saveDocument(sender: AnyObject!) {
    let curBuf = self.neoVimView.currentBuffer()
    
    if curBuf.fileName == nil {
      self.savePanelSheet { self.neoVimView.saveCurrentTab(url: $0) }
      return
    }
    
    self.neoVimView.saveCurrentTab()
  }
  
  @IBAction func saveDocumentAs(sender: AnyObject!) {
    self.savePanelSheet { url in
      self.neoVimView.saveCurrentTab(url: url)
      
      if self.neoVimView.isCurrentBufferDirty() {
        self.neoVimView.openInNewTab(urls: [url])
      } else {
        self.neoVimView.openInCurrentTab(url: url)
      }
    }
  }
  
  private func savePanelSheet(action action: (NSURL) -> Void) {
    let panel = NSSavePanel()
    panel.beginSheetModalForWindow(self.window) { result in
      guard result == NSFileHandlingPanelOKButton else {
        return
      }
      
      let showAlert: () -> Void = {
        let alert = NSAlert()
        alert.addButtonWithTitle("OK")
        alert.messageText = "Invalid File Name"
        alert.informativeText = "The file name you have entered cannot be used. Please use a different name."
        alert.alertStyle = .WarningAlertStyle
        
        alert.runModal()
      }
      
      guard let url = panel.URL else {
        showAlert()
        return
      }
      
      guard url.path != nil else {
        showAlert()
        return
      }
      
      action(url)
    }
  }
}

// MARK: - Font Menu Items
extension MainWindowComponent {

  @IBAction func resetFontSize(sender: AnyObject!) {
    self.neoVimView.font = self.defaultEditorFont
  }

  @IBAction func makeFontBigger(sender: AnyObject!) {
    let curFont = self.neoVimView.font
    let font = self.fontManager.convertFont(curFont,
                                            toSize: min(curFont.pointSize + 1, PrefStore.maximumEditorFontSize))
    self.neoVimView.font = font
  }

  @IBAction func makeFontSmaller(sender: AnyObject!) {
    let curFont = self.neoVimView.font
    let font = self.fontManager.convertFont(curFont,
                                            toSize: max(curFont.pointSize - 1, PrefStore.minimumEditorFontSize))
    self.neoVimView.font = font
  }
}

// MARK: - NeoVimViewDelegate
extension MainWindowComponent {

  func setTitle(title: String) {
    self.window.title = title
  }

  func setDirtyStatus(dirty: Bool) {
    self.windowController.setDocumentEdited(dirty)
  }
  
  func neoVimStopped() {
    self.windowController.close()
  }
}

// MARK: - NSWindowDelegate
extension MainWindowComponent {

  func windowWillClose(notification: NSNotification) {
    self.mainWindowManager?.closeMainWindow(self)
  }

  func windowShouldClose(sender: AnyObject) -> Bool {
    if self.neoVimView.isCurrentBufferDirty() {
      let alert = NSAlert()
      alert.addButtonWithTitle("Cancel")
      alert.addButtonWithTitle("Discard and Close")
      alert.messageText = "The current buffer has unsaved changes!"
      alert.alertStyle = .WarningAlertStyle
      alert.beginSheetModalForWindow(self.window) { response in
        if response == NSAlertSecondButtonReturn {
          self.neoVimView.closeCurrentTabWithoutSaving()
        }
      }

      return false
    }

    self.neoVimView.closeCurrentTab()
    return false
  }
}