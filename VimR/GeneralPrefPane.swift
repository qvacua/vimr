/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import PureLayout
import RxSwift

struct GeneralPrefData: Equatable, StandardPrefData {

  fileprivate static let openNewWindowWhenLaunching = "open-new-window-when-launching"
  fileprivate static let openNewWindowOnReactivation = "open-new-window-on-reactivation"
  fileprivate static let ignorePatterns = "ignore-patterns"

  fileprivate static let defaultIgnorePatterns = Set(
      [ "*/.git", "*.o", "*.d", "*.dia" ].map(FileItemIgnorePattern.init)
  )

  static func ==(left: GeneralPrefData, right: GeneralPrefData) -> Bool {
    return left.openNewWindowWhenLaunching == right.openNewWindowWhenLaunching
        && left.openNewWindowOnReactivation == right.openNewWindowOnReactivation
        && left.ignorePatterns == right.ignorePatterns
  }

  static let `default` = GeneralPrefData(openNewWindowWhenLaunching: true,
                                         openNewWindowOnReactivation: true,
                                         ignorePatterns: GeneralPrefData.defaultIgnorePatterns)

  var openNewWindowWhenLaunching: Bool
  var openNewWindowOnReactivation: Bool
  var ignorePatterns: Set<FileItemIgnorePattern>

  init(openNewWindowWhenLaunching: Bool,
       openNewWindowOnReactivation: Bool,
       ignorePatterns: Set<FileItemIgnorePattern>)
  {
    self.openNewWindowWhenLaunching  = openNewWindowWhenLaunching
    self.openNewWindowOnReactivation = openNewWindowOnReactivation
    self.ignorePatterns = ignorePatterns
  }

  init?(dict: [String: Any]) {
    guard let openNewWinWhenLaunching = PrefUtils.bool(from: dict, for: GeneralPrefData.openNewWindowWhenLaunching),
          let openNewWinOnReactivation = PrefUtils.bool(from: dict, for: GeneralPrefData.openNewWindowOnReactivation),
          let ignorePatternsStr = dict[GeneralPrefData.ignorePatterns] as? String
        else {
      return nil
    }

    self.init(openNewWindowWhenLaunching: openNewWinWhenLaunching,
              openNewWindowOnReactivation: openNewWinOnReactivation,
              ignorePatterns: PrefUtils.ignorePatterns(fromString: ignorePatternsStr))
  }

  func dict() -> [String: Any] {
    return [
        GeneralPrefData.openNewWindowWhenLaunching: self.openNewWindowWhenLaunching,
        GeneralPrefData.openNewWindowOnReactivation: self.openNewWindowOnReactivation,
        GeneralPrefData.ignorePatterns: PrefUtils.ignorePatternString(fromSet: self.ignorePatterns),
    ]
  }
}

class GeneralPrefPane: PrefPane, NSTextFieldDelegate {

  override var displayName: String {
    return "General"
  }

  override var pinToContainer: Bool {
    return true
  }

  fileprivate var data: GeneralPrefData

  fileprivate let openWhenLaunchingCheckbox = NSButton(forAutoLayout: ())
  fileprivate let openOnReactivationCheckbox = NSButton(forAutoLayout: ())
  fileprivate let ignoreField = NSTextField(forAutoLayout: ())

