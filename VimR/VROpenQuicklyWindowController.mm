/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import <TBCacao/TBCacao.h>
#import <CocoaLumberjack/DDLog.h>
#import "VROpenQuicklyWindowController.h"
#import "VROpenQuicklyWindow.h"
#import "VRUtils.h"
#import "VRFileItemManager.h"

#import <cf/cf.h>
#import <text/ranker.h>


int qOpenQuicklyWindowWidth = 200;
static const int qMaximumNumberOfFilterResult = 50;

static inline double rank_string(NSString *string, NSString *target,
    std::vector< std::pair<size_t, size_t> >* out = NULL) {

  return oak::rank(cf::to_s((__bridge CFStringRef) string), cf::to_s((__bridge CFStringRef) target), out);
}

#ifdef DEBUG
static const int ddLogLevel = LOG_LEVEL_DEBUG;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif


@interface VRScoredItem : NSObject

@property double score;
@property id item;

- (instancetype)initWithItem:(id)item score:(double)score;
- (NSString *)description;

@end

static NSComparisonResult (^qScoredItemComparator)(id, id) = ^NSComparisonResult(VRScoredItem *url1, VRScoredItem *url2) {
  return (NSComparisonResult) (url1.score <= url2.score);
};

@implementation VRScoredItem

- (instancetype)initWithItem:(id)item score:(double)score {
  self = [super init];
  RETURN_NIL_WHEN_NOT_SELF

  _score = score;
  _item = item;

  return self;
}

- (NSString *)description {
  NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
  [description appendFormat:@"self.score=%f", self.score];
  [description appendFormat:@", self.item=%@", self.item];
  [description appendString:@">"];
  return description;
}

@end


@interface VROpenQuicklyWindowController ()

@property (weak) NSWindow *targetWindow;
@property (weak) NSSearchField *searchField;
@property (weak) NSTableView *fileItemTableView;
@property (copy) NSURL *rootUrlOfTarget;

@property (readonly) NSMutableArray *filteredFileItems;

@end


@implementation VROpenQuicklyWindowController

TB_AUTOWIRE(fileItemManager)

TB_AUTOWIRE(notificationCenter)

#pragma mark Public
- (void)showForWindow:(NSWindow *)targetWindow url:(NSURL *)targetUrl {
  self.targetWindow = targetWindow;
  self.rootUrlOfTarget = targetUrl;

  CGRect contentRect = [targetWindow contentRectForFrameRect:targetWindow.frame];
  CGFloat xPos = NSMinX(contentRect) + NSWidth(contentRect) / 2 - qOpenQuicklyWindowWidth / 2
      - 2 * qOpenQuicklyWindowPadding;
  CGFloat yPos = NSMaxY(contentRect) - NSHeight(self.window.frame);

  self.window.frameOrigin = CGPointMake(xPos, yPos);
  [self.window makeKeyAndOrderFront:self];
}

#pragma mark NSObject
- (id)init {
  VROpenQuicklyWindow *win = [[VROpenQuicklyWindow alloc] initWithContentRect:
      CGRectMake(100, 100, qOpenQuicklyWindowWidth, 250)];

  self = [super initWithWindow:win];
  RETURN_NIL_WHEN_NOT_SELF

  _searchField = win.searchField;
  _searchField.delegate = self;

  _fileItemTableView = win.fileItemTableView;
  _fileItemTableView.dataSource = self;
  _fileItemTableView.delegate = self;

  win.delegate = self;

  _filteredFileItems = [[NSMutableArray alloc] initWithCapacity:qMaximumNumberOfFilterResult];

  return self;
}

#pragma mark NSTableViewDataSource
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
  if (!self.window.isVisible) {
    return 0;
  }

  if (self.searchField.stringValue.length == 0) {
    return self.fileItemManager.fileItemsOfTargetUrl.count;
  }

  return self.filteredFileItems.count;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
  if (self.searchField.stringValue.length == 0) {
    return self.fileItemManager.fileItemsOfTargetUrl[(NSUInteger) row];
  }

  return [self.filteredFileItems[(NSUInteger) row] item];
}

