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
#import "VRInvalidateCacheOperation.h"
#import "VRDefaultLogSetting.h"
#import "OakImageAndTextCell.h"
#import "NSArray+VR.h"
#import "VROutlineView.h"
#import "NSTableView+VR.h"
#import "VRWorkspaceView.h"


#define CONSTRAIN(fmt) [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:fmt options:0 metrics:nil views:views]];


static NSComparisonResult (^qNodeDirComparator)(NSNumber *, NSNumber *) =
    ^NSComparisonResult(NSNumber *node1IsDir, NSNumber *node2IsDir) {
      if (node1IsDir.boolValue) {
        return NSOrderedAscending;
      } else {
        return NSOrderedDescending;
      }
    };


@implementation VRNode

- (NSString *)description {
  NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
  [description appendFormat:@"self.url=%@", self.url];
  [description appendFormat:@", self.name=%@", self.name];
  [description appendFormat:@", self.children=%@", self.children];
  [description appendFormat:@", self.dir=%d", self.dir];
  [description appendFormat:@", self.hidden=%d", self.hidden];
  [description appendFormat:@", self.item=%@", self.item];
  [description appendString:@">"];
  return description;
}

@end


@implementation VRFileBrowserView {
  NSOperationQueue *_invalidateCacheQueue;

  VRNode *_rootNode;
  NSMutableSet *_expandedUrls;
}

#pragma mark Public
- (void)setRootUrl:(NSURL *)rootUrl {
  _rootUrl = rootUrl;
  [self cacheInvalidated:nil];
}

- (instancetype)initWithRootUrl:(NSURL *)rootUrl {
  self = [super initWithFrame:CGRectZero];
  RETURN_NIL_WHEN_NOT_SELF

  _rootUrl = rootUrl;
  _invalidateCacheQueue = [[NSOperationQueue alloc] init];
  _invalidateCacheQueue.maxConcurrentOperationCount = 1;

  _expandedUrls = [[NSMutableSet alloc] initWithCapacity:40];

  return self;
}

- (void)reload {
  NSURL *selectedUrl = [_fileOutlineView.selectedItem url];
  CGRect visibleRect = _fileOutlineView.enclosingScrollView.contentView.visibleRect;

  [self reCacheNodes];
  [_fileOutlineView reloadData];
  [self restoreExpandedStates];

  [_fileOutlineView scrollRectToVisible:visibleRect];

  [self selectNodeWithUrl:selectedUrl];
}

- (void)setUp {
  [_notificationCenter addObserver:self selector:@selector(cacheInvalidated:) name:qInvalidatedCacheEvent object:nil];

  [self addViews];
  [self reload];
}

#pragma mark NSObject
- (void)dealloc {
  [_notificationCenter removeObserver:self];
}

#pragma mark VRMovementsAndActionsProtocol
- (void)viMotionLeft:(id)sender event:(NSEvent *)event {
  [self fileOutlineViewDoubleClicked:sender];
}

- (void)viMotionUp:(id)sender event:(NSEvent *)event {
  [_fileOutlineView moveSelectionByDelta:-1];
}

- (void)viMotionDown:(id)sender event:(NSEvent *)event {
  [_fileOutlineView moveSelectionByDelta:1];
}

- (void)viMotionRight:(id)sender event:(NSEvent *)event {
  [self fileOutlineViewDoubleClicked:sender];
}

- (void)actionSpace:(id)sender event:(NSEvent *)event {
  [self fileOutlineViewDoubleClicked:sender];
}

- (void)actionCarriageReturn:(id)sender event:(NSEvent *)event {
  [self fileOutlineViewDoubleClicked:sender];
}

- (void)actionEscape:(id)sender event:(NSEvent *)event {
  [self.window makeFirstResponder:[self.window.windowController vimView].textView];
}

