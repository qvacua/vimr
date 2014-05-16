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


#define CONSTRAIN(fmt, ...) [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat: fmt, ##__VA_ARGS__] options:0 metrics:nil views:views]];


@implementation VRFileBrowserView {
  NSOutlineView *_fileOutlineView;
  NSScrollView *_scrollView;
}

#pragma mark Public
- (instancetype)initWithRootUrl:(NSURL *)rootUrl {
  self = [super initWithFrame:CGRectZero];
  RETURN_NIL_WHEN_NOT_SELF

  _rootUrl = rootUrl;
  [self addViews];

  return self;
}

#pragma mark NSOutlineViewDataSource
- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
  if (!item) {
    NSArray *children = [_fileItemManager childrenOfRootUrl:_rootUrl];
    return children.count;
  }

  NSArray *children = [_fileItemManager childrenOfItem:item];
  return children.count;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
  if (!item) {
    NSArray *children = [_fileItemManager childrenOfRootUrl:_rootUrl];
    return children[(NSUInteger) index];
  }

  return [[_fileItemManager childrenOfItem:item] objectAtIndex:(NSUInteger) index];
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
  // VRWorkspaceView in combination with the vim view does not work correctly. To override -isOpaque does not suffice.
  return NO;
}

#pragma mark Private
- (void)addViews {
  NSTableColumn *tableColumn = [[NSTableColumn alloc] initWithIdentifier:@"name"];
  tableColumn.dataCell = [[NSTextFieldCell alloc] initTextCell:@""];
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
  _scrollView.hasHorizontalScroller = NO;
  _scrollView.borderType = NSNoBorder;
  _scrollView.autohidesScrollers = YES;
  _scrollView.documentView = _fileOutlineView;
  [self addSubview:_scrollView];

  NSDictionary *views = @{
      @"outline" : _scrollView,
  };

  CONSTRAIN(@"H:|[outline(>=50)]|");
  CONSTRAIN(@"V:|[outline(>=50)]|");
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

- (void)setUp {
  [_fileOutlineView reloadData];
}

@end
