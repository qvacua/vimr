/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import PureLayout
import RxSwift
import ShortcutRecorder

class ShortcutsPref: PrefPane,
                     UiComponent,
                     NSOutlineViewDelegate,
                     RecorderControlDelegate {

  typealias StateType = AppState

  @objc dynamic var content = [ShortcutItem]()

  override var displayName: String { "Shortcuts" }

  override var pinToContainer: Bool { true }

  required init(source: Observable<StateType>, emitter: ActionEmitter, state: StateType) {
    self.shortcutsDefaultsController = NSUserDefaultsController(
      defaults: self.shortcutsUserDefaults,
      initialValues: nil
    )

    super.init(frame: .zero)

    if let version = self.shortcutsUserDefaults?.integer(forKey: "version"),
       version > defaultsVersion {
      let alert = NSAlert()
      alert.alertStyle = .warning
      alert.messageText = "Incompatible Defaults for Shortcuts"
      alert.informativeText = "The stored defaults for shortcuts are not compatible with "
                              + "this version of VimR. You can delete the stored defaults "
                              + "by executing 'defaults delete com.qvacua.VimR.menuitems' "
                              + "in Terminal."
      alert.runModal()
      return
    }

    self.migrateDefaults()
    self.initShortcutUserDefaults()

    self.addViews()

    self.initShortcutItems()
    if let children = self.shortcutItemsRoot.children { self.content.append(contentsOf: children) }

    self.initMenuItemsBindings()
    self.initOutlineViewBindings()

    self.shortcutList.expandItem(nil, expandChildren: true)
  }

  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  private let shortcutList = NSOutlineView.standardOutlineView()
  private let shortcutScrollView = NSScrollView.standardScrollView()
  private let resetButton = NSButton(forAutoLayout: ())

  private let treeController = NSTreeController()
  private let shortcutItemsRoot = ShortcutItem(title: "root", isLeaf: false, item: nil)

  private let keyEqTransformer = DataToKeyEquivalentTransformer()
  private let keyEqModTransformer = DataToKeyEquivalentModifierMaskTransformer()

  private let shortcutsUserDefaults = UserDefaults(suiteName: "com.qvacua.VimR.menuitems")
  private let shortcutsDefaultsController: NSUserDefaultsController

  private func migrateDefaults() {
    if (self.shortcutsUserDefaults?.integer(forKey: defaultsVersionKey) ?? 0) == defaultsVersion {
      return
    }

    legacyDefaultShortcuts.keys.forEach { id in
      let shortcut: Shortcut?
      if let dict = self.shortcutsUserDefaults?.value(forKey: id) as? [String: Any] {
        shortcut = Shortcut(dictionary: dict)
      } else {
        shortcut = defaultShortcuts[id] ?? nil
      }

      let data = ValueTransformer
        .keyedUnarchiveFromDataTransformer
        .reverseTransformedValue(shortcut) as? NSData
      self.shortcutsUserDefaults?.set(data, forKey: id)
    }

    self.shortcutsUserDefaults?.set(defaultsVersion, forKey: defaultsVersionKey)
  }

  private func initShortcutUserDefaults() {
    let transformer = ValueTransformer(forName: .keyedUnarchiveFromDataTransformerName)!
    defaultShortcuts.forEach { id, shortcut in
      if self.shortcutsUserDefaults?.value(forKey: id) == nil {
        let shortcutData = transformer.reverseTransformedValue(shortcut) as? NSData
        self.shortcutsUserDefaults?.set(shortcutData, forKey: id)
      }
    }
    self.shortcutsUserDefaults?.set(defaultsVersion, forKey: defaultsVersionKey)
  }

  private func initOutlineViewBindings() {
    self.treeController.childrenKeyPath = "children"
    self.treeController.leafKeyPath = "isLeaf"
    self.treeController.countKeyPath = "childrenCount"
    self.treeController.objectClass = ShortcutItem.self
    self.treeController.avoidsEmptySelection = false
    self.treeController.preservesSelection = true
    self.treeController.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
    self.treeController.bind(.contentArray, to: self, withKeyPath: "content")
    self.shortcutList.bind(.content, to: self.treeController, withKeyPath: "arrangedObjects")
    self.shortcutList.bind(
      .selectionIndexPaths,
      to: self.treeController,
      withKeyPath: "selectionIndexPaths"
    )
  }

  private func traverseMenuItems(with fn: (String, NSMenuItem) -> Void) {
    var queue = self.shortcutItemsRoot.children ?? []
    while (!queue.isEmpty) {
      guard let item = queue.popLast() else { break }
      if item.isContainer, let children = item.children {
        queue.append(contentsOf: children)
        continue
      }

      guard let menuItem = item.item, let identifier = item.identifier else { continue }

      fn(identifier, menuItem)
    }
  }

  private func initMenuItemsBindings() {
    self.traverseMenuItems { identifier, menuItem in
      menuItem.bind(
        NSBindingName("keyEquivalent"),
        to: self.shortcutsDefaultsController,
        withKeyPath: "values.\(identifier)",
        options: [.valueTransformer: self.keyEqTransformer]
      )
      menuItem.bind(
        NSBindingName("keyEquivalentModifierMask"),
        to: self.shortcutsDefaultsController,
        withKeyPath: "values.\(identifier)",
        options: [.valueTransformer: self.keyEqModTransformer]
      )
    }
  }

  private func initShortcutItems() {
    guard let mainMenu = NSApplication.shared.mainMenu else { return }
    let firstLevel = mainMenu.items
      .suffix(from: 1)
      .filter { $0.identifier != debugMenuItemIdentifier }

    var queue = firstLevel.map {
      (
        parent: self.shortcutItemsRoot,
        shortcutItem: ShortcutItem(title: $0.title, isLeaf: false, item: $0)
      )
    }
    while (!queue.isEmpty) {
      guard let entry = queue.popLast() else { break }

      if !entry.shortcutItem.isLeaf
         || entry.shortcutItem.identifier?.hasPrefix("com.qvacua.vimr.menuitems.") == true {

        entry.parent.children?.append(entry.shortcutItem)
      }

      if entry.shortcutItem.isContainer,
         let childMenuItems = entry.shortcutItem.item?.submenu?.items {

        let shortcutChildItems = childMenuItems
          .filter { !$0.title.isEmpty }
          .map { menuItem in
            (
              parent: entry.shortcutItem,
              shortcutItem: ShortcutItem(
                title: menuItem.title,
                isLeaf: !menuItem.hasSubmenu,
                item: menuItem
              )
            )
          }
        queue.append(contentsOf: shortcutChildItems)
      }
    }
  }

  private func addViews() {
    let paneTitle = self.paneTitleTextField(title: "Shortcuts")

    let shortcutList = self.shortcutList
    shortcutList.delegate = self

    let shortcutScrollView = self.shortcutScrollView
    shortcutScrollView.documentView = shortcutList

    let reset = self.resetButton
    reset.title = "Reset All to Default"
    reset.bezelStyle = .rounded
    reset.isBordered = true
    reset.setButtonType(.momentaryPushIn)
    reset.target = self
    reset.action = #selector(ShortcutsPref.resetToDefault)

    self.addSubview(paneTitle)
    self.addSubview(shortcutScrollView)
    self.addSubview(reset)

    paneTitle.autoPinEdge(toSuperviewEdge: .top, withInset: 18)
    paneTitle.autoPinEdge(toSuperviewEdge: .left, withInset: 18)
    paneTitle.autoPinEdge(toSuperviewEdge: .right, withInset: 18, relation: .greaterThanOrEqual)

    shortcutScrollView.autoPinEdge(.top, to: .bottom, of: paneTitle, withOffset: 18)
    shortcutScrollView.autoPinEdge(.left, to: .left, of: paneTitle)
    shortcutScrollView.autoPinEdge(toSuperviewEdge: .right, withInset: 18)

    reset.autoPinEdge(.left, to: .left, of: paneTitle)
    reset.autoPinEdge(.top, to: .bottom, of: shortcutScrollView, withOffset: 18)
    reset.autoPinEdge(toSuperviewEdge: .bottom, withInset: 18)
  }
}