  init(source: Observable<Any>, initialData: GeneralPrefData) {
    self.data = initialData
    super.init(source: source)

    self.updateViews(newData: initialData)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func addViews() {
    let paneTitle = self.paneTitleTextField(title: "General")

    let openUntitledWindowTitle = self.titleTextField(title: "Open Untitled Window:")
    self.configureCheckbox(button: self.openWhenLaunchingCheckbox,
                           title: "On launch",
                           action: #selector(GeneralPrefPane.openUntitledWindowWhenLaunchingAction(_:)))
    self.configureCheckbox(button: self.openOnReactivationCheckbox,
                           title: "On re-activation",
                           action: #selector(GeneralPrefPane.openUntitledWindowOnReactivationAction(_:)))

    let whenLaunching = self.openWhenLaunchingCheckbox
    let onReactivation = self.openOnReactivationCheckbox

    let ignoreListTitle = self.titleTextField(title: "Files To Ignore:")
    let ignoreField = self.ignoreField
    NotificationCenter.default.addObserver(forName: NSNotification.Name.NSControlTextDidEndEditing,
                                           object: ignoreField,
                                           queue: nil)
    { [unowned self] _ in
      self.ignorePatternsAction()
    }
    let ignoreInfo =
      self.infoTextField(markdown:
                         "Comma-separated list of ignore patterns  \n"
                         + "Matching files will be ignored in \"Open Quickly\" and the file browser.  \n"
                         + "Example: `*/.git, */node_modules`  \n"
                         + "For detailed information see [VimR Wiki](https://github.com/qvacua/vimr/wiki)."
      )

    let cliToolTitle = self.titleTextField(title: "CLI Tool:")
    let cliToolButton = NSButton(forAutoLayout: ())
    cliToolButton.title = "Copy 'vimr' CLI Tool..."
    cliToolButton.bezelStyle = .rounded
    cliToolButton.isBordered = true
    cliToolButton.setButtonType(.momentaryPushIn)
    cliToolButton.target = self
    cliToolButton.action = #selector(GeneralPrefPane.copyCliTool(_:))
    let cliToolInfo = self.infoTextField(
      markdown: "Put the executable `vimr` in your `$PATH` and execute `vimr -h` for help."
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

    paneTitle.autoPinEdge(toSuperviewEdge: .top, withInset: 18)
    paneTitle.autoPinEdge(toSuperviewEdge: .left, withInset: 18)
    paneTitle.autoPinEdge(toSuperviewEdge: .right, withInset: 18, relation: .greaterThanOrEqual)

    openUntitledWindowTitle.autoAlignAxis(.baseline, toSameAxisOf: whenLaunching, withOffset: 0)
    openUntitledWindowTitle.autoPinEdge(toSuperviewEdge: .left, withInset: 18)

    whenLaunching.autoPinEdge(.top, to: .bottom, of: paneTitle, withOffset: 18)
    whenLaunching.autoPinEdge(.left, to: .right, of: openUntitledWindowTitle, withOffset: 5)
    whenLaunching.autoPinEdge(toSuperviewEdge: .right, withInset: 18, relation: .greaterThanOrEqual)

    onReactivation.autoPinEdge(.top, to: .bottom, of: whenLaunching, withOffset: 5)
    onReactivation.autoPinEdge(.left, to: .left, of: whenLaunching)
    onReactivation.autoPinEdge(toSuperviewEdge: .right, withInset: 18, relation: .greaterThanOrEqual)

    ignoreListTitle.autoAlignAxis(.baseline, toSameAxisOf: ignoreField)
    ignoreListTitle.autoPinEdge(.right, to: .right, of: openUntitledWindowTitle)
    ignoreListTitle.autoPinEdge(toSuperviewEdge: .left, withInset: 18, relation: .greaterThanOrEqual)

    ignoreField.autoPinEdge(.top, to: .bottom, of: onReactivation, withOffset: 18)
    ignoreField.autoPinEdge(toSuperviewEdge: .right, withInset: 18)
    ignoreField.autoPinEdge(.left, to: .right, of: ignoreListTitle, withOffset: 5)

    ignoreInfo.autoPinEdge(.top, to: .bottom, of: ignoreField, withOffset: 5)
    ignoreInfo.autoPinEdge(toSuperviewEdge: .right, withInset: 18)
    ignoreInfo.autoPinEdge(.left, to: .right, of: ignoreListTitle, withOffset: 5)
    
    cliToolTitle.autoAlignAxis(.baseline, toSameAxisOf: cliToolButton)
    cliToolTitle.autoPinEdge(toSuperviewEdge: .left, withInset: 18, relation: .greaterThanOrEqual)
    cliToolTitle.autoPinEdge(.right, to: .right, of: openUntitledWindowTitle)
    
    cliToolButton.autoPinEdge(.top, to: .bottom, of: ignoreInfo, withOffset: 18)
    cliToolButton.autoPinEdge(toSuperviewEdge: .right, withInset: 18, relation: .greaterThanOrEqual)
    cliToolButton.autoPinEdge(.left, to: .right, of: cliToolTitle, withOffset: 5)
    
    cliToolInfo.autoPinEdge(.top, to: .bottom, of: cliToolButton, withOffset: 5)
    cliToolInfo.autoPinEdge(toSuperviewEdge: .right, withInset: 18, relation: .greaterThanOrEqual)
    cliToolInfo.autoPinEdge(.left, to: .right, of: cliToolTitle, withOffset: 5)
    
    self.openWhenLaunchingCheckbox.boolState = self.data.openNewWindowWhenLaunching
    self.openOnReactivationCheckbox.boolState = self.data.openNewWindowOnReactivation
  }

  override func subscription(source: Observable<Any>) -> Disposable {
    return source
      .filter { $0 is PrefData }
      .map { ($0 as! PrefData).general }
      .filter { [unowned self] data in data != self.data }
      .subscribe(onNext: { [unowned self] data in
        self.updateViews(newData: data)
        self.data = data
    })
  }

  override func windowWillClose() {
    self.ignorePatternsAction()
  }

  fileprivate func set(data: GeneralPrefData) {
    self.data = data
    self.publish(event: data)
  }

  fileprivate func ignoreInfoText() -> NSAttributedString {
    let markdown = "Comma-separated list of ignore patterns\n\n"
                   + "Matching files will be ignored in \"Open Quickly\" and the file browser.\n\n"
                   + "Example: `*/.git, */node_modules`\n\n"
                   + "For detailed information see [VimR Wiki](https://github.com/qvacua/vimr/wiki)."

    return NSAttributedString.infoLabel(markdown: markdown)
  }

  fileprivate func updateViews(newData: GeneralPrefData) {
    self.openWhenLaunchingCheckbox.boolState = newData.openNewWindowWhenLaunching
    self.openOnReactivationCheckbox.boolState = newData.openNewWindowOnReactivation
    self.ignoreField.stringValue = PrefUtils.ignorePatternString(fromSet: newData.ignorePatterns)
  }
}

// MARK: - Actions
extension GeneralPrefPane {
  
  func copyCliTool(_ sender: NSButton) {
    let panel = NSOpenPanel()
    panel.canChooseFiles = false
    panel.canChooseDirectories = true
    
    panel.beginSheetModal(for: self.window!) { result in
      guard result == NSFileHandlingPanelOKButton else {
        return
      }
      
      guard let vimrUrl = Bundle.main.url(forResource: "vimr", withExtension: nil) else {
        self.alert(title: "Something Went Wrong.",
                   info: "The CLI tool 'vimr' could not be found. Please re-download VimR and try again.")
        return
      }
      
      guard let targetUrl = panel.url?.appendingPathComponent("vimr") else {
        self.alert(title: "Something Went Wrong.",
                   info: "The target directory could not be determined. Please try again with a different directory.")
        return
      }
      
      do {
        try FileManager.default.copyItem(at: vimrUrl, to: targetUrl)
      } catch let err as NSError {
        self.alert(title: "Error copying 'vimr'", info: err.localizedDescription)
      }
    }
  }

  func openUntitledWindowWhenLaunchingAction(_ sender: NSButton) {
    self.set(data: GeneralPrefData(
      openNewWindowWhenLaunching: self.openWhenLaunchingCheckbox.boolState,
      openNewWindowOnReactivation: self.data.openNewWindowOnReactivation,
      ignorePatterns: self.data.ignorePatterns)
    )
  }

  func openUntitledWindowOnReactivationAction(_ sender: NSButton) {
    self.set(data: GeneralPrefData(
      openNewWindowWhenLaunching: self.data.openNewWindowWhenLaunching,
      openNewWindowOnReactivation: self.openOnReactivationCheckbox.boolState,
      ignorePatterns: self.data.ignorePatterns)
    )
  }

  fileprivate func ignorePatternsAction() {
    let patterns = PrefUtils.ignorePatterns(fromString: self.ignoreField.stringValue)
    if patterns == self.data.ignorePatterns {
      return
    }

    self.set(data: GeneralPrefData(
      openNewWindowWhenLaunching: self.data.openNewWindowWhenLaunching,
      openNewWindowOnReactivation: self.data.openNewWindowOnReactivation,
      ignorePatterns: patterns)
    )
  }

  fileprivate func alert(title: String, info: String) {
    let alert = NSAlert()
    alert.alertStyle = .warning
    alert.messageText = title
    alert.informativeText = info
    alert.runModal()
  }
}

