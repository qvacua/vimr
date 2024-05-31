/**
 * Greg Omelaenko - http://omelaen.co
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import RxNeovim
import RxPack
import RxSwift

extension NvimView: NSTouchBarDelegate, NSScrubberDataSource, NSScrubberDelegate {
  override public func makeTouchBar() -> NSTouchBar? {
    let bar = NSTouchBar()
    bar.delegate = self
    bar.customizationIdentifier = touchBarIdentifier
    bar.defaultItemIdentifiers = [touchBarTabSwitcherIdentifier]
    bar.customizationRequiredItemIdentifiers = [touchBarTabSwitcherIdentifier]

    return bar
  }

  public func touchBar(
    _: NSTouchBar,
    makeItemForIdentifier identifier: NSTouchBarItem.Identifier
  ) -> NSTouchBarItem? {
    switch identifier {
    case touchBarTabSwitcherIdentifier:
      let item = NSCustomTouchBarItem(identifier: identifier)
      item.customizationLabel = "Tab Switcher"
      let tabsControl = NSScrubber()
      tabsControl.register(
        NSScrubberTextItemView.self,
        forItemIdentifier: NSUserInterfaceItemIdentifier(touchBarTabSwitcherItem)
      )
      tabsControl.mode = .fixed
      tabsControl.dataSource = self
      tabsControl.delegate = self
      tabsControl.selectionOverlayStyle = .outlineOverlay
      tabsControl.selectedIndex = self.selectedTabIndex()

      let layout = NSScrubberProportionalLayout()
      layout.numberOfVisibleItems = 1
      tabsControl.scrubberLayout = layout
      item.view = tabsControl

      return item

    default:
      return nil
    }
  }

  private func selectedTabIndex() -> Int { tabsCache.firstIndex { $0.isCurrent } ?? -1 }

  private func getTabsControl() -> NSScrubber? {
    let item = self
      .touchBar?
      .item(forIdentifier: touchBarTabSwitcherIdentifier) as? NSCustomTouchBarItem
    return item?.view as? NSScrubber
  }

  func updateTouchBarCurrentBuffer() {
    self
      .allTabs()
      .observe(on: MainScheduler.instance)
      .subscribe(onSuccess: { [weak self] in
        self?.tabsCache = $0

        guard let tabsControl = self?.getTabsControl() else { return }

        tabsControl.reloadData()

        let scrubberProportionalLayout = tabsControl.scrubberLayout as! NSScrubberProportionalLayout
        scrubberProportionalLayout.numberOfVisibleItems = tabsControl
          .numberOfItems > 0 ? tabsControl.numberOfItems : 1
        tabsControl.selectedIndex = self?.selectedTabIndex() ?? tabsControl.selectedIndex
      }, onFailure: { [weak self] error in
        self?.eventsSubject.onNext(.apiError(msg: "Could not get all tabpages.", cause: error))
      })
      .disposed(by: self.disposeBag)
  }

  func updateTouchBarTab() {
    self
      .allTabs()
      .observe(on: MainScheduler.instance)
      .subscribe(onSuccess: { [weak self] in
        self?.tabsCache = $0

        guard let tabsControl = self?.getTabsControl() else { return }

        tabsControl.reloadData()
        tabsControl.selectedIndex = self?.selectedTabIndex() ?? tabsControl.selectedIndex
      }, onFailure: { error in
        self.eventsSubject.onNext(.apiError(msg: "Could not get all tabpages.", cause: error))
      })
      .disposed(by: self.disposeBag)
  }

  public func numberOfItems(for _: NSScrubber) -> Int { tabsCache.count }

  public func scrubber(_ scrubber: NSScrubber, viewForItemAt index: Int) -> NSScrubberItemView {
    let item = scrubber.makeItem(
      withIdentifier: NSUserInterfaceItemIdentifier(touchBarTabSwitcherItem),
      owner: nil
    )
    guard let itemView = item as? NSScrubberTextItemView else { return NSScrubberTextItemView() }

    guard tabsCache.count > index else { return itemView }

    let tab = self.tabsCache[index]
    itemView.title = tab.currentWindow?.buffer.name ?? "[No Name]"

    return itemView
  }

  public func scrubber(_: NSScrubber, didSelectItemAt selectedIndex: Int) {
    let tab = self.tabsCache[selectedIndex]
    guard tab.windows.count > 0 else { return }

    let window = tab.currentWindow ?? tab.windows[0]
    self.api
      .nvimSetCurrentWin(window: RxNeovimApi.Window(window.handle))
      .subscribe(on: self.scheduler)
      .subscribe(onError: { [weak self] error in
        self?.eventsSubject
          .onNext(.apiError(msg: "Could not set current window to \(window.handle).", cause: error))
      })
      .disposed(by: self.disposeBag)
  }
}

private let touchBarIdentifier = NSTouchBar
  .CustomizationIdentifier("com.qvacua.VimR.NvimView.touchBar")

private let touchBarTabSwitcherIdentifier = NSTouchBarItem
  .Identifier("com.qvacua.VimR.NvimView.touchBar.tabSwitcher")

private let touchBarTabSwitcherItem = "com.qvacua.VimR.NvimView.touchBar.tabSwitcher.item"
