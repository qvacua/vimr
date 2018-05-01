/**
 * Greg Omelaenko - http://omelaen.co
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import NvimMsgPack
import RxSwift

@available(OSX 10.12.2, *)
extension NvimView: NSTouchBarDelegate, NSScrubberDataSource, NSScrubberDelegate {

  override public func makeTouchBar() -> NSTouchBar? {
    let bar = NSTouchBar()
    bar.delegate = self
    bar.customizationIdentifier = touchBarIdentifier
    bar.defaultItemIdentifiers = [touchBarTabSwitcherIdentifier]
    bar.customizationRequiredItemIdentifiers = [touchBarTabSwitcherIdentifier]

    return bar
  }

  public func touchBar(_ touchBar: NSTouchBar,
                       makeItemForIdentifier identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {

    switch identifier {

    case touchBarTabSwitcherIdentifier:
      let item = NSCustomTouchBarItem(identifier: identifier)
      item.customizationLabel = "Tab Switcher"
      let tabsControl = NSScrubber()
      tabsControl.register(NSScrubberTextItemView.self,
                           forItemIdentifier: NSUserInterfaceItemIdentifier(touchBarTabSwitcherItem))
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
    return tabsCache.index { $0.isCurrent } ?? -1
  }

  private func getTabsControl() -> NSScrubber? {
    let item = self.touchBar?.item(forIdentifier: touchBarTabSwitcherIdentifier) as? NSCustomTouchBarItem
    return item?.view as? NSScrubber
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
      }, onError: { error in
        self.eventsSubject.onNext(.apiError(error: error, msg: "Could not get all tabpages."))
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
      }, onError: { error in
        self.eventsSubject.onNext(.apiError(error: error, msg: "Could not get all tabpages."))
      })
  }

  public func numberOfItems(for scrubber: NSScrubber) -> Int {
    return tabsCache.count
  }

  public func scrubber(_ scrubber: NSScrubber, viewForItemAt index: Int) -> NSScrubberItemView {
    let item = scrubber.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(touchBarTabSwitcherItem), owner: nil)
    guard let itemView = item as? NSScrubberTextItemView else {
      return NSScrubberTextItemView()
    }

    guard tabsCache.count > index else {
      return itemView
    }

    let tab = self.tabsCache[index]
    itemView.title = tab.currentWindow?.buffer.name ?? "[No Name]"

    return itemView
  }

  public func scrubber(_ scrubber: NSScrubber, didSelectItemAt selectedIndex: Int) {
    let tab = self.tabsCache[selectedIndex]
    guard tab.windows.count > 0 else {
      return
    }

    let window = tab.currentWindow ?? tab.windows[0]
    self.nvim
      .setCurrentWin(window: NvimApi.Window(window.handle), expectsReturnValue: false)
      .subscribeOn(self.nvimApiScheduler)
      .subscribe(onError: { error in
        self.eventsSubject.onNext(.apiError(error: error, msg: "Could not set current window to \(window.handle)."))
      })
  }
}

@available(OSX 10.12.2, *)
private let touchBarIdentifier = NSTouchBar.CustomizationIdentifier("com.qvacua.VimR.NvimView.touchBar")

@available(OSX 10.12.2, *)
private let touchBarTabSwitcherIdentifier = NSTouchBarItem.Identifier("com.qvacua.VimR.NvimView.touchBar.tabSwitcher")

@available(OSX 10.12.2, *)
private let touchBarTabSwitcherItem = "com.qvacua.VimR.NvimView.touchBar.tabSwitcher.item"
