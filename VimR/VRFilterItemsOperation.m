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


NSString *const qFilterItemsOperationFileItemManagerKey = @"file-item-manager";
NSString *const qFilterItemsOperationSearchStringKey = @"search-string";
NSString *const qFilterItemsOperationFilteredItemsKey = @"filtered-items-array";
NSString *const qFilterItemsOperationItemTableViewKey = @"file-item-table-view";
const NSUInteger qMaximumNumberOfFilterResult = 50;


static NSComparisonResult (^qScoredItemComparator)(id, id) = ^NSComparisonResult(VRScoredPath *p1, VRScoredPath *p2) {
  return (NSComparisonResult) (p1.score <= p2.score);
};


#define CANCEL_WHEN_REQUESTED  if (self.isCancelled) { \
                                 [_fileItemManager resume]; \
                                 return; \
                               }


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
    NSArray *fileItemsOfTargetUrl = _fileItemManager.fileItemsOfTargetUrl;

    NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:1000];
    @synchronized (fileItemsOfTargetUrl) {
      for (NSString *path in fileItemsOfTargetUrl) {
        CANCEL_WHEN_REQUESTED

        [result addObject:[[VRScoredPath alloc] initWithPath:path]];
      }
    }

    CANCEL_WHEN_REQUESTED

    dispatch_apply(result.count, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(size_t i) {
      [result[i] computeScoreForCandidate:_searchStr];
    });

    CANCEL_WHEN_REQUESTED

    [result sortUsingComparator:qScoredItemComparator];

    CANCEL_WHEN_REQUESTED

    @synchronized (_filteredItems) {
      [_filteredItems removeAllObjects];
      [_filteredItems addObjectsFromArray:[result subarrayWithRange:[self rangeForFilteredItems:result]]];
    }

    CANCEL_WHEN_REQUESTED

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

@end
