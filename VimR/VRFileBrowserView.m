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


@interface VRNode : NSObject

@property (nonatomic) NSURL *url;
@property (nonatomic) id item;
@property (nonatomic) NSString *name;
@property (nonatomic) NSArray *children;
@property (nonatomic, getter=isDir) BOOL dir;
@property (nonatomic, getter=isHidden) BOOL hidden;
- (NSString *)description;

@end

@implementation VRNode

- (NSString *)description {
  NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
  [description appendFormat:@"self.url=%@", self.url];
  [description appendFormat:@", self.item=%@", self.item];
  [description appendFormat:@", self.name=%@", self.name];
  [description appendFormat:@", self.children=%@", self.children];
  [description appendFormat:@", self.dir=%d", self.dir];
  [description appendFormat:@", self.hidden=%d", self.hidden];
  [description appendString:@">"];
  return description;
}

@end


@implementation VRFileBrowserView {
  NSOutlineView *_fileOutlineView;
  NSScrollView *_scrollView;
  NSPopUpButton *_settingsButton;
  NSMenuItem *_showHiddenMenuItem;
  VRNode *_rootNode;
}

#pragma mark Public
- (void)setRootUrl:(NSURL *)rootUrl {
  _rootUrl = rootUrl;
  [self reCacheNodes];
  [_fileOutlineView reloadData];
  [_fileOutlineView selectRowIndexes:nil byExtendingSelection:NO];
}

- (instancetype)initWithRootUrl:(NSURL *)rootUrl {
  self = [super initWithFrame:CGRectZero];
  RETURN_NIL_WHEN_NOT_SELF

  _rootUrl = rootUrl;
  _rootNode = [[VRNode alloc] init];

  [self addViews];

  return self;
}

- (void)dealloc {
  [_notificationCenter removeObserver:self];
}

- (void)setUp {
  [_notificationCenter addObserver:self selector:@selector(cacheInvalidated:) name:qInvalidatedCacheEvent
                            object:nil];

  [self reCacheNodes];
  [_fileOutlineView reloadData];
}

- (void)reCacheNodes {
  @synchronized (_fileItemManager) {
    NSArray *childrenOfRootUrl = [_fileItemManager childrenOfRootUrl:_rootUrl];
    [self buildUpChildNodes:childrenOfRootUrl ofNode:_rootNode];
    NSLog(@"######## recached root node: %@", @(_rootNode.children.count));
  }
}

- (void)buildUpChildNodes:(NSArray *)childItems ofNode:(VRNode *)parentNode {
  NSMutableArray *children = [[NSMutableArray alloc] initWithCapacity:childItems.count];
  for (id item in childItems) {
    VRNode *node = [[VRNode alloc] init];
    node.url = [_fileItemManager urlForItem:item];
    node.dir = [_fileItemManager isItemDir:item];
    node.hidden = [_fileItemManager isItemHidden:item];
    node.name = [_fileItemManager nameOfItem:item];
    node.item = item;
    node.children = nil;

    [children addObject:node];
  }

  parentNode.children = children;
}

- (NSArray *)filter:(NSArray *)input {
  if ([self showHiddenFiles]) {
    return input;
  }

  NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:input.count];
  for (VRNode *item in input) {
    if (!item.hidden) {
      [result addObject:item];
    }
  }

  return result;
}

#pragma mark NSOutlineViewDataSource
- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(VRNode *)item {
  if (!item) {
    if (_rootNode.children) {
      return [self filter:_rootNode.children].count;
    }  else {
      [self buildUpChildNodes:[_fileItemManager childrenOfRootUrl:_rootNode.item] ofNode:_rootNode];
      return [self filter:_rootNode.children].count;
    }
  }

  if (item.children) {
    return [self filter:item.children].count;
  }

  [self buildUpChildNodes:[_fileItemManager childrenOfItem:item.item] ofNode:item];
  return [self filter:item.children].count;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(VRNode *)item {
  if (!item) {
    return [self filter:_rootNode.children][(NSUInteger) index];
  }

  return [[self filter:item.children] objectAtIndex:(NSUInteger) index];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(VRNode *)item {
  return item.dir;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn
           byItem:(VRNode *)item {

  return item.name;
}

#pragma mark NSOutlineViewDelegate
- (NSCell *)outlineView:(NSOutlineView *)outlineView dataCellForTableColumn:(NSTableColumn *)tableColumn item:(VRNode *)item {
  NSTextFieldCell *cell = [tableColumn dataCellForRow:[_fileOutlineView rowForItem:item]];
  cell.textColor = item.hidden ? [NSColor grayColor] : [NSColor textColor];

  return cell;
}

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
  [tableColumn.dataCell setAllowsEditingTextAttributes:YES];
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
  [_settingsButton.menu addItemWithTitle:@"" action:NULL keyEquivalent:@""];

  _showHiddenMenuItem = [[NSMenuItem alloc] initWithTitle:@"Show Hidden Files"
                                                   action:@selector(toggleShowHiddenFiles:) keyEquivalent:@""];
  _showHiddenMenuItem.target = self;
  _showHiddenMenuItem.state = [_userDefaults boolForKey:qDefaultShowHiddenInFileBrowser] ? NSOnState : NSOffState;
  [_settingsButton.menu addItem:_showHiddenMenuItem];

  [self addSubview:_settingsButton];

  NSDictionary *views = @{
      @"outline" : _scrollView,
      @"settings" : _settingsButton,
  };

  CONSTRAIN(@"H:[settings]|");
  CONSTRAIN(@"H:|-(-1)-[outline(>=50)]-(-1)-|");
  CONSTRAIN(@"V:|-(-1)-[outline(>=50)][settings]-(3)-|");
}

- (IBAction)toggleShowHiddenFiles:(id)sender {
  NSInteger oldState = _showHiddenMenuItem.state;
  _showHiddenMenuItem.state = !oldState;

  [_fileOutlineView reloadData];
}

- (void)fileOutlineViewDoubleClicked:(id)sender {
  id clickedItem = [_fileOutlineView itemAtRow:_fileOutlineView.clickedRow];

  if (![_fileItemManager isItemDir:clickedItem]) {
    [(VRMainWindowController *) self.window.windowController openFilesWithUrls:@[[_fileItemManager urlForItem:clickedItem]]];
    return;
  }

  if ([_fileOutlineView isItemExpanded:clickedItem]) {
    [_fileOutlineView collapseItem:clickedItem];
  } else {
    [_fileOutlineView expandItem:clickedItem];
  }
}

- (NSArray *)filterOutHiddenFromItems:(NSArray *)items {
  if ([self showHiddenFiles]) {
    return items;
  }

  NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:items.count];
  for (id item in items) {
    if (![_fileItemManager isItemHidden:item]) {
      [result addObject:item];
    }
  }

  return result;
}

- (BOOL)showHiddenFiles {
  return _showHiddenMenuItem.state == NSOnState;
}

- (void)cacheInvalidated:(NSNotification *)notification {
  [self reCacheNodes];
  [_fileOutlineView reloadData];
  [_fileOutlineView selectRowIndexes:nil byExtendingSelection:NO];
}

@end