// MARK: - Actions
extension ShortcutsPref {

  @objc func resetToDefault(_ sender: NSButton) {
    guard let window = self.window else { return }

    let alert = NSAlert()
    alert.addButton(withTitle: "Cancel")
    alert.addButton(withTitle: "Reset")

    alert.messageText = "Do you want to reset all shortcuts to their default values?"
    alert.alertStyle = .warning
    alert.beginSheetModal(for: window, completionHandler: { response in
      guard response == .alertSecondButtonReturn else { return }
      self.traverseMenuItems { identifier, _ in
        let shortcut = defaultShortcuts[identifier] ?? Shortcut(keyEquivalent: "")
        let valueToWrite = ValueTransformer
          .keyedUnarchiveFromDataTransformer
          .reverseTransformedValue(shortcut)

        self.shortcutsDefaultsController.setValue(valueToWrite, forKeyPath: "values.\(identifier)")
        self.treeController.rearrangeObjects()
      }
    })
  }
}

// MARK: - NSOutlineViewDelegate
extension ShortcutsPref {

  private func isUppercase(_ str: String) -> Bool {
    for c in str.unicodeScalars {
      if !CharacterSet.uppercaseLetters.contains(c) { return false }
    }

    return true
  }

  func outlineView(_ outlineView: NSOutlineView, rowViewForItem item: Any) -> NSTableRowView? {
    let view = self.shortcutList.makeView(
      withIdentifier: NSUserInterfaceItemIdentifier("shortcut-row-view"),
      owner: self
    ) as? ShortcutTableRow ?? ShortcutTableRow(withIdentifier: "shortcut-row-view")

    return view
  }

