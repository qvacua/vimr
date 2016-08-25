/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import PureLayout
import RxSwift

struct GeneralPrefData {
  let openNewWindowWhenLaunching: Bool
  let openNewWindowOnReactivation: Bool
}

func == (left: GeneralPrefData, right: GeneralPrefData) -> Bool {
  return left.openNewWindowWhenLaunching == right.openNewWindowWhenLaunching
    && left.openNewWindowOnReactivation == right.openNewWindowOnReactivation
}

func != (left: GeneralPrefData, right: GeneralPrefData) -> Bool {
  return !(left == right)
}

class GeneralPrefPane: PrefPane {

  private var data: GeneralPrefData {
    willSet {
      self.updateViews(newData: newValue)
    }

    didSet {
      self.publish(event: self.data)
    }
  }

  private let openWhenLaunchingCheckbox = NSButton(forAutoLayout: ())
  private let openOnReactivationCheckbox = NSButton(forAutoLayout: ())

  init(source: Observable<Any>, initialData: GeneralPrefData) {
    self.data = initialData
    super.init(source: source)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func addViews() {
    let paneTitle = self.paneTitleTextField(title: "General")

    let openUntitledWindowTitle = self.titleTextField(title: "Open Untitled Window:")
    self.configureCheckbox(button: self.openWhenLaunchingCheckbox,
                           title: "On Launch",
                           action: #selector(GeneralPrefPane.openUntitledWindowWhenLaunchingAction(_:)))
    self.configureCheckbox(button: self.openOnReactivationCheckbox,
                           title: "On Re-Activation",
                           action: #selector(GeneralPrefPane.openUntitledWindowOnReactivation(_:)))

    let whenLaunching = self.openWhenLaunchingCheckbox
    let onReactivation = self.openOnReactivationCheckbox
    
    let cliToolTitle = self.titleTextField(title: "CLI Tool:")
    let cliToolButton = NSButton(forAutoLayout: ())
    cliToolButton.title = "Copy 'vimr' CLI tool..."
    cliToolButton.bezelStyle = .RoundedBezelStyle
    cliToolButton.bordered = true
    cliToolButton.setButtonType(.MomentaryPushInButton)
    cliToolButton.target = self
    cliToolButton.action = #selector(GeneralPrefPane.copyCliTool(_:))
    let cliToolInfo = NSTextField(forAutoLayout: ())
    cliToolInfo.font = NSFont.systemFontOfSize(NSFont.smallSystemFontSize())
    cliToolInfo.textColor = NSColor.grayColor()
    cliToolInfo.stringValue = "Put the executable 'vimr' in your $PATH and execute 'vimr -h' for help."
    cliToolInfo.backgroundColor = NSColor.clearColor()
    cliToolInfo.editable = false
    cliToolInfo.bordered = false

    self.addSubview(paneTitle)
    self.addSubview(openUntitledWindowTitle)
    self.addSubview(whenLaunching)
    self.addSubview(onReactivation)
    self.addSubview(cliToolTitle)
    self.addSubview(cliToolButton)
    self.addSubview(cliToolInfo)

    paneTitle.autoPinEdgeToSuperviewEdge(.Top, withInset: 18)
    paneTitle.autoPinEdgeToSuperviewEdge(.Left, withInset: 18)
    paneTitle.autoPinEdgeToSuperviewEdge(.Right, withInset: 18, relation: .GreaterThanOrEqual)

    openUntitledWindowTitle.autoAlignAxis(.Baseline, toSameAxisOfView: whenLaunching, withOffset: 0)
    openUntitledWindowTitle.autoPinEdgeToSuperviewEdge(.Left, withInset: 18)

    whenLaunching.autoPinEdge(.Top, toEdge: .Bottom, ofView: paneTitle, withOffset: 18)
    whenLaunching.autoPinEdge(.Left, toEdge: .Right, ofView: openUntitledWindowTitle, withOffset: 5)
    whenLaunching.autoPinEdgeToSuperviewEdge(.Right, withInset: 18, relation: .GreaterThanOrEqual)

    onReactivation.autoPinEdge(.Top, toEdge: .Bottom, ofView: whenLaunching, withOffset: 5)
    onReactivation.autoPinEdge(.Left, toEdge: .Left, ofView: whenLaunching)
    onReactivation.autoPinEdgeToSuperviewEdge(.Right, withInset: 18, relation: .GreaterThanOrEqual)
    
    cliToolTitle.autoAlignAxis(.Baseline, toSameAxisOfView: cliToolButton, withOffset: 0)
    cliToolTitle.autoPinEdgeToSuperviewEdge(.Left, withInset: 18, relation: .GreaterThanOrEqual)
    cliToolTitle.autoPinEdge(.Right, toEdge: .Right, ofView: openUntitledWindowTitle)
    
    cliToolButton.autoPinEdge(.Top, toEdge: .Bottom, ofView: onReactivation, withOffset: 18)
    cliToolButton.autoPinEdge(.Left, toEdge: .Right, ofView: cliToolTitle, withOffset: 5)
    cliToolButton.autoPinEdgeToSuperviewEdge(.Right, withInset: 18, relation: .GreaterThanOrEqual)
    
    cliToolInfo.autoPinEdge(.Top, toEdge: .Bottom, ofView: cliToolButton, withOffset: 5)
    cliToolInfo.autoPinEdge(.Left, toEdge: .Right, ofView: cliToolTitle, withOffset: 5)
    cliToolInfo.autoPinEdgeToSuperviewEdge(.Right, withInset: 18, relation: .GreaterThanOrEqual)
    cliToolInfo.autoPinEdgeToSuperviewEdge(.Bottom, withInset: 18)
    
    self.openWhenLaunchingCheckbox.boolState = self.data.openNewWindowWhenLaunching
    self.openOnReactivationCheckbox.boolState = self.data.openNewWindowOnReactivation
  }

  override func subscription(source source: Observable<Any>) -> Disposable {
    return source
      .filter { $0 is PrefData }
      .map { ($0 as! PrefData).general }
      .filter { [unowned self] data in data != self.data }
      .subscribeNext { [unowned self] data in self.data = data }
  }

  private func updateViews(newData newData: GeneralPrefData) {
    call(self.openWhenLaunchingCheckbox.boolState = newData.openNewWindowWhenLaunching,
         whenNot: newData.openNewWindowWhenLaunching == self.data.openNewWindowWhenLaunching)

    call(self.openOnReactivationCheckbox.boolState = newData.openNewWindowOnReactivation,
         whenNot: newData.openNewWindowOnReactivation == self.data.openNewWindowOnReactivation)
  }
}

// MARK: - Actions
extension GeneralPrefPane {
  
  func copyCliTool(sender: NSButton) {
    let panel = NSOpenPanel()
    panel.canChooseFiles = false
    panel.canChooseDirectories = true
    
    panel.beginSheetModalForWindow(self.window!) { result in
      guard result == NSFileHandlingPanelOKButton else {
        return
      }
      
      guard let vimrUrl = NSBundle.mainBundle().URLForResource("vimr", withExtension: nil) else {
        self.alert(title: "Something Went Wrong.",
                   info: "The CLI tool 'vimr' could not be found. Please re-download VimR and try again.")
        return
      }
      
      guard let targetUrl = panel.URL?.URLByAppendingPathComponent("vimr") else {
        self.alert(title: "Something Went Wrong.",
                   info: "The target directory could not be determined. Please try again with a different directory.")
        return
      }
      
      do {
        try NSFileManager.defaultManager().copyItemAtURL(vimrUrl, toURL: targetUrl)
      } catch let err as NSError {
        self.alert(title: "Error copying 'vimr'", info: err.localizedDescription)
      }
    }
  }

  func openUntitledWindowWhenLaunchingAction(sender: NSButton) {
    self.data = GeneralPrefData(openNewWindowWhenLaunching: self.openWhenLaunchingCheckbox.boolState,
                                openNewWindowOnReactivation: self.data.openNewWindowOnReactivation)
  }

  func openUntitledWindowOnReactivation(sender: NSButton) {
    self.data = GeneralPrefData(openNewWindowWhenLaunching: self.data.openNewWindowWhenLaunching,
                                openNewWindowOnReactivation: self.openOnReactivationCheckbox.boolState)
  }
  
  private func alert(title title: String, info: String) {
    let alert = NSAlert()
    alert.alertStyle = .WarningAlertStyle
    alert.messageText = title
    alert.informativeText = info
    alert.runModal()
  }
}
