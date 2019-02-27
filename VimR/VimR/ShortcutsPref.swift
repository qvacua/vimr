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
                     NSOutlineViewDelegate {

  typealias StateType = AppState

  enum Action {

    case dummy
  }

  @objc dynamic var content = [ShortcutItem]()

  override var displayName: String {
    return "Shortcuts"
  }

  override var pinToContainer: Bool {
    return true
  }

  required init(
    source: Observable<StateType>,
    emitter: ActionEmitter,
    state: StateType
  ) {
    self.emit = emitter.typedEmit()

    super.init(frame: .zero)

    self.addViews()
    self.updateViews()

    self.initShortcutItems()
    if let children = self.shortcutItemsRoot.children {
      self.content.append(contentsOf: children)
    }
    self.initMenuItemsBindings()

    source
      .observeOn(MainScheduler.instance)
      .subscribe(onNext: { state in
      })
      .disposed(by: self.disposeBag)

    self.initOutlineViewBindings()
    self.shortcutList.expandItem(nil, expandChildren: true)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private let emit: (Action) -> Void
  private let disposeBag = DisposeBag()

  private let shortcutList = NSOutlineView.standardOutlineView()
  private let shortcutScrollView = NSScrollView.standardScrollView()
  private let resetButton = NSButton(forAutoLayout: ())

  private let treeController = NSTreeController()
  private let shortcutItemsRoot = ShortcutItem(
    title: "root", isLeaf: false, item: nil
  )

  private let keyEqTransformer = SRKeyEquivalentTransformer()
  private let keyEqModTransformer = SRKeyEquivalentModifierMaskTransformer()

  private let shortcutsDefaultsController = NSUserDefaultsController(
    defaults: UserDefaults(suiteName: "com.qvacua.VimR.menuitems"),
    initialValues: defaultShortcuts
  )

  private func initOutlineViewBindings() {
    self.treeController.childrenKeyPath = "children"
    self.treeController.leafKeyPath = "isLeaf"
    self.treeController.countKeyPath = "childrenCount"
    self.treeController.objectClass = ShortcutItem.self
    self.treeController.avoidsEmptySelection = false
    self.treeController.preservesSelection = true
    self.treeController.sortDescriptors = [
      NSSortDescriptor(key: "title", ascending: true)
    ]
    self.treeController.bind(.contentArray, to: self, withKeyPath: "content")
    self.shortcutList.bind(.content,
                           to: self.treeController,
                           withKeyPath: "arrangedObjects")
    self.shortcutList.bind(.selectionIndexPaths,
                           to: self.treeController,
                           withKeyPath: "selectionIndexPaths")
  }

  private func initMenuItemsBindings() {
    var queue = self.shortcutItemsRoot.children ?? []
    while (!queue.isEmpty) {
      guard let item = queue.popLast() else { break }
      if item.isContainer, let children = item.children {
        queue.append(contentsOf: children)
        continue
      }

      guard let menuItem = item.item, let identifier = item.identifier else {
        continue
      }

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
         || entry.shortcutItem
              .identifier?
              .hasPrefix("com.qvacua.vimr.menuitems.") == true {

        entry.parent.children?.append(entry.shortcutItem)
      }

      if entry.shortcutItem.isContainer,
         let childMenuItems = entry.shortcutItem.item?.submenu?.items {

        let shortcutChildItems = childMenuItems
          .filter { !$0.title.isEmpty }
          .map { menuItem in
            (
              parent: entry.shortcutItem,
              shortcutItem: ShortcutItem(title: menuItem.title,
                                         isLeaf: !menuItem.hasSubmenu,
                                         item: menuItem)
            )
          }
        queue.append(contentsOf: shortcutChildItems)
      }
    }
  }

  private func updateViews() {
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
    paneTitle.autoPinEdge(
      toSuperviewEdge: .right, withInset: 18, relation: .greaterThanOrEqual
    )

    shortcutScrollView.autoPinEdge(
      .top, to: .bottom, of: paneTitle, withOffset: 18
    )
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
    stdoutLog.debug("Reset to default!")
    stdoutLog.debug(
      self.shortcutsDefaultsController.defaults
        .dictionaryRepresentation()["com.qvacua.vimr.menuitems.edit.copy"]
    )
  }
}

// MARK: - NSOutlineViewDelegate
extension ShortcutsPref {

  private func isUppercase(_ str: String) -> Bool {
    for c in str.unicodeScalars {
      if !CharacterSet.uppercaseLetters.contains(c) {
        return false
      }
    }

    return true
  }

  func outlineView(
    _ outlineView: NSOutlineView,
    rowViewForItem item: Any
  ) -> NSTableRowView? {
    let view = self.shortcutList.makeView(
      withIdentifier: NSUserInterfaceItemIdentifier("shortcut-row-view"),
      owner: self
    ) as? ShortcutTableRow
               ?? ShortcutTableRow(withIdentifier: "shortcut-row-view")

    return view
  }

  func outlineView(
    _: NSOutlineView,
    viewFor tableColumn: NSTableColumn?,
    item: Any
  ) -> NSView? {
    let cellView = self.shortcutList.makeView(
      withIdentifier: NSUserInterfaceItemIdentifier("shortcut-cell-view"),
      owner: self
    ) as? ShortcutTableCell
                   ?? ShortcutTableCell(withIdentifier: "shortcut-cell-view")

    let repObj = (item as? NSTreeNode)?.representedObject
    guard let item = repObj as? ShortcutItem else {
      return nil
    }

    cellView.isDir = !item.isLeaf
    cellView.text = item.title

    guard let identifier = item.identifier else { return cellView }
    cellView.bindRecorder(toKeyPath: "values.\(identifier)",
                          to: self.shortcutsDefaultsController)

    return cellView
  }

  func outlineView(_: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat {
    return 28
  }
}
