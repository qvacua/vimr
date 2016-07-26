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

  private let windowController = NSWindowController(windowNibName: "MainWindow")
  private let window: NSWindow

  // This is ugly, but since we don't know exactly when NeoVimServer will be ready, we store the initial PrefData here
  // and apply it to NeoVimView in the NeoVimViewDelegate.neoVimReady() method.
  private let initialData: PrefData

  var uuid: String {
    return self.neoVimView.uuid
  }

  private let neoVimView = NeoVimView(forAutoLayout: ())

  init(source: Observable<Any>, manager: MainWindowManager, initialData: PrefData) {
    self.source = source
    self.mainWindowManager = manager
    self.window = self.windowController.window!
    self.initialData = initialData

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
      .map { ($0 as! PrefData).appearance.editorFont }
      .subscribeNext { [unowned self] font in
        self.neoVimView.setFont(font)
      }
      .addDisposableTo(self.disposeBag)
  }
}

// MARK: - NeoVimViewDelegate
extension MainWindowComponent {

  func setNeoVimTitle(title: String) {
    NSLog("\(#function): \(title)")
  }

  func neoVimReady() {
    self.neoVimView.setFont(self.initialData.appearance.editorFont)
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