  func outlineView(_: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
    let cellView = self.shortcutList.makeView(
      withIdentifier: NSUserInterfaceItemIdentifier("shortcut-cell-view"),
      owner: self
    ) as? ShortcutTableCell ?? ShortcutTableCell(withIdentifier: "shortcut-cell-view")

    let repObj = (item as? NSTreeNode)?.representedObject
    guard let item = repObj as? ShortcutItem else { return nil }
    guard let identifier = item.identifier else { return cellView }

    cellView.isDir = !item.isLeaf
    cellView.text = item.title

    if item.isContainer {
      cellView.customized = false
      cellView.layoutViews()
      return cellView
    }

    cellView.customized = !self.areShortcutsEqual(identifier)
    cellView.layoutViews()
    cellView.setDelegateOfRecorder(self)
    cellView.bindRecorder(toKeyPath: "values.\(identifier)", to: self.shortcutsDefaultsController)

    return cellView
  }

  func outlineView(_: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat { 28 }

  private func areShortcutsEqual(_ identifier: String) -> Bool {
    guard let dataFromDefaults = self.shortcutsDefaultsController.value(
      forKeyPath: "values.\(identifier)"
    ) as? NSData else { return true }

    guard let shortcutFromDefaults = ValueTransformer
      .keyedUnarchiveFromDataTransformer
      .transformedValue(dataFromDefaults) as? Shortcut else { return true }

    let defaultShortcut = defaultShortcuts[identifier] ?? nil

    return shortcutFromDefaults.isEqual(to: defaultShortcut) == true
  }
}

// MARK: - SRRecorderControlDelegate
extension ShortcutsPref {

  func recorderControlDidEndRecording(_ sender: RecorderControl) {
    self.treeController.rearrangeObjects()
  }
}

private let defaultsVersionKey = "version"
private let defaultsVersion = 337

private class DataToKeyEquivalentTransformer: ValueTransformer {

  override func transformedValue(_ value: Any?) -> Any? {
    guard let shortcut = ValueTransformer
      .keyedUnarchiveFromDataTransformer
      .transformedValue(value) as? Shortcut else { return "" }

    return KeyEquivalentTransformer.shared.transformedValue(shortcut)
  }
}

private class DataToKeyEquivalentModifierMaskTransformer: ValueTransformer {

  override func transformedValue(_ value: Any?) -> Any? {
    guard let shortcut = ValueTransformer
      .keyedUnarchiveFromDataTransformer
      .transformedValue(value) as? Shortcut else { return NSNumber(value: 0) }

    return KeyEquivalentModifierMaskTransformer.shared.transformedValue(shortcut)
  }
}
