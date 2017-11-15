/**
 * Greg Omelaenko - http://omelaen.co
 * See LICENSE
 */

import Cocoa

@available(OSX 10.12.2, *)
extension NeoVimView : NSTouchBarDelegate, NSScrubberDataSource, NSScrubberDelegate {

  private static let touchBarIdentifier = NSTouchBar.CustomizationIdentifier("com.qvacua.VimR.SwiftNeoVim.touchBar")
  private static let touchBarTabSwitcherIdentifier = NSTouchBarItem.Identifier("com.qvacua.VimR.SwiftNeoVim.touchBar.tabSwitcher")
  private static let touchBarTabSwitcherItem = "com.qvacua.VimR.SwiftNeoVim.touchBar.tabSwitcher.item"

  override public func makeTouchBar() -> NSTouchBar? {
    let bar = NSTouchBar()
    bar.delegate = self
    bar.customizationIdentifier = NeoVimView.touchBarIdentifier
    bar.defaultItemIdentifiers = [NeoVimView.touchBarTabSwitcherIdentifier]
    bar.customizationRequiredItemIdentifiers = [NeoVimView.touchBarTabSwitcherIdentifier]
    return bar
  }

  public func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
    switch identifier {
    case NeoVimView.touchBarTabSwitcherIdentifier:
      let item = NSCustomTouchBarItem(identifier: identifier)
      item.customizationLabel = "Tab Switcher"
      let tabsControl = NSScrubber()
      tabsControl.register(NSScrubberTextItemView.self, forItemIdentifier: NSUserInterfaceItemIdentifier(rawValue: NeoVimView.touchBarTabSwitcherItem))
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
    return (self.touchBar?.item(forIdentifier: NeoVimView.touchBarTabSwitcherIdentifier) as? NSCustomTouchBarItem)?.view as? NSScrubber
  }

  func updateTouchBarCurrentBuffer() {
    guard let tabsControl = getTabsControl() else { return }
    tabsCache = self.agent.tabs()
    tabsControl.reloadData()
    (tabsControl.scrubberLayout as! NSScrubberProportionalLayout).numberOfVisibleItems = tabsControl.numberOfItems > 0 ? tabsControl.numberOfItems : 1
    tabsControl.selectedIndex = selectedTabIndex()
  }

  func updateTouchBarTab() {
    guard let tabsControl = getTabsControl() else { return }
    tabsCache = self.agent.tabs()
    tabsControl.reloadData()
    tabsControl.selectedIndex = selectedTabIndex()
  }

  public func numberOfItems(for scrubber: NSScrubber) -> Int {
    return tabsCache.count
  }

  public func scrubber(_ scrubber: NSScrubber, viewForItemAt index: Int) -> NSScrubberItemView {
    let itemView = scrubber.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: type(of: self).touchBarTabSwitcherItem), owner: nil) as! NSScrubberTextItemView
    guard tabsCache.count > index else { return itemView }
    let tab = tabsCache[index]
    itemView.title = tab.currentWindow()?.buffer.name ?? "[No Name]"

    return itemView
  }

  public func scrubber(_ scrubber: NSScrubber, didSelectItemAt selectedIndex: Int) {
    let tab = tabsCache[selectedIndex]
    guard tab.windows.count > 0 else { return }
    self.agent.select(tab.currentWindow() ?? tab.windows[0])
  }

}
