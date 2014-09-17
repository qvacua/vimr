/**
* Tae Won Ha — @hataewon
*
* http://taewon.de
* http://qvacua.com
*
* See LICENSE
*/

#import "VRFileItemOperation.h"
#import "VRUtils.h"
#import "VRFileItemManager.h"
#import "VRFileItem.h"
#import "NSArray+VR.h"
#import "VRCppUtils.h"
#import "VRCachingLogSetting.h"
#import "NSMutableArray+VR.h"


NSString *const qFileItemOperationOperationQueueKey = @"operation-queue";
NSString *const qFileItemOperationParentItemKey = @"parent-file-item";
NSString *const qFileItemOperationRootUrlKey = @"root-url";
NSString *const qFileItemOperationUrlsForTargetUrlKey = @"file-items-array";
NSString *const qFileItemOperationPauseConditionKey = @"condition";


static const int qArrayChunkSize = 1000;
static NSArray *qKeysToCache;


#define CANCEL_OR_WAIT(rv) if ([self isCancelled]) { \
                             return rv; \
                           } \
                           [_condition lock]; \
                           while (_paused) { \
                             [_condition wait]; \
                           } \
                           [_condition unlock]; \


@implementation VRFileItemOperation {
  VRFileItemOperationMode _mode;

  __weak VRFileItemManager *_fileItemManager;
  __weak NSFileManager *_fileManager;

  __weak VRFileItem *_item;
  __weak NSMutableArray *_urlsForTargetUrl;

  __weak NSCondition *_condition;
  BOOL _paused;
}

#pragma mark Public
- (void)pause {
  _paused = YES;
}

- (void)resume {
  _paused = NO;
}

- (id)initWithMode:(VRFileItemOperationMode)mode dict:(NSDictionary *)dict {
  self = [super init];
  RETURN_NIL_WHEN_NOT_SELF

  _mode = mode;

  _fileItemManager = dict[qOperationFileItemManagerKey];
  _fileManager = dict[qOperationFileManagerKey];
  _item = dict[qFileItemOperationParentItemKey];
  _urlsForTargetUrl = dict[qFileItemOperationUrlsForTargetUrlKey];

  _condition = dict[qFileItemOperationPauseConditionKey];
  _paused = NO;

#ifdef DEBUG
  setup_file_logger();
#endif

  return self;
}

#pragma mark NSOperation
- (void)main {
  @autoreleasepool {
    // Necessary?
    if (_item.isCachingChildren) {
      DDLogCaching(@"File item %@ is currently being cached, noop.", _item.url);
      return;
    }

    if (_mode == VRFileItemOperationTraverseMode) {
      [self traverse];
      return;
    }

    if (_mode == VRFileItemOperationShallowCacheMode) {
      [self cacheDirectDescendants:_item];
      return;
    }
  }
}

#pragma mark NSObject
+ (void)initialize {
  [super initialize];

  if (!qKeysToCache) {
    qKeysToCache = @[NSURLIsDirectoryKey, NSURLIsHiddenKey, NSURLIsAliasFileKey, NSURLIsSymbolicLinkKey,];
  }
}

#pragma mark Private
- (void)traverse {
  // pre-order traversal

  VRStack *stack = [[VRStack alloc] initWithCapacity:10000];
  [stack push:_item];

  CANCEL_OR_WAIT()
  __weak VRFileItem *currentItem;
  while (stack.count > 0) {
    currentItem = [stack pop];

    @synchronized (currentItem) {
      NSMutableArray *childrenOfCurrentItem = currentItem.children;

      CANCEL_OR_WAIT()
      if (currentItem.shouldCacheChildren) {
        [childrenOfCurrentItem removeAllObjects];

        [self cacheDirectDescendants:currentItem];
      }

      if (childrenOfCurrentItem.isEmpty) {
        continue;
      }

      CANCEL_OR_WAIT()
      NSMutableArray *fileItemsToAdd = [[NSMutableArray alloc] initWithCapacity:childrenOfCurrentItem.count];
      BOOL operationCancelled =
          [self chunkEnumerateArray:childrenOfCurrentItem usingBlockOnChunks:^(size_t beginIndex, size_t endIndex) {
            for (size_t i = beginIndex; i <= endIndex; i++) {
              VRFileItem *item = childrenOfCurrentItem[i];
              if (item.dir) {
                [stack push:item];
              } else {
                [fileItemsToAdd addObject:item];
              }
            }
          }];

      if (!operationCancelled) {
        return;
      }

      if (fileItemsToAdd.isEmpty) {
        continue;
      }

      [self addAllToUrlsForTargetUrl:childrenOfCurrentItem];
    }
  }
}

- (void)cacheDirectDescendants:(__weak VRFileItem *)item {
  @synchronized (item) {
    item.isCachingChildren = YES;

    if (item.url == nil) {
      DDLogError(@"url of %@ is nil", item);
    }

    NSArray *childUrls = [_fileManager contentsOfDirectoryAtURL:item.url includingPropertiesForKeys:qKeysToCache
                                                        options:NSDirectoryEnumerationSkipsPackageDescendants
                                                          error:NULL];

    NSMutableArray *children = item.children;
    [children removeAllObjects];
    for (NSURL *childUrl in childUrls) {
      [children addObject:[[VRFileItem alloc] initWithUrl:childUrl]];
    }

    // When the monitoring thread invalidates cache of this item before this line, then we will have an outdated
    // children, however, we don't really care...
    item.shouldCacheChildren = NO; // because shouldCacheChildren means, "should add direct descendants"
    item.isCachingChildren = NO; // direct descendants scanning is done
  }
}

- (BOOL)addAllToUrlsForTargetUrl:(__weak NSArray *)items {
  __block BOOL added = NO;

  BOOL enumerationComplete = [self chunkEnumerateArray:items usingBlockOnChunks:^(size_t beginIndex, size_t endIndex) {
    @synchronized (_urlsForTargetUrl) {
      for (size_t i = beginIndex; i <= endIndex; i++) {
        VRFileItem *child = items[i];

        if (!child.dir) {
          [_urlsForTargetUrl addObject:child.url];
          added = YES;
        }
      }
    }
  }];

  if (!enumerationComplete || !added) {
    return NO;
  }

  dispatch_to_main_thread(^{
    [NSObject cancelPreviousPerformRequestsWithTarget:_fileItemManager];
    [_fileItemManager performSelector:@selector(postNewFileItemsAddedNotification:) withObject:nil afterDelay:0.5];
  });

  return YES;
}

/**
* shouldStopBeforeChunk() is called before each chunk execution and if it returns YES, we stop and return NO, ie
* the enumeration was not complete, but was cancelled.
*/
- (BOOL)chunkEnumerateArray:(__weak NSArray *)array usingBlockOnChunks:(void (^)(size_t beginIndex, size_t endIndex))blockOnChunks {
  std::vector<std::pair<size_t, size_t>> chunkedIndexes = chunked_indexes(array.count, qArrayChunkSize);
  for (auto &pair : chunkedIndexes) {
    CANCEL_OR_WAIT(NO)

    size_t beginIndex = pair.first;
    size_t endIndex = pair.second;

    blockOnChunks(beginIndex, endIndex);
  }

  return YES;
}

@end
