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
#import "VRCppUtils.h"
#import "VRTextMateCppUtils.h"
#import "VROpenQuicklyIgnorePattern.h"

#import <cf/cf.h>


NSString *const qFilterItemsOperationSearchStringKey = @"search-string";
NSString *const qFilterItemsOperationFilteredItemsKey = @"filtered-items-array";
NSString *const qFilterItemsOperationItemTableViewKey = @"file-item-table-view";
NSString *const qOpenQuicklyIgnorePatternsKey = @"open-quickly-ignore-patterns";
const NSUInteger qMaximumNumberOfFilterResult = 250;
const NSUInteger qMaximumNumberOfNonFilteredResult = 2500;


static const int qArrayChunkSize = 10000;
static NSComparisonResult (^qScoredItemComparator)(id, id) = ^NSComparisonResult(VRScoredPath *p1, VRScoredPath *p2) {
  return (NSComparisonResult) (p1.score <= p2.score);
};


static inline BOOL ignore_url(__weak NSArray *patterns, NSURL *fileUrl) {
  NSString *path = fileUrl.path;
  for (VROpenQuicklyIgnorePattern *pattern in patterns) {
    if ([pattern matchesPath:path]) {
      return YES;
    }
  }

  return NO;
}

static inline NSString *disambiguated_display_name(size_t level, NSString *path) {
  if (level == 0) {
    return path.lastPathComponent;
  }

  NSArray *pathComponents = path.pathComponents;
  NSArray *disambiguationPathComponents = [pathComponents.reverseObjectEnumerator.allObjects subarrayWithRange:NSMakeRange(1, level)];

  NSString *disambiguation = [disambiguationPathComponents componentsJoinedByString:@"/"];
  return SF(@"%@  —  %@", pathComponents.lastObject, disambiguation);
}

static inline NSRange capped_range_for_filtered_items(NSUInteger maxCount, NSArray *result) {
  if (result.isEmpty) {
    return NSMakeRange(0, 0);
  }

  NSRange range;
  if (result.count >= maxCount) {
    range = NSMakeRange(0, maxCount - 1);
  } else {
    range = NSMakeRange(0, result.count - 1);
  }

  return range;
}


#define CANCEL_WHEN_REQUESTED  if (self.isCancelled) { \
                                 [_fileItemManager resumeFileItemOperations]; \
                                 return; \
                               }

@implementation VRFilterItemsOperation {
  __weak VRFileItemManager *_fileItemManager;
  __weak NSMutableArray *_filteredItems;
  __weak NSTableView *_fileItemTableView;
  NSArray *_ignorePatterns;
  NSString *_searchStr;
}

#pragma mark Public
- (instancetype)initWithDict:(NSDictionary *)dict {
  self = [super init];
  RETURN_NIL_WHEN_NOT_SELF

  _fileItemManager = dict[qOperationFileItemManagerKey];
  _filteredItems = dict[qFilterItemsOperationFilteredItemsKey];
  _searchStr = [dict[qFilterItemsOperationSearchStringKey] copy];
  _fileItemTableView = dict[qFilterItemsOperationItemTableViewKey];
  _ignorePatterns = dict[qOpenQuicklyIgnorePatternsKey];

  return self;
}

#pragma mark NSOperation
- (void)main {
  if (self.isCancelled) {return;}

  NSArray *urlsOfTargetUrl = _fileItemManager.urlsOfTargetUrl;
  BOOL filterResult = _searchStr.length > 0;

  [_fileItemManager pauseFileItemOperations];
  @autoreleasepool {
    @synchronized (urlsOfTargetUrl) {
      NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:urlsOfTargetUrl.count];
      std::vector<std::pair<size_t, size_t>> chunkedIndexes = chunked_indexes(urlsOfTargetUrl.count, qArrayChunkSize);

      for (auto &pair : chunkedIndexes) {
        NSUInteger beginIndex = pair.first;
        NSUInteger endIndex = pair.second;
        NSUInteger count = endIndex - beginIndex + 1;

        CANCEL_WHEN_REQUESTED
        for (size_t i = beginIndex; i <= endIndex; i++) {
          [result addObject:[[VRScoredPath alloc] initWithUrl:urlsOfTargetUrl[i]]];
        }

        CANCEL_WHEN_REQUESTED
        [self computeScores:result beginIndex:beginIndex count:count];

        CANCEL_WHEN_REQUESTED
        [result sortUsingComparator:qScoredItemComparator];

        CANCEL_WHEN_REQUESTED
        NSArray *cappedResult = [self cappedResult:result filter:filterResult];

        CANCEL_WHEN_REQUESTED
        std::vector<std::string> paths;
        for (VRScoredPath *scoredPath in cappedResult) {
          paths.push_back(cf::to_s((__bridge CFStringRef) scoredPath.url.path));
        }

        CANCEL_WHEN_REQUESTED
        [self disambiguateResult:cappedResult paths:paths];

        CANCEL_WHEN_REQUESTED
        [self reloadTableViewWithScoredPaths:cappedResult];
      }
    }
  }
  [_fileItemManager resumeFileItemOperations];
}

- (void)disambiguateResult:(NSArray *)cappedResult paths:(std::vector<std::string> &)paths {
  std::vector<size_t> levels = disambiguate(paths);
  dispatch_loop(cappedResult.count, ^(size_t i) {
    VRScoredPath *scoredPath = cappedResult[i];
    scoredPath.displayName = disambiguated_display_name(levels[i], scoredPath.url.path);
  });
}

- (void)computeScores:(NSMutableArray *)result beginIndex:(NSUInteger)beginIndex count:(NSUInteger)count {
  dispatch_loop(count, ^(size_t i) {
    VRScoredPath *scoredPath = result[beginIndex + i];
    [scoredPath computeScoreForCandidate:_searchStr];
  });
}

#pragma mark Private
- (NSArray *)cappedResult:(NSArray *)uncappedResult filter:(BOOL)filterResult {
  NSUInteger countOfMaxResult = filterResult ? qMaximumNumberOfFilterResult : qMaximumNumberOfNonFilteredResult;
  NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:countOfMaxResult];

  std::vector<std::pair<size_t, size_t>> chunkedIndexes = chunked_indexes(uncappedResult.count, countOfMaxResult);
  for (auto &pair : chunkedIndexes) {
    NSArray *cappedResultForIteration = [uncappedResult subarrayWithRange:NSMakeRange(pair.first, pair.second - pair.first + 1)];
    NSMutableArray *cappedResult = cappedResultForIteration.mutableCopy;

    for (VRScoredPath *scoredPath in cappedResultForIteration) {
      if (ignore_url(_ignorePatterns, scoredPath.url)) {
        [cappedResult removeObject:scoredPath];
      }
    }

    if (result.count + cappedResult.count >= countOfMaxResult) {
      [result addObjectsFromArray:[cappedResult subarrayWithRange:NSMakeRange(0, countOfMaxResult - result.count)]];
      return result;
    }

    [result addObjectsFromArray:cappedResult];
  }

  return result;
}

- (void)reloadTableViewWithScoredPaths:(NSArray *)scoredPaths {
  dispatch_to_main_thread(^{
    @synchronized (_filteredItems) {
      [_filteredItems removeAllObjects];
      [_filteredItems addObjectsFromArray:scoredPaths];

      [_fileItemTableView reloadData];
    }
  });
}

@end
