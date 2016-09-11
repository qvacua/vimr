/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import PureLayout
import RxSwift

struct GeneralPrefData: Equatable {
  let openNewWindowWhenLaunching: Bool
  let openNewWindowOnReactivation: Bool

  let ignorePatterns: Set<FileItemIgnorePattern>
}

func == (left: GeneralPrefData, right: GeneralPrefData) -> Bool {
  return left.openNewWindowWhenLaunching == right.openNewWindowWhenLaunching
    && left.openNewWindowOnReactivation == right.openNewWindowOnReactivation
}

class GeneralPrefPane: PrefPane {

  override var pinToContainer: Bool {
    return true
  }

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

    let ignoreListTitle = self.titleTextField(title: "Files To Ignore:")
    let ignoreField = NSTextField(forAutoLayout: ())
    let ignoreInfo = self.infoTextField(text: "")
    ignoreInfo.attributedStringValue = self.ignoreInfoText()

    let cliToolTitle = self.titleTextField(title: "CLI Tool:")
    let cliToolButton = NSButton(forAutoLayout: ())
    cliToolButton.title = "Copy 'vimr' CLI tool..."
    cliToolButton.bezelStyle = .RoundedBezelStyle
    cliToolButton.bordered = true
    cliToolButton.setButtonType(.MomentaryPushInButton)
    cliToolButton.target = self
    cliToolButton.action = #selector(GeneralPrefPane.copyCliTool(_:))
    let cliToolInfo = self.infoTextField(
      text: "Put the executable 'vimr' in your $PATH and execute 'vimr -h' for help."
    )

    self.addSubview(paneTitle)
    self.addSubview(openUntitledWindowTitle)
    self.addSubview(whenLaunching)
    self.addSubview(onReactivation)

    self.addSubview(ignoreListTitle)
    self.addSubview(ignoreField)
    self.addSubview(ignoreInfo)

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

    ignoreListTitle.autoAlignAxis(.Baseline, toSameAxisOfView: ignoreField)
    ignoreListTitle.autoPinEdge(.Right, toEdge: .Right, ofView: openUntitledWindowTitle)
    ignoreListTitle.autoPinEdgeToSuperviewEdge(.Left, withInset: 18, relation: .GreaterThanOrEqual)

    ignoreField.autoPinEdge(.Top, toEdge: .Bottom, ofView: onReactivation, withOffset: 18)
    ignoreField.autoPinEdgeToSuperviewEdge(.Right, withInset: 18)
    ignoreField.autoPinEdge(.Left, toEdge: .Right, ofView: ignoreListTitle, withOffset: 5)

    ignoreInfo.autoPinEdge(.Top, toEdge: .Bottom, ofView: ignoreField, withOffset: 5)
    ignoreInfo.autoPinEdgeToSuperviewEdge(.Right, withInset: 18)
    ignoreInfo.autoPinEdge(.Left, toEdge: .Right, ofView: ignoreListTitle, withOffset: 5)
    
    cliToolTitle.autoAlignAxis(.Baseline, toSameAxisOfView: cliToolButton)
    cliToolTitle.autoPinEdgeToSuperviewEdge(.Left, withInset: 18, relation: .GreaterThanOrEqual)
    cliToolTitle.autoPinEdge(.Right, toEdge: .Right, ofView: openUntitledWindowTitle)
    
    cliToolButton.autoPinEdge(.Top, toEdge: .Bottom, ofView: ignoreInfo, withOffset: 18)
    cliToolButton.autoPinEdgeToSuperviewEdge(.Right, withInset: 18, relation: .GreaterThanOrEqual)
    cliToolButton.autoPinEdge(.Left, toEdge: .Right, ofView: cliToolTitle, withOffset: 5)
    
    cliToolInfo.autoPinEdge(.Top, toEdge: .Bottom, ofView: cliToolButton, withOffset: 5)
    cliToolInfo.autoPinEdgeToSuperviewEdge(.Right, withInset: 18, relation: .GreaterThanOrEqual)
    cliToolInfo.autoPinEdge(.Left, toEdge: .Right, ofView: cliToolTitle, withOffset: 5)
    
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

  private func ignoreInfoText() -> NSAttributedString {
    let wikiUrl = NSURL(string: "https://github.com/qvacua/vimr/wiki")!
    let font = NSFont.systemFontOfSize(NSFont.smallSystemFontSize())
    let linkStr = NSAttributedString.link(withUrl: wikiUrl, text: "VimR Wiki", font: font)
    let ignoreInfoStr = NSMutableAttributedString(string:
      "Comma-separated list of ignore patterns\n"
        + "Matching files will be ignored in \"Open Quickly\".\n"
        + "Example: */.git, */node_modules\n"
        + "For detailed information go to ",
                                                  attributes:[
                                                    NSFontAttributeName: font,
                                                    NSForegroundColorAttributeName: NSColor.grayColor()
      ]
    )
    ignoreInfoStr.appendAttributedString(linkStr)
    ignoreInfoStr.appendAttributedString(
      NSAttributedString(string: ".", attributes: [
        NSFontAttributeName: font,
        NSForegroundColorAttributeName: NSColor.grayColor()
        ])
    )

    return ignoreInfoStr
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
                                openNewWindowOnReactivation: self.data.openNewWindowOnReactivation,
                                ignorePatterns: self.data.ignorePatterns)
  }

  func openUntitledWindowOnReactivation(sender: NSButton) {
    self.data = GeneralPrefData(openNewWindowWhenLaunching: self.data.openNewWindowWhenLaunching,
                                openNewWindowOnReactivation: self.openOnReactivationCheckbox.boolState,
                                ignorePatterns: self.data.ignorePatterns)
  }
  
  private func alert(title title: String, info: String) {
    let alert = NSAlert()
    alert.alertStyle = .WarningAlertStyle
    alert.messageText = title
    alert.informativeText = info
    alert.runModal()
  }
}
