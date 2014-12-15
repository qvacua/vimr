/**
* Tae Won Ha — @hataewon
*
* http://taewon.de
* http://qvacua.com
*
* See LICENSE
*/

#import "VRPrefWindow.h"
#import "VRUtils.h"
#import "VRGeneralPrefPane.h"
#import "VRFileBrowserPrefPane.h"


NSString *const qPrefWindowFrameAutosaveName = @"pref-window-frame-autosave";


static const int qWindowStyleMask = NSTitledWindowMask | NSResizableWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask;


#define CONSTRAIN(fmt) [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:fmt options:0 metrics:nil views:views]];


@implementation VRPrefWindow {
  NSArray *_prefPanes;
  NSOutlineView *_categoryOutlineView;
  NSScrollView *_paneScrollView;
  NSScrollView *_categoryScrollView;
}

@autowire(userDefaultsController)
@autowire(fileManager)
@autowire(workspace)
@autowire(mainBundle)

#pragma mark NSWindow
- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag {
  self = [super initWithContentRect:contentRect styleMask:(NSUInteger) qWindowStyleMask backing:NSBackingStoreBuffered defer:YES];
  RETURN_NIL_WHEN_NOT_SELF

  self.title = @"Preferences";
  self.releasedWhenClosed = NO;
  [self setFrameAutosaveName:qPrefWindowFrameAutosaveName];

  return self;
}

#pragma mark TBInitializingBean
- (void)postConstruct {
  _prefPanes = @[
      [[VRGeneralPrefPane alloc] initWithUserDefaultsController:_userDefaultsController fileManager:_fileManager workspace:_workspace mainBundle:_mainBundle],
      [[VRFileBrowserPrefPane alloc] initWithUserDefaultsController:_userDefaultsController],
  ];

  for (NSView *prefPane in _prefPanes) {
    prefPane.translatesAutoresizingMaskIntoConstraints = NO;
  }

  [self addViews];
}

#pragma mark NSOutlineViewDelegate
- (void)outlineViewSelectionDidChange:(NSNotification *)notification {
  VRPrefPane *selectedPane = [_categoryOutlineView itemAtRow:_categoryOutlineView.selectedRow];

  _paneScrollView.documentView = selectedPane;

  // The first two or three times, the resizing does not work. When dispatching to the main thread, it works from the
  // start. Very odd...
  dispatch_to_main_thread(^{
    [self resizeWindowForPrefPane:selectedPane];
  });
}

#pragma mark NSOutlineViewDataSource
- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
  if (item == nil) {
    return _prefPanes[(NSUInteger) index];
  }

  return nil;
}
- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
  return _prefPanes.count;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(VRPrefPane *)pane {
  return pane.displayName;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
  return NO;
}

#pragma mark Private
- (void)addViews {
  NSTableColumn *tableColumn = [[NSTableColumn alloc] initWithIdentifier:@"name"];
  tableColumn.dataCell = [[NSTextFieldCell alloc] init];
  [tableColumn.dataCell setAllowsEditingTextAttributes:YES];
  [tableColumn.dataCell setLineBreakMode:NSLineBreakByTruncatingTail];

  _categoryOutlineView = [[NSOutlineView alloc] initWithFrame:CGRectZero];
  [_categoryOutlineView addTableColumn:tableColumn];
  _categoryOutlineView.outlineTableColumn = tableColumn;
  [_categoryOutlineView sizeLastColumnToFit];
  _categoryOutlineView.allowsEmptySelection = NO;
  _categoryOutlineView.allowsMultipleSelection = NO;
  _categoryOutlineView.headerView = nil;
  _categoryOutlineView.focusRingType = NSFocusRingTypeNone;
  _categoryOutlineView.dataSource = self;
  _categoryOutlineView.delegate = self;
  _categoryOutlineView.allowsMultipleSelection = NO;
  _categoryOutlineView.allowsEmptySelection = NO;

  _categoryScrollView = [[NSScrollView alloc] initWithFrame:CGRectZero];
  _categoryScrollView.translatesAutoresizingMaskIntoConstraints = NO;
  _categoryScrollView.hasVerticalScroller = YES;
  _categoryScrollView.hasHorizontalScroller = YES;
  _categoryScrollView.borderType = NSBezelBorder;
  _categoryScrollView.autohidesScrollers = YES;
  _categoryScrollView.documentView = _categoryOutlineView;
  _categoryScrollView.autohidesScrollers = YES;

  _paneScrollView = [[NSScrollView alloc] initWithFrame:CGRectZero];
  _paneScrollView.translatesAutoresizingMaskIntoConstraints = NO;
  _paneScrollView.hasVerticalScroller = YES;
  _paneScrollView.hasHorizontalScroller = YES;
  _paneScrollView.borderType = NSNoBorder;
  _paneScrollView.autohidesScrollers = YES;
  _paneScrollView.autoresizesSubviews = YES;
  _paneScrollView.documentView = _prefPanes[0];
  _paneScrollView.backgroundColor = [NSColor windowBackgroundColor];
  _paneScrollView.autohidesScrollers = YES;

  NSView *contentView = self.contentView;
  [contentView addSubview:_categoryScrollView];
  [contentView addSubview:_paneScrollView];

  NSDictionary *views = @{
      @"catView" : _categoryScrollView,
      @"paneView" : _paneScrollView,
  };

  CONSTRAIN(@"H:|-(-1)-[catView(150)][paneView(>=200)]|")
  CONSTRAIN(@"V:|-(-1)-[catView(>=150)]-(-1)-|")
  CONSTRAIN(@"V:|[paneView]|")

  // Why do we need this?
  dispatch_to_main_thread(^{
    [self resizeWindowForPrefPane:_prefPanes[0]];
  });
}

- (void)resizeWindowForPrefPane:(VRPrefPane *)selectedPane {
  CGRect paneRect = selectedPane.frame;
  CGFloat targetWidth = _categoryScrollView.frame.size.width - 1 + paneRect.size.width;
  CGFloat targetHeight = MAX(150, paneRect.size.height);
  CGSize newWinSize = [NSWindow frameRectForContentRect:CGRectMake(0, 0, targetWidth, targetHeight) styleMask:qWindowStyleMask].size;

  CGRect winFrame = self.frame;
  winFrame.origin.y += winFrame.size.height;
  winFrame.origin.y -= newWinSize.height;
  winFrame.size = newWinSize;

  [self setFrame:winFrame display:YES animate:YES];
}

@end