#pragma mark NSOutlineViewDataSource
- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(VRNode *)item {
  VRNode *currentNode = item ?: _rootNode;

  if (!currentNode.children) {[self buildChildNodesForNode:currentNode];}

  return currentNode.children.count;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(VRNode *)item {
  if (!item) {return _rootNode.children[(NSUInteger) index];}

  return item.children[(NSUInteger) index];
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
  cell.image = [_fileItemManager iconForUrl:item.url];

  return cell;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldExpandItem:(VRNode *)item {
  [_expandedUrls addObject:item.url];

  return YES;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldCollapseItem:(VRNode *)item {
  [_expandedUrls removeObject:item.url];

  return YES;
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
  tableColumn.dataCell = [[OakImageAndTextCell alloc] init];
  [tableColumn.dataCell setAllowsEditingTextAttributes:YES];
  [tableColumn.dataCell setLineBreakMode:NSLineBreakByTruncatingTail];

  _fileOutlineView = [[VROutlineView alloc] initWithFrame:CGRectZero];
  [_fileOutlineView addTableColumn:tableColumn];
  _fileOutlineView.outlineTableColumn = tableColumn;
  [_fileOutlineView sizeLastColumnToFit];
  _fileOutlineView.allowsEmptySelection = YES;
  _fileOutlineView.allowsMultipleSelection = NO;
  _fileOutlineView.headerView = nil;
  _fileOutlineView.focusRingType = NSFocusRingTypeNone;
  _fileOutlineView.dataSource = self;
  _fileOutlineView.delegate = self;
  _fileOutlineView.movementsAndActionDelegate = self;
  _fileOutlineView.allowsMultipleSelection = NO;
  _fileOutlineView.doubleAction = @selector(fileOutlineViewDoubleClicked:);
  _fileOutlineView.backgroundColor = [NSColor colorWithSRGBRed:0.925 green:0.925 blue:0.925 alpha:1.0];

  NSScrollView *scrollView = [[NSScrollView alloc] initWithFrame:CGRectZero];
  scrollView.translatesAutoresizingMaskIntoConstraints = NO;
  scrollView.hasVerticalScroller = YES;
  scrollView.hasHorizontalScroller = YES;
  scrollView.borderType = NSBezelBorder;
  scrollView.autohidesScrollers = YES;
  scrollView.documentView = _fileOutlineView;
  [self addSubview:scrollView];

  NSDictionary *views = @{
      @"outline" : scrollView,
  };

  CONSTRAIN(@"H:|-(-1)-[outline(>=50)]-(-1)-|");
  CONSTRAIN(@"V:|-(-1)-[outline(>=50)]-(-1)-|");
}

- (void)fileOutlineViewDoubleClicked:(id)sender {
  VRNode *selectedItem = _fileOutlineView.selectedItem;
  if (!selectedItem) {return;}

  if (!selectedItem.dir) {
    VROpenMode mode = open_mode_from_event(
        [NSApp currentEvent],
        [_userDefaults stringForKey:qDefaultDefaultOpeningBehavior]
    );

    [(VRMainWindowController *) self.window.windowController openFileWithUrls:selectedItem.url openMode:mode];
    return;
  }

  if ([_fileOutlineView isItemExpanded:selectedItem]) {
    [_fileOutlineView collapseItem:selectedItem];
  } else {
    [_fileOutlineView expandItem:selectedItem];
  }
}

- (void)cacheInvalidated:(NSNotification *)notification {
  [_invalidateCacheQueue addOperationWithBlock:^{
    // We wait here till all file item operations are finished, because, for instance, the children items of the root
    // can be deleted by -reload and Open Quickly file item operations are trying to use them.
    [_fileItemManager waitTillFileItemOperationsFinished];
    DDLogDebug(@"finished wating till file item operations are done");

    dispatch_to_main_thread(^{
      @synchronized (_fileItemManager) {
        [self reload];
      }
    });
  }];
}

- (void)selectNodeWithUrl:(NSURL *)selectedUrl {
  if (selectedUrl == nil) {return;}

  for (NSUInteger i = 0; i < _fileOutlineView.numberOfRows; i++) {
    if ([[[_fileOutlineView itemAtRow:i] url] isEqualTo:selectedUrl]) {
      [_fileOutlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:i] byExtendingSelection:NO];
      return;
    }
  }
}

- (void)restoreExpandedStates {
  NSSet *oldExpandedStates = _expandedUrls.copy;
  [_expandedUrls removeAllObjects];

  [self restoreExpandState:_rootNode.children states:oldExpandedStates];
}

- (void)reCacheNodes {
  _rootNode = [[VRNode alloc] init];
  _rootNode.item = [_fileItemManager itemForUrl:_rootUrl];

  [self buildChildNodesForNode:_rootNode];
  DDLogDebug(@"Re-cached root node");
}

- (void)restoreExpandState:(NSArray *)children states:(NSSet *)states {
  for (VRNode *node in children) {
    if (node.dir && [states containsObject:node.url]) {
      [_fileOutlineView expandItem:node];

      if (!node.children.isEmpty) {
        [self restoreExpandState:node.children states:states];
      }
    }
  }
}

- (void)buildChildNodesForNode:(VRNode *)parentNode {
  NSArray *childItems = [_fileItemManager childrenOfItem:parentNode.item];
  NSMutableArray *children = [[NSMutableArray alloc] initWithCapacity:childItems.count];
  for (id item in childItems) {
    VRNode *node = [self nodeFromItem:item];
    [children addObject:node];
  }

  NSArray *filteredChildren = [self filterHiddenNodesIfNec:children];
  if (_workspaceView.showFoldersFirst) {
    NSSortDescriptor *folderDescriptor = [[NSSortDescriptor alloc] initWithKey:@"dir" ascending:YES
                                                                    comparator:qNodeDirComparator];

    parentNode.children = [filteredChildren sortedArrayUsingDescriptors:@[folderDescriptor]];
  } else {
    parentNode.children = filteredChildren;
  }
}

- (VRNode *)nodeFromItem:(id)item {
  VRNode *node = [[VRNode alloc] init];
  node.url = [_fileItemManager urlForItem:item];
  node.dir = [_fileItemManager isItemDir:item];
  node.hidden = [_fileItemManager isItemHidden:item];
  node.name = [_fileItemManager nameOfItem:item];
  node.item = item;
  node.children = nil;

  return node;
}

- (NSArray *)filterHiddenNodesIfNec:(NSArray *)nodes {
  if (_workspaceView.showHiddenFiles) {return nodes;}

  NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:nodes.count];
  for (VRNode *item in nodes) {
    if (!item.hidden) {
      [result addObject:item];
    }
  }

  return result;
}

@end
