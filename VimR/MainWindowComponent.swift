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

  private let urlsToBeOpenedWhenReady: [NSURL]

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
    self.urlsToBeOpenedWhenReady = urls

    super.init()

    self.window.delegate = self
    self.neoVimView.delegate = self

    self.addViews()
    self.addReactions()

    self.window.makeFirstResponder(self.neoVimView)
    self.windowController.showWindow(self)
  }

  deinit {
    self.subject.onCompleted()
  }

  func isDirty() -> Bool {
    return self.neoVimView.hasDirtyDocs()
  }

  private func addViews() {
    self.window.contentView?.addSubview(self.neoVimView)
    self.neoVimView.autoPinEdgesToSuperviewEdges()
  }

  private func addReactions() {
    self.source
      .filter { $0 is PrefData }
      .map { ($0 as! PrefData).appearance }
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

  @IBAction func openInTab(sender: AnyObject!) {
    let panel = NSOpenPanel()
    panel.canChooseDirectories = true
    panel.beginSheetModalForWindow(self.window) { result in
      guard result == NSFileHandlingPanelOKButton else {
        return
      }
      
      // The open panel can choose only one file.
      let url = panel.URLs[0]
      self.neoVimView.openInNewTab(url: url)
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

  func neoVimReady() {
    self.neoVimView.font = self.defaultEditorFont
    self.neoVimView.usesLigatures = self.usesLigatures

    if self.urlsToBeOpenedWhenReady.isEmpty {
      return
    }

    self.urlsToBeOpenedWhenReady.enumerate().forEach { (idx, url) in
      if idx == 0 {
        self.neoVimView.open(url: url)
      } else {
        self.neoVimView.openInNewTab(url: url)
      }
    }

//    self.neoVimView.open(url: url)
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
    guard self.isDirty() else {
      return true
    }

    let alert = NSAlert()
    alert.addButtonWithTitle("Cancel")
    alert.addButtonWithTitle("Discard and Close")
    alert.messageText = "There are unsaved buffers!"
    alert.alertStyle = .WarningAlertStyle
    alert.beginSheetModalForWindow(self.window) { response in
      if response == NSAlertSecondButtonReturn {
        self.windowController.close()
      }
    }

    return false
  }
}