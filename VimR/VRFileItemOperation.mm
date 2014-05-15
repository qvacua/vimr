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
#import "NSURL+VR.h"
#import "NSArray+VR.h"
#import "VRCppUtils.h"
#import "VRCachingLogSetting.h"


NSString *const qFileItemOperationOperationQueueKey = @"operation-queue";
NSString *const qFileItemOperationNotificationCenterKey = @"notification-center";
NSString *const qFileItemOperationFileManagerKey = @"file-manager";
NSString *const qFileItemOperationParentItemKey = @"parent-file-item";
NSString *const qFileItemOperationRootUrlKey = @"root-url";
NSString *const qFileItemOperationFileItemsKey = @"file-items-array";


static const int qArrayChunkSize = 50;


#define CANCEL_OR_WAIT if ([self isCancelled]) { \
                         return; \
                       }

#define CANCEL_OR_WAIT_BLOCK ^BOOL { \
                               if ([self isCancelled]) { \
                                 return YES; \
                               } \
                               return NO; \
                             }


@implementation VRFileItemOperation {
  VRFileItemOperationMode _mode;

  __weak NSOperationQueue *_operationQueue;
  __weak NSFileManager *_fileManager;
  __weak NSNotificationCenter *_notificationCenter;
  __weak VRFileItem *_parentItem;
  __weak NSMutableArray *_fileItems;

  NSURL *_rootUrl;
}

#pragma mark Public
- (id)initWithMode:(VRFileItemOperationMode)mode dict:(NSDictionary *)dict {
  self = [super init];
  RETURN_NIL_WHEN_NOT_SELF

  _mode = mode;

  _operationQueue = dict[qFileItemOperationOperationQueueKey];
  _notificationCenter = dict[qFileItemOperationNotificationCenterKey];
  _fileManager = dict[qFileItemOperationFileManagerKey];
  _parentItem = dict[qFileItemOperationParentItemKey];
  _rootUrl = [dict[qFileItemOperationRootUrlKey] copy];
  _fileItems = dict[qFileItemOperationFileItemsKey];

#ifdef DEBUG
  setup_file_logger();
#endif

  return self;
}

#pragma mark NSOperation
- (void)main {
  if (_mode == VRFileItemOperationTraverseMode) {
    [self traverseFileItemChildHierarchy];
    return;
  }

  if (_mode == VRFileItemOperationCacheMode) {
    [self cacheAddToFileItems];
    return;
  }

  if (_mode == VRFileItemOperationShallowCacheMode) {
    DDLogDebug(@"shallow caching %@", _parentItem);
    [self cacheDirectDescendants];
    return;
  }
}

#pragma mark Private
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

      [_operationQueue addOperation:[self operationForParent:_parentItem mode:VRFileItemOperationCacheMode]];

      return;
    }

    DDLogCaching(@"Children of %@ already cached, traversing or adding.", _parentItem.url);

    NSUInteger parentChildrenCount = children.count;
    if (parentChildrenCount == 0) {
      return;
    }

    NSMutableArray *fileItemsToAdd = [[NSMutableArray alloc] initWithCapacity:parentChildrenCount];
    BOOL wasComplete = chunk_enumerate_array(children, qArrayChunkSize, CANCEL_OR_WAIT_BLOCK, ^(VRFileItem *child) {
      if (child.dir) {
        DDLogCaching(@"Traversing children of %@", child.url);
        [_operationQueue addOperation:[self operationForParent:child mode:VRFileItemOperationTraverseMode]];
      } else {
        [fileItemsToAdd addObject:child];
      }
    });
    if (!wasComplete) {
      return;
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
    [self cacheDirectDescendants];

    NSMutableArray *children = _parentItem.children;
    if (children.isEmpty) {
      return;
    }

    CANCEL_OR_WAIT

    DDLogCaching(@"### Adding (from caching) children items of parent: %@", _parentItem.url);
    [self addAllToFileItemsForTargetUrl:children];

    chunk_enumerate_array(children, qArrayChunkSize, CANCEL_OR_WAIT_BLOCK, ^(VRFileItem *child) {
      if (child.dir) {
        [_operationQueue addOperation:[self operationForParent:child mode:VRFileItemOperationCacheMode]];
      }
    });
  }
}

- (void)cacheDirectDescendants {
  _parentItem.isCachingChildren = YES;

  NSArray *childUrls = [_fileManager contentsOfDirectoryAtURL:_parentItem.url
                                   includingPropertiesForKeys:@[NSURLIsDirectoryKey]
                                                      options:NSDirectoryEnumerationSkipsPackageDescendants
                                                        error:NULL];

  NSMutableArray *children = _parentItem.children;
  [children removeAllObjects];
  for (NSURL *childUrl in childUrls) {
      [children addObject:[[VRFileItem alloc] initWithUrl:childUrl isDir:childUrl.isDirectory]];
    }

  // When the monitoring thread invalidates cache of this item before this line, then we will have an outdated
  // children, however, we don't really care...
  _parentItem.shouldCacheChildren = NO; // because shouldCacheChildren means, "should add direct descendants"
  _parentItem.isCachingChildren = NO; // direct descendants scanning is done
}

- (void)addAllToFileItemsForTargetUrl:(NSArray *)items {
  __block BOOL added = NO;

  @synchronized (_fileItems) {
    BOOL shouldReturn = chunk_enumerate_array(items, qArrayChunkSize, CANCEL_OR_WAIT_BLOCK, ^(VRFileItem *child) {
      if (!child.dir) {
        [_fileItems addObject:child.url.path];
        added = YES;
      }
    });

    if (shouldReturn) {
      return;
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

- (VRFileItemOperation *)operationForParent:(VRFileItem *)parent mode:(VRFileItemOperationMode)mode {
  return [[VRFileItemOperation alloc] initWithMode:mode
                                              dict:@{
                                                  qFileItemOperationRootUrlKey : _rootUrl,
                                                  qFileItemOperationParentItemKey : parent,
                                                  qFileItemOperationOperationQueueKey : _operationQueue,
                                                  qFileItemOperationNotificationCenterKey : _notificationCenter,
                                                  qFileItemOperationFileItemsKey : _fileItems,
                                                  qFileItemOperationFileManagerKey : _fileManager,
                                              }];
}

@end
