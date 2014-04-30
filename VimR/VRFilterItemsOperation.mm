/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import <CocoaLumberjack/DDLog.h>
#import "VRFilterItemsOperation.h"
#import "VROpenQuicklyWindowController.h"
#import "VRFileItemManager.h"
#import "VRUtils.h"
#import "VRScoredPath.h"
#import "NSArray+VR.h"
#import "VRCppUtils.h"

#import <cf/cf.h>


static const int ddLogLevel = LOG_LEVEL_DEBUG;


NSString *const qFilterItemsOperationFileItemManagerKey = @"file-item-manager";
NSString *const qFilterItemsOperationSearchStringKey = @"search-string";
NSString *const qFilterItemsOperationFilteredItemsKey = @"filtered-items-array";
NSString *const qFilterItemsOperationItemTableViewKey = @"file-item-table-view";
const NSUInteger qMaximumNumberOfFilterResult = 250;


static const int qArrayChunkSize = 2000;

static NSString *disambiguated_display_name(size_t level, NSURL *url) {
  if (level == 0) {
    return url.lastPathComponent;
  }

  NSArray *disambiguationPathComponents = [url.pathComponents.reverseObjectEnumerator.allObjects
      subarrayWithRange:NSMakeRange(1, level)
  ];

  NSString *disambiguation = [disambiguationPathComponents componentsJoinedByString:@"/"];
  return SF(@"%@  —  %@", url.lastPathComponent, disambiguation);
}

static NSRange capped_range_for_filtered_items(NSArray *result) {
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
        @synchronized (_filteredItems) {
          [_fileItemTableView reloadData];
        }
      });

      return;
    }

    [_fileItemManager pause];

    // We could shallow copy the file items array, since the _controller.fileItemManager.fileItemsOfTargetUrl can get
    // mutated, while we enumerate over it. Then, we have to update the filtered list, when a chunk of cached items are
    // updated. However, it's not necessary anymore, because we're pausing the file item manager...
    NSArray *fileItemsOfTargetUrl = _fileItemManager.fileItemsOfTargetUrl;

    NSMutableArray *result;
    std::vector<std::pair<size_t, size_t>> chunkedIndexes;
    @synchronized (fileItemsOfTargetUrl) {
      result = [[NSMutableArray alloc] initWithCapacity:fileItemsOfTargetUrl.count];
      chunkedIndexes = chunked_indexes(fileItemsOfTargetUrl.count, qArrayChunkSize);
    }

    for (auto &pair : chunkedIndexes) {
      CANCEL_WHEN_REQUESTED

      NSUInteger beginIndex = pair.first;
      NSUInteger endIndex = pair.second;
      NSUInteger count = endIndex - beginIndex + 1;

      @synchronized (fileItemsOfTargetUrl) {
        for (size_t i = beginIndex; i <= endIndex; i++) {
          [result addObject:[[VRScoredPath alloc] initWithPath:fileItemsOfTargetUrl[i]]];
        }
      }

      CANCEL_WHEN_REQUESTED
      dispatch_loop(count, ^(size_t i) {
        [result[beginIndex + i] computeScoreForCandidate:_searchStr];
      });

      CANCEL_WHEN_REQUESTED
      [result sortUsingComparator:qScoredItemComparator];
      NSArray *cappedResult = [result subarrayWithRange:capped_range_for_filtered_items(result)];

      std::vector<std::string> paths;
      for (VRScoredPath *scoredPath in cappedResult) {
        paths.push_back(cf::to_s((__bridge CFStringRef) scoredPath.path));
      }

      CANCEL_WHEN_REQUESTED
      std::vector<size_t> levels = disambiguate(paths);
      dispatch_loop(cappedResult.count, ^(size_t i) {
        VRScoredPath *scoredPath = cappedResult[i];
        NSURL *url = [NSURL fileURLWithPath:scoredPath.path];

        scoredPath.displayName = disambiguated_display_name(levels[i], url);
      });

      CANCEL_WHEN_REQUESTED
      @synchronized (_filteredItems) {
        [_filteredItems removeAllObjects];
        [_filteredItems addObjectsFromArray:cappedResult];
      }

      CANCEL_WHEN_REQUESTED
      dispatch_to_main_thread(^{
        @synchronized (_filteredItems) {
          [_fileItemTableView reloadData];
        }
      });
    }

    [_fileItemManager resume];
  }
}

@end
