/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import <CocoaLumberjack/DDFileLogger.h>
#import "VRFileItemOperation.h"
#import "VRUtils.h"
#import "VRFileItemManager.h"
#import "VRFileItem.h"
#import "NSURL+VR.h"
#import "NSArray+VR.h"
#import "VRCppUtils.h"


#define LOG_FLAG_CACHING (1 << 5)
#define DDLogCaching(fmt, ...) ASYNC_LOG_OBJC_MAYBE(ddLogLevel, LOG_FLAG_CACHING,  0, fmt, ##__VA_ARGS__)
static const int ddLogLevel = LOG_LEVEL_DEBUG;
//static const int ddLogLevel = LOG_LEVEL_DEBUG | LOG_FLAG_CACHING;
static DDFileLogger *file_logger_for_cache;


static void setup_file_logger() {
  static dispatch_once_t once_token;

  dispatch_once(&once_token, ^{
    file_logger_for_cache = [[DDFileLogger alloc] init];
    file_logger_for_cache.maximumFileSize = 20 * (1024 * 1024); // 20 MB
    [DDLog addLogger:file_logger_for_cache withLogLevel:LOG_FLAG_CACHING];
  });
}


NSString *const qFileItemOperationOperationQueueKey = @"operation-queue";
NSString *const qFileItemOperationFileItemManagerKey = @"file-item-manager";
NSString *const qFileItemOperationNotificationCenterKey = @"notification-center";
NSString *const qFileItemOperationFileManagerKey = @"file-manager";
NSString *const qFileItemOperationParentItemKey = @"parent-file-item";
NSString *const qFileItemOperationRootUrlKey = @"root-url";
NSString *const qFileItemOperationFileItemsKey = @"file-items-array";


static const int qArrayChunkSize = 50;


#define CANCEL_OR_WAIT if ([self isCancelled]) { \
                         return; \
                       } \
                       [self wait];


@implementation VRFileItemOperation {
  VRFileItemOperationMode _mode;

  __weak NSOperationQueue *_operationQueue;
  __weak VRFileItemManager *_fileItemManager;
  __weak NSFileManager *_fileManager;
  __weak NSNotificationCenter *_notificationCenter;
  __weak VRFileItem *_parentItem;
  __weak NSMutableArray *_fileItems;

  NSURL *_rootUrl;

  NSCondition *_pauseCondition;
  BOOL _shouldPause;
}

#pragma mark Public
- (BOOL)isPaused {
  @synchronized (_pauseCondition) {
    return _shouldPause;
  }
}

- (void)pause {
  [_pauseCondition lock];
  _shouldPause = YES;
  [_pauseCondition signal];
  [_pauseCondition unlock];
}

- (void)resume {
  [_pauseCondition lock];
  _shouldPause = NO;
  [_pauseCondition signal];
  [_pauseCondition unlock];
}

- (id)initWithMode:(VRFileItemOperationMode)mode dict:(NSDictionary *)dict {
  self = [super init];
  RETURN_NIL_WHEN_NOT_SELF

  _mode = mode;

  _operationQueue = dict[qFileItemOperationOperationQueueKey];
  _fileItemManager = dict[qFileItemOperationFileItemManagerKey];
  _notificationCenter = dict[qFileItemOperationNotificationCenterKey];
  _fileManager = dict[qFileItemOperationFileManagerKey];
  _parentItem = dict[qFileItemOperationParentItemKey];
  _rootUrl = [dict[qFileItemOperationRootUrlKey] copy];
  _fileItems = dict[qFileItemOperationFileItemsKey];

  _shouldPause = NO;
  _pauseCondition = [[NSCondition alloc] init];

#ifdef DEBUG
  setup_file_logger();
#endif

  return self;
}

#pragma mark NSOperation
- (void)main {
  if (_mode == VRFileItemOperationTraverseMode) {
    [self traverseFileItemChildHierarchy];
  } else {
    [self cacheAddToFileItems];
  }
}

#pragma mark Private
- (void)wait {
  [_pauseCondition lock];
  while (_shouldPause) {
    [_pauseCondition wait];
  }
  [_pauseCondition unlock];
}

- (void)traverseFileItemChildHierarchy {
  @autoreleasepool {
    // Necessary?
    if (_parentItem.isCachingChildren) {
      DDLogCaching(@"File item %@ is currently being cached, noop.", _parentItem.url);
      return;
    }

    CANCEL_OR_WAIT

    NSMutableArray *children = _parentItem.children;
    if (_parentItem.shouldCacheChildren) {
      // We remove all children when shouldCacheChildren is on, because we do not deep-scan in background, but only set
      // shouldCacheChildren to YES, ie invalidate the cache.
      [children removeAllObjects];

      [_operationQueue addOperation:[self cacheOperationForParent:_parentItem]];

      return;
    }

    DDLogCaching(@"Children of %@ already cached, traversing or adding.", _parentItem.url);

    NSUInteger parentChildrenCount = children.count;
    NSMutableArray *fileItemsToAdd = [[NSMutableArray alloc] initWithCapacity:parentChildrenCount];

    std::vector<std::pair<size_t, size_t>> chunkedIndexes = chunked_indexes(parentChildrenCount, qArrayChunkSize);
    for (auto &pair : chunkedIndexes) {
      CANCEL_OR_WAIT

      size_t beginIndex = pair.first;
      size_t endIndex = pair.second;

      for (size_t i = beginIndex; i <= endIndex; i++) {
        VRFileItem *child = children[i];

        if (child.dir) {
          DDLogCaching(@"Traversing children of %@", child.url);
          [_operationQueue addOperation:[self traverseOperationForParent:child]];
        } else {
          [fileItemsToAdd addObject:child];
        }
      }
    }

    if (fileItemsToAdd.isEmpty) {
      return;
    }

    CANCEL_OR_WAIT

    DDLogCaching(@"### Adding (from traversing) children items of parent: %@", _parentItem.url);
    [self addAllToFileItemsForTargetUrl:fileItemsToAdd];
  }
}

