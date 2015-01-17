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

#import <cf/cf.h>


NSString *const qFilterItemsOperationSearchStringKey = @"search-string";
NSString *const qFilterItemsOperationFilteredItemsKey = @"filtered-items-array";
NSString *const qFilterItemsOperationItemTableViewKey = @"file-item-table-view";
NSString *const qOpenQuicklyIgnorePatternsKey = @"open-quickly-ignore-patterns";
const NSUInteger qMaximumNumberOfFilterResult = 250;
const NSUInteger qMaximumNumberOfNonFilteredResult = 5000;


static const int qArrayChunkSize = 50000;
static NSComparisonResult (^qScoredItemComparator)(id, id) = ^NSComparisonResult(VRScoredPath *p1, VRScoredPath *p2) {
  return (NSComparisonResult) (p1.score <= p2.score);
};


static inline BOOL ignore(const char **patterns, NSUInteger patternsCount, NSURL *fileUrl) {
  for (NSUInteger i = 0; i < patternsCount; i++) {
    if (path_matches_shell_pattern(patterns[i], fileUrl.path)) {
      return YES;
    }
  }

  return NO;
}

static inline NSString *disambiguated_display_name(size_t level, NSString *path) {
  if (level == 0) {
    return path.lastPathComponent;
  }

  NSArray *disambiguationPathComponents = [path.pathComponents.reverseObjectEnumerator.allObjects
      subarrayWithRange:NSMakeRange(1, level)
  ];

  NSString *disambiguation = [disambiguationPathComponents componentsJoinedByString:@"/"];
  return SF(@"%@  —  %@", path.lastPathComponent, disambiguation);
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

  if (_searchStr.length == 0) {
    @autoreleasepool {
      [_fileItemManager pauseFileItemOperations];

      @synchronized (urlsOfTargetUrl) {
        NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:urlsOfTargetUrl.count];

        NSUInteger patternsCount = _ignorePatterns.count;
        const char *patterns[patternsCount];
        for (NSUInteger i = 0; i < patternsCount; i++) {
          patterns[i] = [_ignorePatterns[i] fileSystemRepresentation];
        }

        std::vector<std::pair<size_t, size_t>> chunkedIndexes = chunked_indexes(urlsOfTargetUrl.count, qArrayChunkSize);
        for (auto &pair : chunkedIndexes) {
          NSMutableArray *partialResult = [[NSMutableArray alloc] initWithCapacity:qArrayChunkSize];
          NSUInteger beginIndex = pair.first;
          NSUInteger endIndex = pair.second;

          CANCEL_WHEN_REQUESTED
          for (size_t i = beginIndex; i <= endIndex; i++) {
            if (ignore(patterns, patternsCount, urlsOfTargetUrl[i])) {
              continue;
            }

            [partialResult addObject:[[VRScoredPath alloc] initWithUrl:urlsOfTargetUrl[i]]];
          }

          // use the whole result from here
          [result addObjectsFromArray:partialResult];

          CANCEL_WHEN_REQUESTED
          NSArray *cappedResult = [result subarrayWithRange:capped_range_for_filtered_items(qMaximumNumberOfNonFilteredResult, result)];

          // use the capped result from here

          std::vector<std::string> paths;
          [self fillPaths:paths withScoredPaths:cappedResult];

          CANCEL_WHEN_REQUESTED
          [self disambiguatePaths:paths inScoredPaths:cappedResult];

          CANCEL_WHEN_REQUESTED
          [self reloadTableViewWithScoredPaths:cappedResult];
        }
      }

      [_fileItemManager resumeFileItemOperations];
    }

    return;
  }

  NSUInteger countOfMaxResult = qMaximumNumberOfFilterResult;

  [_fileItemManager pauseFileItemOperations];
  @autoreleasepool {
    @synchronized (urlsOfTargetUrl) {
      NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:urlsOfTargetUrl.count];

      NSUInteger patternsCount = _ignorePatterns.count;
      const char *patterns[patternsCount];
      for (NSUInteger i = 0; i < patternsCount; i++) {
        patterns[i] = [_ignorePatterns[i] fileSystemRepresentation];
      }

      std::vector<std::pair<size_t, size_t>> chunkedIndexes = chunked_indexes(urlsOfTargetUrl.count, qArrayChunkSize);
      for (auto &pair : chunkedIndexes) {
        NSUInteger beginIndex = pair.first;
        NSUInteger endIndex = pair.second;

        CANCEL_WHEN_REQUESTED
        NSUInteger countOfResultUpToNow = result.count;
        NSUInteger addedCount = 0;
        for (size_t i = beginIndex; i <= endIndex; i++) {
          if (ignore(patterns, patternsCount, urlsOfTargetUrl[i])) {
            continue;
          }

          [result addObject:[[VRScoredPath alloc] initWithUrl:urlsOfTargetUrl[i]]];
          addedCount++;
        }

        // filter start
        CANCEL_WHEN_REQUESTED
        dispatch_loop(addedCount, ^(size_t i) {
          VRScoredPath *scoredPath = result[countOfResultUpToNow + i];
          [scoredPath computeScoreForCandidate:_searchStr];
        });

        CANCEL_WHEN_REQUESTED
        [result sortUsingComparator:qScoredItemComparator];
        // filter end

        NSArray *cappedResult = [result subarrayWithRange:capped_range_for_filtered_items(countOfMaxResult, result)];

        // use the capped result from here

        std::vector<std::string> paths;
        [self fillPaths:paths withScoredPaths:cappedResult];

        CANCEL_WHEN_REQUESTED
        [self disambiguatePaths:paths inScoredPaths:cappedResult];

        CANCEL_WHEN_REQUESTED
        [self reloadTableViewWithScoredPaths:cappedResult];
      }
    }
  }
  [_fileItemManager resumeFileItemOperations];
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

- (void)fillPaths:(std::vector<std::string> &)paths withScoredPaths:(NSArray *)scoredPaths {
  for (VRScoredPath *scoredPath in scoredPaths) {
    paths.push_back(cf::to_s((__bridge CFStringRef) scoredPath.url.path));
  }
}

- (void)disambiguatePaths:(std::vector<std::string> &)paths inScoredPaths:(NSArray *)scoredPaths {
  std::vector<size_t> levels = disambiguate(paths);

  dispatch_loop(scoredPaths.count, ^(size_t i) {
    VRScoredPath *scoredPath = scoredPaths[i];
    scoredPath.displayName = disambiguated_display_name(levels[i], scoredPath.url.path);
  });
}

@end
