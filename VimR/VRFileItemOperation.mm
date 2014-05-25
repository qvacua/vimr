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


NSString *const qFileItemOperationOperationQueueKey = @"operation-queue";
NSString *const qFileItemOperationParentItemKey = @"parent-file-item";
NSString *const qFileItemOperationRootUrlKey = @"root-url";
NSString *const qFileItemOperationUrlsForTargetUrlKey = @"file-items-array";


static const int qArrayChunkSize = 1000;


#define CANCEL_WHEN_REQUESTED if ([self isCancelled]) { \
                                return; \
                              }


@implementation VRFileItemOperation {
  VRFileItemOperationMode _mode;

  __weak VRFileItemManager *_fileItemManager;
  __weak NSOperationQueue *_operationQueue;
  __weak NSFileManager *_fileManager;

  __weak VRFileItem *_item;
  __weak NSMutableArray *_urlsForTargetUrl;

  NSURL *_rootUrl;
}

#pragma mark Public
- (id)initWithMode:(VRFileItemOperationMode)mode dict:(NSDictionary *)dict {
  self = [super init];
  RETURN_NIL_WHEN_NOT_SELF

  _mode = mode;

  _fileItemManager = dict[qOperationFileItemManagerKey];
  _operationQueue = dict[qFileItemOperationOperationQueueKey];
  _fileManager = dict[qOperationFileManagerKey];
  _item = dict[qFileItemOperationParentItemKey];
  _rootUrl = [dict[qFileItemOperationRootUrlKey] copy];
  _urlsForTargetUrl = dict[qFileItemOperationUrlsForTargetUrlKey];

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

    @synchronized (_item) {
      if (_mode == VRFileItemOperationTraverseMode) {
        [self traverseFileItemChildHierarchy];
        return;
      }

      if (_mode == VRFileItemOperationCacheMode) {
        [self cacheAddToFileItems];
        return;
      }

      if (_mode == VRFileItemOperationShallowCacheMode) {
        [self cacheDirectDescendants];
        return;
      }
    }
  }
}

#pragma mark Private
- (void)traverseFileItemChildHierarchy {
  CANCEL_WHEN_REQUESTED

  NSMutableArray *children = _item.children;
  if (_item.shouldCacheChildren) {
    // We remove all children when shouldCacheChildren is on, because we do not deep-scan in background, but only set
    // shouldCacheChildren to YES, ie invalidate the cache.
    [children removeAllObjects];

    [_operationQueue addOperation:[self operationForParent:_item mode:VRFileItemOperationCacheMode]];

    return;
  }

  DDLogCaching(@"Children of %@ already cached, traversing or adding.", _item.url);

  NSUInteger parentChildrenCount = children.count;
  if (parentChildrenCount == 0) {
    return;
  }

  NSMutableArray *fileItemsToAdd = [[NSMutableArray alloc] initWithCapacity:parentChildrenCount];

  BOOL enumerationComplete = [self chunkEnumerateArray:children usingBlock:^(VRFileItem *child) {
    if (child.dir) {
      DDLogCaching(@"Traversing children of %@", child.url);
      [_operationQueue addOperation:[self operationForParent:child mode:VRFileItemOperationTraverseMode]];
    } else {
      [fileItemsToAdd addObject:child];
    }
  }];

  if (!enumerationComplete) {
    return;
  }

  if (fileItemsToAdd.isEmpty) {
    return;
  }

  CANCEL_WHEN_REQUESTED

      DDLogCaching(@"### Adding (from traversing) children items of parent: %@", _item.url);
  [self addAllToUrlsForTargetUrl:fileItemsToAdd];
}

- (void)cacheAddToFileItems {
  CANCEL_WHEN_REQUESTED

      DDLogCaching(@"Caching children for %@", _item.url);
  [self cacheDirectDescendants];

  NSMutableArray *children = _item.children;
  if (children.isEmpty) {
    return;
  }

  CANCEL_WHEN_REQUESTED

      DDLogCaching(@"### Adding (from caching) children items of parent: %@", _item.url);
  [self addAllToUrlsForTargetUrl:children];

  [self chunkEnumerateArray:children usingBlock:^(VRFileItem *child) {
    if (child.dir) {
      [_operationQueue addOperation:[self operationForParent:child mode:VRFileItemOperationCacheMode]];
    }
  }];
}

- (void)cacheDirectDescendants {
  _item.isCachingChildren = YES;

  if (_item.url == nil) {
    DDLogError(@"url of %@ is nil", _item);
  }

  NSArray *childUrls = [_fileManager contentsOfDirectoryAtURL:_item.url
                                   includingPropertiesForKeys:@[NSURLIsDirectoryKey, NSURLIsHiddenKey,]
                                                      options:NSDirectoryEnumerationSkipsPackageDescendants
                                                        error:NULL];

  NSMutableArray *children = _item.children;
  [children removeAllObjects];
  for (NSURL *childUrl in childUrls) {
    [children addObject:[[VRFileItem alloc] initWithUrl:childUrl]];
  }

  // When the monitoring thread invalidates cache of this item before this line, then we will have an outdated
  // children, however, we don't really care...
  _item.shouldCacheChildren = NO; // because shouldCacheChildren means, "should add direct descendants"
  _item.isCachingChildren = NO; // direct descendants scanning is done
}

- (void)addAllToUrlsForTargetUrl:(NSArray *)items {
  @synchronized (_urlsForTargetUrl) {
    __block BOOL added = NO;

    BOOL enumerationComplete = [self chunkEnumerateArray:items usingBlock:^(VRFileItem *child) {
      if (!child.dir) {
        [_urlsForTargetUrl addObject:child.url];
        added = YES;
      }
    }];

    if (!enumerationComplete || !added) {
      return;
    }
  }

  dispatch_to_main_thread(^{
    [NSObject cancelPreviousPerformRequestsWithTarget:_fileItemManager];
    [_fileItemManager performSelector:@selector(postNewFileItemsAddedNotification:) withObject:nil afterDelay:0.5];
  });
}

- (VRFileItemOperation *)operationForParent:(VRFileItem *)parent mode:(VRFileItemOperationMode)mode {
  return [[VRFileItemOperation alloc] initWithMode:mode
                                              dict:@{
                                                  qFileItemOperationRootUrlKey : _rootUrl,
                                                  qFileItemOperationParentItemKey : parent,
                                                  qFileItemOperationUrlsForTargetUrlKey : _urlsForTargetUrl,
                                                  qOperationFileItemManagerKey : _fileItemManager,
                                                  qFileItemOperationOperationQueueKey : _operationQueue,
                                                  qOperationFileManagerKey : _fileManager,
                                              }];
}

/**
* shouldStopBeforeChunk() is called before each chunk execution and if it returns YES, we stop and return NO, ie
* the enumeration was not complete, but was cancelled.
*/
- (BOOL)chunkEnumerateArray:(NSArray *)array usingBlock:(void (^)(VRFileItem *))blockOnChild {
  std::vector<std::pair<size_t, size_t>> chunkedIndexes = chunked_indexes(array.count, qArrayChunkSize);
  for (auto &pair : chunkedIndexes) {
    if (self.isCancelled) {
      return NO;
    }

    size_t beginIndex = pair.first;
    size_t endIndex = pair.second;

    for (size_t i = beginIndex; i <= endIndex; i++) {
      blockOnChild(array[i]);
    }
  }

  return YES;
}

@end
