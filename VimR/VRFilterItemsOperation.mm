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

#import <numeric>
#import <cf/cf.h>


static const int ddLogLevel = LOG_LEVEL_DEBUG;


NSString *const qFilterItemsOperationFileItemManagerKey = @"file-item-manager";
NSString *const qFilterItemsOperationSearchStringKey = @"search-string";
NSString *const qFilterItemsOperationFilteredItemsKey = @"filtered-items-array";
NSString *const qFilterItemsOperationItemTableViewKey = @"file-item-table-view";
const NSUInteger qMaximumNumberOfFilterResult = 50;


static const int qArrayChunkSize = 50;


static NSComparisonResult (^qScoredItemComparator)(id, id) = ^NSComparisonResult(VRScoredPath *p1, VRScoredPath *p2) {
  return (NSComparisonResult) (p1.score <= p2.score);
};

/**
* Copied from TextMate
* Frameworks/io/src/path.mm
* v2.0-alpha.9537
*/
static size_t count_slashes(std::string const &s1, std::string const &s2) {
  auto s1First = s1.rbegin(), s1Last = s1.rend();
  auto s2First = s2.rbegin(), s2Last = s2.rend();
  while (s1First != s1Last && s2First != s2Last) {
    if (*s1First != *s2First)
      break;
    ++s1First, ++s2First;
  }
  return (size_t) std::count(s1.rbegin(), s1First, '/');
}

/**
* Copied from TextMate
* Frameworks/io/src/path.mm
* v2.0-alpha.9537
*/
std::vector<size_t> disambiguate(std::vector<std::string> const &paths) {
  std::vector<size_t> v(paths.size());
  std::iota(v.begin(), v.end(), 0);

  std::sort(v.begin(), v.end(), [&paths](size_t const &lhs, size_t const &rhs) -> bool {
    auto s1First = paths[lhs].rbegin(), s1Last = paths[lhs].rend();
    auto s2First = paths[rhs].rbegin(), s2Last = paths[rhs].rend();
    while (s1First != s1Last && s2First != s2Last) {
      if (*s1First < *s2First)
        return true;
      else if (*s1First != *s2First)
        return false;
      ++s1First, ++s2First;
    }
    return s1First == s1Last && s2First != s2Last;
  });

  std::vector<size_t> levels(paths.size());
  for (size_t i = 0; i < v.size();) {
    std::string const &current = paths[v[i]];
    size_t above = 0, below = 0;

    if (i != 0)
      above = count_slashes(current, paths[v[i - 1]]);

    size_t j = i;
    while (j < v.size() && current == paths[v[j]])
      ++j;
    if (j < v.size())
      below = count_slashes(current, paths[v[j]]);

    for (; i < j; ++i)
      levels[v[i]] = std::max(above, below);
  }

  return levels;
}

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

    std::vector<std::pair<NSUInteger, NSUInteger>> chunkedIndexes = chunked_indexes(result.count, qArrayChunkSize);
    for (auto &pair : chunkedIndexes) {
      CANCEL_WHEN_REQUESTED
      
      NSUInteger beginIndex = pair.first;
      NSUInteger endIndex = pair.second;
      NSUInteger count = endIndex - beginIndex + 1;

      dispatch_apply(count, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(size_t i) {
        [result[beginIndex + i] computeScoreForCandidate:_searchStr];
      });
    }

    CANCEL_WHEN_REQUESTED

    [result sortUsingComparator:qScoredItemComparator];

    std::vector<std::string> paths;
    for (VRScoredPath *scoredPath in result) {
      paths.push_back(cf::to_s((__bridge CFStringRef) scoredPath.path));
    }

    std::vector<size_t> levels = disambiguate(paths);
    chunkedIndexes = chunked_indexes((NSUInteger) levels.size(), qArrayChunkSize);
    for (auto &pair : chunkedIndexes) {
      CANCEL_WHEN_REQUESTED

      NSUInteger beginIndex = pair.first;
      NSUInteger endIndex = pair.second;
      NSUInteger count = endIndex - beginIndex + 1;

      dispatch_apply(count, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(size_t i) {
        size_t level = levels[i];
        VRScoredPath *scoredPath = result[i];
        NSURL *url = [NSURL fileURLWithPath:scoredPath.path];

        NSArray *disambiguationPathComponents = [url.pathComponents.reverseObjectEnumerator.allObjects
            subarrayWithRange:NSMakeRange(1, level)
        ];

        if (disambiguationPathComponents.isEmpty) {
          scoredPath.displayName = url.lastPathComponent;
        } else {
          NSString *disambiguation = [disambiguationPathComponents componentsJoinedByString:@"/"];
          scoredPath.displayName = SF(@"%@  —  %@", url.lastPathComponent, disambiguation);
        }
      });
    }

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