- (void)cacheAddToFileItems {
  @autoreleasepool {
    CANCEL_OR_WAIT

    DDLogCaching(@"Caching children for %@", _parentItem.url);

    _parentItem.isCachingChildren = YES;

    NSArray *childUrls = [_fileManager contentsOfDirectoryAtURL:_parentItem.url
                                     includingPropertiesForKeys:@[NSURLIsDirectoryKey]
                                                        options:NSDirectoryEnumerationSkipsPackageDescendants
                                                          error:NULL];

    [self wait];

    NSMutableArray *childrenOfParent = _parentItem.children;
    [childrenOfParent removeAllObjects];
    for (NSURL *childUrl in childUrls) {
      [childrenOfParent addObject:[[VRFileItem alloc] initWithUrl:childUrl isDir:childUrl.isDirectory]];
    }

    // When the monitoring thread invalidates cache of this item before this line, then we will have an outdated
    // children, however, we don't really care...
    _parentItem.shouldCacheChildren = NO; // because shouldCacheChildren means, "should add direct descendants"
    _parentItem.isCachingChildren = NO; // direct descendants scanning is done

    if (childrenOfParent.isEmpty) {
      return;
    }

    CANCEL_OR_WAIT

    DDLogCaching(@"### Adding (from caching) children items of parent: %@", _parentItem.url);
    [self addAllToFileItemsForTargetUrl:childrenOfParent];

    std::vector<std::pair<size_t, size_t>> chunkedIndexes = chunked_indexes(childrenOfParent.count, qArrayChunkSize);
    for (auto &pair : chunkedIndexes) {
      CANCEL_OR_WAIT

      size_t beginIndex = pair.first;
      size_t endIndex = pair.second;

      for (size_t i = beginIndex; i <= endIndex; i++) {
        VRFileItem *child = childrenOfParent[i];

        if (child.dir) {
          [_operationQueue addOperation:[self cacheOperationForParent:child]];
        }
      }
    }
  }
}

- (void)addAllToFileItemsForTargetUrl:(NSArray *)items {
  BOOL added = NO;

  std::vector<std::pair<size_t, size_t>> chunkedIndexes = chunked_indexes(items.count, qArrayChunkSize);
  for (auto &pair : chunkedIndexes) {
    CANCEL_OR_WAIT

    size_t beginIndex = pair.first;
    size_t endIndex = pair.second;

    @synchronized (_fileItems) {
      for (size_t i = beginIndex; i <= endIndex; i++) {
        VRFileItem *child = items[i];
        if (!child.dir) {
          [_fileItems addObject:child.url.path];
          added = YES;
        }
      }
    }
  }

  if (!added) {
    return;
  }

  NSURL *parentUrl = [[items[0] url] URLByDeletingLastPathComponent];
  DDLogCaching(@"Adding children of %@ to file items array", parentUrl);

  dispatch_to_main_thread(^{
    [_notificationCenter postNotificationName:qChunkOfNewFileItemsAddedEvent object:parentUrl];
  });
}

- (VRFileItemOperation *)traverseOperationForParent:(VRFileItem *)parent {
  return [[VRFileItemOperation alloc] initWithMode:VRFileItemOperationTraverseMode
                                              dict:@{
                                                  qFileItemOperationRootUrlKey : _rootUrl,
                                                  qFileItemOperationParentItemKey : parent,
                                                  qFileItemOperationOperationQueueKey : _operationQueue,
                                                  qFileItemOperationFileItemManagerKey : _fileItemManager,
                                                  qFileItemOperationNotificationCenterKey : _notificationCenter,
                                                  qFileItemOperationFileItemsKey : _fileItems,
                                                  qFileItemOperationFileManagerKey : _fileManager,
                                              }];
}

- (VRFileItemOperation *)cacheOperationForParent:(VRFileItem *)parent {
  return [[VRFileItemOperation alloc] initWithMode:VRFileItemOperationCacheMode
                                              dict:@{
                                                  qFileItemOperationRootUrlKey : _rootUrl,
                                                  qFileItemOperationParentItemKey : parent,
                                                  qFileItemOperationOperationQueueKey : _operationQueue,
                                                  qFileItemOperationFileItemManagerKey : _fileItemManager,
                                                  qFileItemOperationNotificationCenterKey : _notificationCenter,
                                                  qFileItemOperationFileItemsKey : _fileItems,
                                                  qFileItemOperationFileManagerKey : _fileManager,
                                              }];
}

@end
