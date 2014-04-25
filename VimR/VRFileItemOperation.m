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


#define LOG_FLAG_CACHING (1 << 5)
#define DDLogCaching(frmt, ...) ASYNC_LOG_OBJC_MAYBE(ddLogLevel, LOG_FLAG_CACHING,  0, frmt, ##__VA_ARGS__)
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
  @synchronized (self) {
    return _shouldPause;
  }
}

- (void)pause {
  @synchronized (self) {
    [_pauseCondition lock];
    _shouldPause = YES;
    [_pauseCondition signal];
    [_pauseCondition unlock];
  }
}

- (void)resume {
  @synchronized (self) {
    [_pauseCondition lock];
    _shouldPause = NO;
    [_pauseCondition signal];
    [_pauseCondition unlock];
  }
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
    NSURL *parentUrl = _parentItem.url;

    // Necessary?
    if (_parentItem.isCachingChildren) {
      DDLogCaching(@"File item %@ is currently being cached, noop.", parentUrl);
      return;
    }

    if ([self isCancelled]) {
      DDLogCaching(@"Cancelling the traversing as requested at %@", parentUrl);
      return;
    }
    [self wait];

    if (_parentItem.shouldCacheChildren) {
      // We remove all children when shouldCacheChildren is on, because we do not deep-scan in background, but only set
      // shouldCacheChildren to YES, ie invalidate the cache.
      [_parentItem.children removeAllObjects];

      [_operationQueue addOperation:
          [[VRFileItemOperation alloc] initWithMode:VRFileItemOperationCacheMode
                                               dict:@{
                                                   qFileItemOperationRootUrlKey : _rootUrl,
                                                   qFileItemOperationParentItemKey : _parentItem,
                                                   qFileItemOperationOperationQueueKey : _operationQueue,
                                                   qFileItemOperationFileItemManagerKey : _fileItemManager,
                                                   qFileItemOperationNotificationCenterKey : _notificationCenter,
                                                   qFileItemOperationFileItemsKey : _fileItems,
                                                   qFileItemOperationFileManagerKey : _fileManager,
                                               }]
      ];

      return;
    }

    DDLogCaching(@"Children of %@ already cached, traversing or adding.", parentUrl);

    NSMutableArray *fileItemsToAdd = [[NSMutableArray alloc] initWithCapacity:_parentItem.children.count];
    for (VRFileItem *child in _parentItem.children) {
      NSURL *childUrl = child.url;

      if ([self isCancelled]) {
        DDLogCaching(@"Cancelling the traversing as requested at %@", childUrl);
        return;
      }
      [self wait];

      if (child.dir) {
        DDLogCaching(@"Traversing children of %@", childUrl);
        [_operationQueue addOperation:
            [[VRFileItemOperation alloc] initWithMode:VRFileItemOperationTraverseMode
                                                 dict:@{
                                                     qFileItemOperationRootUrlKey : _rootUrl,
                                                     qFileItemOperationParentItemKey : child,
                                                     qFileItemOperationOperationQueueKey : _operationQueue,
                                                     qFileItemOperationFileItemManagerKey : _fileItemManager,
                                                     qFileItemOperationNotificationCenterKey : _notificationCenter,
                                                     qFileItemOperationFileItemsKey : _fileItems,
                                                     qFileItemOperationFileManagerKey : _fileManager,
                                                 }]
        ];
      } else {
        [fileItemsToAdd addObject:child];
      }
    }

    if ([self isCancelled]) {
      DDLogCaching(@"Cancelling the traversing as requested at %@", parentUrl);
      return;
    }
    [self wait];

    [self addAllToFileItemsForTargetUrl:fileItemsToAdd];
  }
}

- (void)cacheAddToFileItems {
  @autoreleasepool {
    NSURL *parentUrl = _parentItem.url;

    if ([self isCancelled]) {
      DDLogCaching(@"Cancelling the scanning as requested at %@", parentUrl);
      return;
    }
    [self wait];

    DDLogCaching(@"Building children for %@", parentUrl);

    _parentItem.isCachingChildren = YES;

    NSArray *childUrls = [_fileManager contentsOfDirectoryAtURL:parentUrl
                                     includingPropertiesForKeys:@[NSURLIsDirectoryKey]
                                                        options:NSDirectoryEnumerationSkipsPackageDescendants
                                                          error:NULL];
    NSMutableArray *childrenOfParent = _parentItem.children;

    for (NSURL *childUrl in childUrls) {
      [childrenOfParent addObject:[[VRFileItem alloc] initWithUrl:childUrl isDir:childUrl.isDirectory]];
    }

    _parentItem.shouldCacheChildren = NO; // because shouldCacheChildren means, "should add direct descendants"
    _parentItem.isCachingChildren = NO; // direct descendants scanning is done

    if (childrenOfParent.isEmpty) {
      return;
    }

    if ([self isCancelled]) {
      DDLogCaching(@"Cancelling the scanning as requested at %@", parentUrl);
      return;
    }
    [self wait];

    [self addAllToFileItemsForTargetUrl:childrenOfParent];

    for (VRFileItem *child in childrenOfParent) {
      if ([self isCancelled]) {
        DDLogCaching(@"Cancelling the scanning as requested at %@", child.url);
        return;
      }
      [self wait];

      if (child.dir) {
        [_operationQueue addOperation:
            [[VRFileItemOperation alloc] initWithMode:VRFileItemOperationCacheMode
                                                 dict:@{
                                                     qFileItemOperationRootUrlKey : _rootUrl,
                                                     qFileItemOperationParentItemKey : child,
                                                     qFileItemOperationOperationQueueKey : _operationQueue,
                                                     qFileItemOperationFileItemManagerKey : _fileItemManager,
                                                     qFileItemOperationNotificationCenterKey : _notificationCenter,
                                                     qFileItemOperationFileItemsKey : _fileItems,
                                                     qFileItemOperationFileManagerKey : _fileManager,
                                                 }]
        ];
      }
    }
  }
}

- (void)addAllToFileItemsForTargetUrl:(NSArray *)items {
  BOOL added = NO;
  for (VRFileItem *child in items) {
    if (!child.dir) {
      [_fileItems addObject:child.url.path];
      added = YES;
    }
  }

  if (!added) {
    return;
  }

  NSURL *parentUrl = [[items[0] url] URLByDeletingLastPathComponent];
  DDLogCaching(@"Adding children of %@ to file items array", parentUrl);

  dispatch_async(dispatch_get_main_queue(), ^{
    [_notificationCenter postNotificationName:qChunkOfNewFileItemsAddedEvent object:parentUrl];
  });
}

@end
