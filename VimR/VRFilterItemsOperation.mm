/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import "VRFilterItemsOperation.h"
#import "VROpenQuicklyWindowController.h"
#import "VRFileItemManager.h"
#import "VRUtils.h"
#import "VRScoredPath.h"
#import "NSArray+VR.h"

#import <cf/cf.h>
#import <text/ranker.h>
#import <__locale>


NSString *const qFilterItemsOperationFileItemManagerKey = @"file-item-manager";
NSString *const qFilterItemsOperationSearchStringKey = @"search-string";
NSString *const qFilterItemsOperationFilteredItemsKey = @"filtered-items-array";
NSString *const qFilterItemsOperationItemTableViewKey = @"file-item-table-view";
const NSUInteger qMaximumNumberOfFilterResult = 50;

static inline double rank_string(NSString *string, NSString *target,
    std::vector< std::pair<size_t, size_t> > *out = NULL) {

  return oak::rank(cf::to_s((__bridge CFStringRef) string), cf::to_s((__bridge CFStringRef) target), out);
}

static NSComparisonResult (^qScoredItemComparator)(id, id) = ^NSComparisonResult(VRScoredPath *p1, VRScoredPath *p2) {
  return (NSComparisonResult) (p1.score <= p2.score);
};


@implementation VRFilterItemsOperation {
  __weak VRFileItemManager *_fileItemManager;
  __weak NSMutableArray *_filteredItems;
  __weak NSTableView *_fileItemTableView;
  NSString *_searchStr;
}

#pragma mark Public
- (instancetype)initWithDict:(NSDictionary *)dict {
  self = [super init];
  RETURN_NIL_WHEN_NOT_SELF

  _fileItemManager = dict[qFilterItemsOperationFileItemManagerKey];
  _filteredItems = dict[qFilterItemsOperationFilteredItemsKey];
  _searchStr = [dict[qFilterItemsOperationSearchStringKey] copy];
  _fileItemTableView = dict[qFilterItemsOperationItemTableViewKey];

  return self;
}

#pragma mark NSOperation
- (void)main {
  @autoreleasepool {
    if (self.isCancelled) {
      return;
    }

    if (_searchStr.length == 0) {
      @synchronized (_filteredItems) {
        [_filteredItems removeAllObjects];
      }

      dispatch_to_main_thread(^{
        [_fileItemTableView reloadData];
      });

      return;
    }

    [_fileItemManager pause];

    // We could shallow copy the file items array, since the _controller.fileItemManager.fileItemsOfTargetUrl can get
    // mutated, while we enumerate over it. Then, we have to update the filtered list, when a chunk of cached items are
    // updated. However, it's not necessary anymore, because we're pausing the file item manager...
    NSArray *filItemsOfTargetUrl = _fileItemManager.fileItemsOfTargetUrl;

    NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:1000];
    @synchronized (filItemsOfTargetUrl) {
      for (NSString *path in filItemsOfTargetUrl) {
        if (self.isCancelled) {
          [_fileItemManager resume];
          return;
        }

        VRScoredPath *item = [self scoredItemForSearchStr:_searchStr path:path];
        [result addObject:item];
      }
    }
    [result sortUsingComparator:qScoredItemComparator];

    if (self.isCancelled) {
      [_fileItemManager resume];
      return;
    }

    @synchronized (_filteredItems) {
      [_filteredItems removeAllObjects];
      [_filteredItems addObjectsFromArray:[result subarrayWithRange:[self rangeForFilteredItems:result]]];
    }

    if (self.isCancelled) {
      [_fileItemManager resume];
      return;
    }

    dispatch_to_main_thread(^{
      [_fileItemTableView reloadData];
    });

    [_fileItemManager resume];
  }
}

#pragma mark Private
- (NSRange)rangeForFilteredItems:(NSArray *)result {
  if (result.isEmpty) {
    return NSMakeRange(0, 0);
  }

  NSRange range;
  if (result.count >= qMaximumNumberOfFilterResult) {
    range = NSMakeRange(0, qMaximumNumberOfFilterResult - 1);
  } else {
    range = NSMakeRange(0, result.count - 1);
  }
  return range;
}

- (VRScoredPath *)scoredItemForSearchStr:(NSString *)searchStr path:(NSString *)path {
  double score = rank_string(searchStr, path.lastPathComponent);

  return [[VRScoredPath alloc] initWithPath:path score:score];
}

@end
