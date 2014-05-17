/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import "VRFileBrowserView.h"
#import "VRUtils.h"
#import "VRFileItemManager.h"
#import "VRMainWindowController.h"
#import "VRUserDefaults.h"
#import "VRInvalidateCacheOperation.h"


#define CONSTRAIN(fmt, ...) [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat: fmt, ##__VA_ARGS__] options:0 metrics:nil views:views]];



@implementation VRFileBrowserView {
  NSOutlineView *_fileOutlineView;
  NSScrollView *_scrollView;
  NSPopUpButton *_settingsButton;
  BOOL _showHidden;
}

#pragma mark Public
- (void)setRootUrl:(NSURL *)rootUrl {
  _rootUrl = rootUrl;
  [_fileOutlineView reloadData];
  [_fileOutlineView selectRowIndexes:nil byExtendingSelection:NO];
}

- (instancetype)initWithRootUrl:(NSURL *)rootUrl {
  self = [super initWithFrame:CGRectZero];
  RETURN_NIL_WHEN_NOT_SELF

  _rootUrl = rootUrl;

  [self addViews];

  return self;
}

- (void)dealloc {
 [_notificationCenter removeObserver:self];
}

- (void)setUp {
  _showHidden = [_userDefaults boolForKey:qDefaultShowHiddenInFileBrowser];

  [_notificationCenter addObserver:self selector:@selector(cacheInvalidated:) name:qInvalidatedCacheEvent
                            object:nil];

  [_fileOutlineView reloadData];
}

#pragma mark NSOutlineViewDataSource
- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
  if (!item) {
    NSArray *children = [self filterOutHiddenFromItems:[_fileItemManager childrenOfRootUrl:_rootUrl]];
    return children.count;
  }

  NSArray *children = [self filterOutHiddenFromItems:[_fileItemManager childrenOfItem:item]];
  return children.count;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
  if (!item) {
    NSArray *children = [self filterOutHiddenFromItems:[_fileItemManager childrenOfRootUrl:_rootUrl]];
    return children[(NSUInteger) index];
  }

  return [[self filterOutHiddenFromItems:[_fileItemManager childrenOfItem:item]] objectAtIndex:(NSUInteger) index];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
  return [_fileItemManager isItemDir:item];
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn
           byItem:(id)item {

  return [_fileItemManager nameOfItem:item];
}

#pragma mark NSOutlineViewDelegate


#pragma mark NSView
- (BOOL)mouseDownCanMoveWindow {
  // I dunno why, but if we don't override this, then the window title has the inactive appearance and the drag in the
  // VRWorkspaceView in combination with the vim view does not work correctly. Overriding -isOpaque does not suffice.
  return NO;
}

#pragma mark Private
- (void)addViews {
  NSTableColumn *tableColumn = [[NSTableColumn alloc] initWithIdentifier:@"name"];
  tableColumn.dataCell = [[NSTextFieldCell alloc] initTextCell:@""];
  [tableColumn.dataCell setFont:[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSSmallControlSize]]];
  [tableColumn.dataCell setLineBreakMode:NSLineBreakByTruncatingTail];

  _fileOutlineView = [[NSOutlineView alloc] initWithFrame:CGRectZero];
  [_fileOutlineView addTableColumn:tableColumn];
  _fileOutlineView.outlineTableColumn = tableColumn;
  [_fileOutlineView sizeLastColumnToFit];
  _fileOutlineView.allowsEmptySelection = YES;
  _fileOutlineView.allowsMultipleSelection = NO;
  _fileOutlineView.headerView = nil;
  _fileOutlineView.focusRingType = NSFocusRingTypeNone;
  _fileOutlineView.dataSource = self;
  _fileOutlineView.delegate = self;
  [_fileOutlineView setDoubleAction:@selector(fileOutlineViewDoubleClicked:)];

  _scrollView = [[NSScrollView alloc] initWithFrame:NSZeroRect];
  _scrollView.translatesAutoresizingMaskIntoConstraints = NO;
  _scrollView.hasVerticalScroller = YES;
  _scrollView.hasHorizontalScroller = YES;
  _scrollView.borderType = NSBezelBorder;
  _scrollView.autohidesScrollers = YES;
  _scrollView.documentView = _fileOutlineView;
  [self addSubview:_scrollView];

  _settingsButton = [[NSPopUpButton alloc] initWithFrame:CGRectZero];
  _settingsButton.translatesAutoresizingMaskIntoConstraints = NO;
  _settingsButton.bordered = NO;
  _settingsButton.pullsDown = YES;

  NSMenuItem *item = [NSMenuItem new];
  item.title = @"";
  item.image = [NSImage imageNamed:NSImageNameActionTemplate];
  [item.image setSize:NSMakeSize(12, 12)];
  [_settingsButton.cell setBackgroundStyle:NSBackgroundStyleRaised];
  [_settingsButton.cell setUsesItemFromMenu:NO];
  [_settingsButton.cell setMenuItem:item];
  [self addSubview:_settingsButton];

  NSDictionary *views = @{
      @"outline" : _scrollView,
      @"settings" : _settingsButton,
  };

  CONSTRAIN(@"H:[settings]|");
  CONSTRAIN(@"H:|-(-1)-[outline(>=50)]-(-1)-|");
  CONSTRAIN(@"V:|-(-1)-[outline(>=50)][settings]-(3)-|");
}

- (void)fileOutlineViewDoubleClicked:(id)sender {
  id clickedItem = [_fileOutlineView itemAtRow:_fileOutlineView.clickedRow];

  if (![_fileItemManager isItemDir:clickedItem]) {
    [(VRMainWindowController *) self.window.windowController openFileWithUrl:[_fileItemManager urlForItem:clickedItem]];
    return;
  }

  if ([_fileOutlineView isItemExpanded:clickedItem]) {
    [_fileOutlineView collapseItem:clickedItem];
  } else {
    [_fileOutlineView expandItem:clickedItem];
  }
}

- (NSArray *)filterOutHiddenFromItems:(NSArray *)items {
  if (_showHidden) {
    return items;
  }

  NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:items.count];
  for (id item in items) {
    if(![_fileItemManager isItemHidden:item]) {
      [result addObject:item];
    }
  }

  return result;
}

- (void)cacheInvalidated:(NSNotification *)notification {
  [_fileOutlineView reloadData];
}

@end