#pragma mark NSTextFieldDelegate
- (void)controlTextDidChange:(NSNotification *)obj {
  NSString *searchStr = self.searchField.stringValue;
  if (searchStr.length == 0) {
    return;
  }

  NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:1000];
  // Shallow copy the file items array, since the self.fileItemManager.fileItemsOfTargetUrl can get mutated,
  // while we enumerate over it. Then, we have to update the filtered list, when a chunk of cached items are updated.
  NSArray *fileItems = [[NSArray alloc] initWithArray:self.fileItemManager.fileItemsOfTargetUrl];
  for (NSString *path in fileItems) {
    VRScoredItem *item= [self scoredItemForSearchStr:searchStr path:path];
    [result addObject:item];
  }
  [result sortUsingComparator:qScoredItemComparator];

  [self.filteredFileItems removeAllObjects];
  NSRange range;
  if (result.count >= qMaximumNumberOfFilterResult) {
    range = NSMakeRange(0, qMaximumNumberOfFilterResult - 1);
  } else {
    range = NSMakeRange(0, result.count - 1);
  }
  [self.filteredFileItems addObjectsFromArray:[result subarrayWithRange:range]];
  [self.fileItemTableView reloadData];
}

- (VRScoredItem *)scoredItemForSearchStr:(NSString *)searchStr path:(NSString *)path {
  std::vector<std::pair<size_t, size_t>> matches;
  double score = rank_string(searchStr, path.lastPathComponent, &matches);

  for (auto &region : matches) {
    DDLogVerbose(@"%@: %d, %d", path, region.first, region.second);
  }

  __block CGFloat pathScore = 0;
  NSArray *refPathComponents = self.rootUrlOfTarget.pathComponents;
  NSArray *pathComponents = path.pathComponents;

  NSArray *source = refPathComponents;
  NSArray *target = pathComponents;
  if (source.count > target.count) {
    source = pathComponents;
    target = refPathComponents;
  }

  [source enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL *stop) {
    if ([obj isEqualToString:target[idx]]) {
      pathScore++;
    } else {
      *stop = YES;
    }
  }];

  score += 0.25 * pathScore / (refPathComponents.count - 1); // path score contributes 1/4 to the whole score

  return [[VRScoredItem alloc] initWithItem:path score:score];
}

- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)selector {
  if (selector == @selector(cancelOperation:)) {
    DDLogDebug(@"Open quickly cancelled");

    [self reset];
    return YES;
  }

  if (selector == @selector(insertNewline:)) {
    DDLogDebug(@"Open quickly window: Enter pressed");
    return YES;
  }

  return NO;
}

#pragma mark NSWindowDelegate
- (void)windowDidResignMain:(NSNotification *)notification {
  DDLogDebug(@"Open quickly window resigned main");
  [self reset];
}

- (void)windowDidResignKey:(NSNotification *)notification {
  DDLogDebug(@"Open quickly window resigned key");
  [self reset];
}

#pragma mark Private
- (void)chunkOfFileItemsAdded:(id)obj {
  dispatch_async(dispatch_get_main_queue(), ^{
    [[(VROpenQuicklyWindow *) self.window fileItemTableView] reloadData];
  });
}

- (void)reset {
  [self.fileItemManager resetTargetUrl];

  [self.window close];

  [(VROpenQuicklyWindow *) self.window reset];

  [self.targetWindow makeKeyAndOrderFront:self];
  self.targetWindow = nil;
}

#pragma mark TBInitializingBean
- (void)postConstruct {
  [self.notificationCenter addObserver:self selector:@selector(chunkOfFileItemsAdded:)
                                  name:qChunkOfNewFileItemsAddedEvent object:nil];
}

@end
