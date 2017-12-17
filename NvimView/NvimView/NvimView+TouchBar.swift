/**
 * Greg Omelaenko - http://omelaen.co
 * See LICENSE
 */

import Cocoa
import NvimMsgPack

@available(OSX 10.12.2, *)
extension NvimView: NSTouchBarDelegate, NSScrubberDataSource, NSScrubberDelegate {

  private static let touchBarIdentifier = NSTouchBar.CustomizationIdentifier("com.qvacua.VimR.SwiftNeoVim.touchBar")
  private static let touchBarTabSwitcherIdentifier = NSTouchBarItem.Identifier("com.qvacua.VimR.SwiftNeoVim.touchBar.tabSwitcher")
  private static let touchBarTabSwitcherItem = "com.qvacua.VimR.SwiftNeoVim.touchBar.tabSwitcher.item"

  override public func makeTouchBar() -> NSTouchBar? {
    let bar = NSTouchBar()
    bar.delegate = self
    bar.customizationIdentifier = NvimView.touchBarIdentifier
    bar.defaultItemIdentifiers = [NvimView.touchBarTabSwitcherIdentifier]
    bar.customizationRequiredItemIdentifiers = [NvimView.touchBarTabSwitcherIdentifier]
    return bar
  }

  public func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
    switch identifier {
    case NvimView.touchBarTabSwitcherIdentifier:
      let item = NSCustomTouchBarItem(identifier: identifier)
      item.customizationLabel = "Tab Switcher"
      let tabsControl = NSScrubber()
      tabsControl.register(NSScrubberTextItemView.self, forItemIdentifier: NSUserInterfaceItemIdentifier(rawValue: NvimView.touchBarTabSwitcherItem))
      tabsControl.mode = .fixed
      tabsControl.dataSource = self
      tabsControl.delegate = self
      tabsControl.selectionOverlayStyle = .outlineOverlay
      tabsControl.selectedIndex = selectedTabIndex()
      let layout = NSScrubberProportionalLayout()
      layout.numberOfVisibleItems = 1
      tabsControl.scrubberLayout = layout
      item.view = tabsControl
      return item
    default:
      return nil
    }
  }

  private func selectedTabIndex() -> Int {
    return tabsCache.index(where: { $0.isCurrent }) ?? -1
  }

  private func getTabsControl() -> NSScrubber? {
    return (self.touchBar?.item(forIdentifier: NvimView.touchBarTabSwitcherIdentifier) as? NSCustomTouchBarItem)?.view
    as? NSScrubber
  }

  func updateTouchBarCurrentBuffer() {
    self
      .allTabs()
      .observeOn(MainScheduler.instance)
      .subscribe(onSuccess: {
        self.tabsCache = $0

        guard let tabsControl = self.getTabsControl() else {
          return
        }

        tabsControl.reloadData()
        let scrubberProportionalLayout = tabsControl.scrubberLayout as! NSScrubberProportionalLayout
        scrubberProportionalLayout.numberOfVisibleItems = tabsControl.numberOfItems > 0 ? tabsControl.numberOfItems : 1
        tabsControl.selectedIndex = self.selectedTabIndex()
      })
  }

  func updateTouchBarTab() {
    self
      .allTabs()
      .observeOn(MainScheduler.instance)
      .subscribe(onSuccess: {
        self.tabsCache = $0

        guard let tabsControl = self.getTabsControl() else {
          return
        }

        tabsControl.reloadData()
        tabsControl.selectedIndex = self.selectedTabIndex()
      })
  }

  public func numberOfItems(for scrubber: NSScrubber) -> Int {
    return tabsCache.count
  }

  public func scrubber(_ scrubber: NSScrubber, viewForItemAt index: Int) -> NSScrubberItemView {
    let itemView = scrubber.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: type(of: self).touchBarTabSwitcherItem), owner: nil) as! NSScrubberTextItemView
    guard tabsCache.count > index else { return itemView }
    let tab = tabsCache[index]
    itemView.title = tab.currentWindow?.buffer.name ?? "[No Name]"

    return itemView
  }

  public func scrubber(_ scrubber: NSScrubber, didSelectItemAt selectedIndex: Int) {
    let tab = tabsCache[selectedIndex]
    guard tab.windows.count > 0 else {
      return
    }

    let window = tab.currentWindow ?? tab.windows[0]
    self.nvim.setCurrentWin(window: NvimApi.Window(window.handle), expectsReturnValue: false)
  }
}
