/**
* Tae Won Ha — @hataewon
*
* http://taewon.de
* http://qvacua.com
*
* See LICENSE
*/

#import "VRFileItemManager.h"
#import "VRUtils.h"
#import "VRFileItem.h"
#import "NSArray+VR.h"
#import "NSURL+VR.h"
#import "VRFileItemOperation.h"
#import "VRInvalidateCacheOperation.h"
#import "VRDefaultLogSetting.h"
#import "VRCachedFileItemRecord.h"


static NSString *const qThreadName = @"com.qvacua.VimR.VRFileItemManager";


NSString *const qChunkOfNewFileItemsAddedEvent = @"chunk-of-new-file-items-added-event";


@interface VRFileItemManager ()

// Declared here to be used in the callback and not to make it public.
- (void)invalidateCacheForPaths:(char **)eventPaths eventCount:(NSUInteger)eventCount;

@end


void streamCallback(
    ConstFSEventStreamRef stream,
    void *streamContextInfo,
    size_t eventCount,
    void *paths,
    const FSEventStreamEventFlags flags[],
    const FSEventStreamEventId eventIds[]) {

  __weak VRFileItemManager *urlManager = (__bridge VRFileItemManager *) streamContextInfo;
  [urlManager invalidateCacheForPaths:paths eventCount:eventCount];
}


@implementation VRFileItemManager {
  NSThread *_thread;
  FSEventStreamRef _stream;
  FSEventStreamEventId _lastEventId;

  NSMutableDictionary *_url2CacheRecord;
  NSMutableArray *_mutableUrlsForTargetUrl;

  NSCondition *_fileItemOperationCondition;
  NSOperationQueue *_fileItemOperationQueue;
  NSOperationQueue *_invalidateCacheOperationQueue;

  NSCache *_iconCache;
}

@autowire(workspace)
@autowire(fileManager)
@autowire(notificationCenter);

#pragma mark Properties
- (NSArray *)urlsOfTargetUrl {
  return _mutableUrlsForTargetUrl;
}

- (NSArray *)registeredUrls {
  return _url2CacheRecord.allKeys;
}

#pragma mark Public
- (id)itemForUrl:(NSURL *)url {
  return [_url2CacheRecord[url] fileItem];
}

- (NSArray *)childrenOfItem:(VRFileItem *)item {
  if (!item.shouldCacheChildren) {
    return item.children;
  }

  // TODO: if item is caching, we should wait here until done and return

  VRFileItemOperation *operation = [[VRFileItemOperation alloc] initWithMode:VRFileItemOperationShallowCacheMode
                                                                        dict:@{
                                                                            qFileItemOperationParentItemKey : item,
                                                                            qOperationFileManagerKey : _fileManager,
                                                                        }];
  [operation main];

  return item.children;
}

- (BOOL)isItemDir:(VRFileItem *)item {
  return item.dir;
}

- (BOOL)isItemHidden:(VRFileItem *)item {
  return item.hidden;
}

- (NSString *)nameOfItem:(VRFileItem *)item {
  return item.url.lastPathComponent;
}

- (NSURL *)urlForItem:(VRFileItem *)item {
  return item.url;
}

- (NSImage *)iconForUrl:(NSURL *)url {
  if (!url.isFileURL) {
    return nil;
  }

  NSImage *icon = [_iconCache objectForKey:url];
  if (!icon) {
    icon = [_workspace iconForFile:url.path];
    icon.size = CGSizeMake(16, 16);

    [_iconCache setObject:icon forKey:url];
  }

  return icon;
}

- (void)registerUrl:(NSURL *)url {
  // TODO: handle symlinks and aliases

  @synchronized (self) {
    VRCachedFileItemRecord *record = _url2CacheRecord[url];
    if (record) {
      DDLogWarn(@"%@ is already registered, incrementing consumer count", url);
      [record incrementConsumer];
      return;
    }

    if (!url.isDirectory) {
      DDLogWarn(@"%@ is not a dir, noop", url);
      return;
    }

      // NOTE: We may optimize (or not) the caching behavior here: When the URL A to register is a subdir of an already
      // registered URL B, we build the hierarchy up to the requested URL A. However, then, we would have to scan children
      // up to A, which could be costly to do it sync; async building complicates things too much. For time being, we
      // ignore B and use a separate file item hierarchy for B.
      // If we should do that, we would have only one parent when invalidating the cache. For now, we could have multiple
      // parent URLs and therefore file items for one URL reported by FSEventStream.

    DDLogDebug(@"Registering %@ for caching and monitoring", url);
    _url2CacheRecord[url] = [[VRCachedFileItemRecord alloc] initWithFileItem:[[VRFileItem alloc] initWithUrl:url]];

    [self stop];
    [self start];
  }
}

- (void)unregisterUrl:(NSURL *)url {
  @synchronized (self) {
    VRCachedFileItemRecord *record = _url2CacheRecord[url];
    if (!record) {
      DDLogWarn(@"%@ was not registered", url);
      return;
    }

    DDLogDebug(@"decrementing %@", url);
    [record decrementConsumer];
    if (record.countOfConsumer > 0) {
      return;
    }

    DDLogDebug(@"Unregistering %@", url);
    [_url2CacheRecord removeObjectForKey:url];

    [self stop];
    [self start];
  }
}

- (BOOL)setTargetUrl:(NSURL *)url {
  @synchronized (self) {
    // Just to be safe...
    [self resetTargetUrl];
    _fileItemOperationQueue.suspended = NO;
    _fileItemOperationCondition = [[NSCondition alloc] init];

    VRCachedFileItemRecord *record = _url2CacheRecord[url];
    if (!record) {
      DDLogWarn(@"The URL %@ is not yet registered.", url);
      return NO;
    }

    VRFileItem *targetItem = record.fileItem;

    [_mutableUrlsForTargetUrl removeAllObjects];

    // We don't add targetItem to mutableFileItemsForTargetUrl, since it is a dir.
    [_fileItemOperationQueue addOperation:
        [[VRFileItemOperation alloc] initWithMode:VRFileItemOperationTraverseMode
                                             dict:@{
                                                 qFileItemOperationRootUrlKey : url,
                                                 qFileItemOperationParentItemKey : targetItem,
                                                 qFileItemOperationUrlsForTargetUrlKey : _mutableUrlsForTargetUrl,
                                                 qOperationFileItemManagerKey : self,
                                                 qFileItemOperationOperationQueueKey : _fileItemOperationQueue,
                                                 qOperationNotificationCenterKey : _notificationCenter,
                                                 qOperationFileManagerKey : _fileManager,
                                                 qFileItemOperationPauseConditionKey : _fileItemOperationCondition,
                                             }]
    ];

    return YES;
  }
}

- (void)resetTargetUrl {
  @synchronized (_fileItemOperationQueue) {
    [_fileItemOperationQueue setSuspended:YES];
    [_fileItemOperationQueue cancelAllOperations];
  }

  @synchronized (_mutableUrlsForTargetUrl) {
    [_mutableUrlsForTargetUrl removeAllObjects];
  }
}

- (void)cleanUp {
  @synchronized (_fileItemOperationQueue) {
    _fileItemOperationQueue.suspended = YES;
    [_fileItemOperationQueue cancelAllOperations];

    [self stop];
  }
}

- (void)pauseFileItemOperations {
  @synchronized (_fileItemOperationQueue) {
    _fileItemOperationQueue.suspended = YES;

    [_fileItemOperationCondition lock];
    for (VRFileItemOperation *operation in _fileItemOperationQueue.operations) {
      [operation pause];
    }
    [_fileItemOperationCondition unlock];
  }
}

- (void)resumeFileItemOperations {
  @synchronized (_fileItemOperationQueue) {
    _fileItemOperationQueue.suspended = NO;

    [_fileItemOperationCondition lock];
    for (VRFileItemOperation *operation in _fileItemOperationQueue.operations) {
      [operation resume];
    }
    [_fileItemOperationCondition broadcast];
    [_fileItemOperationCondition unlock];
  }
}

- (BOOL)fileItemOperationPending {
  @synchronized (_fileItemOperationQueue) {
    return _fileItemOperationQueue.operationCount > 0;
  }
}

- (void)waitTillFileItemOperationsFinished {
  [_fileItemOperationQueue waitUntilAllOperationsAreFinished];
}

#pragma mark NSObject
- (id)init {
  self = [super init];
  RETURN_NIL_WHEN_NOT_SELF

  _lastEventId = kFSEventStreamEventIdSinceNow;

  _url2CacheRecord = [[NSMutableDictionary alloc] initWithCapacity:5];
  _mutableUrlsForTargetUrl = [[NSMutableArray alloc] initWithCapacity:10000];

  _fileItemOperationCondition = [[NSCondition alloc] init];
  _fileItemOperationQueue = [[NSOperationQueue alloc] init];
  _fileItemOperationQueue.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount;

  _invalidateCacheOperationQueue = [[NSOperationQueue alloc] init];
  _invalidateCacheOperationQueue.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount;

  _iconCache = [[NSCache alloc] init];
  _iconCache.countLimit = 1000;
  _iconCache.name = @"icon-cache";

  return self;
}

#pragma mark Private
/**
* Performed on a separate thread
*/
- (void)invalidateCacheForPaths:(char **)paths eventCount:(NSUInteger)eventCount {
  @autoreleasepool {
    [self waitTillFileItemOperationsFinished];
    DDLogDebug(@"done waiting till file item operations are finished.");

    for (NSUInteger i = 0; i < eventCount; i++) {

      // There is +fileURLWithFileSystemRepresentation:isDirectory:relativeToURL: of NSURL, but I'm not quite sure,
      // what to think of isDirectory argument. Thus, use NSFileManager first to convert the paths to NSString.
      NSString *path = [self.fileManager stringWithFileSystemRepresentation:paths[i] length:strlen(paths[i])];
      NSURL *url = [NSURL fileURLWithPath:path];

      /**
      * NOTE: We could optimize here: Evaluate the flag for each URL and issue either a shallow or deep scan.
      * This however may be (or is) an overkill. For time being we issue only deep scan.
      * We need a separate queue since we're cancelling all operations of _fileItemOperationQueue when the user
      * closes the open quickly window, but the cache invalidation operation must be processed.
      */
      [_invalidateCacheOperationQueue addOperation:
          [[VRInvalidateCacheOperation alloc] initWithUrl:url dict:@{
              qOperationNotificationCenterKey : _notificationCenter,
              qInvalidateCacheOperationParentItemsKey : [self parentItemsForUrl:url],
          }]
      ];
    }
  };
}

// TODO: extract this in an util class and test it!
- (NSArray *)parentItemsForUrl:(NSURL *)url {
  NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:5];
  for (NSURL *possibleParentUrl in self.registeredUrls) {
    if ([possibleParentUrl isParentToUrl:url]) {
      VRCachedFileItemRecord *record = _url2CacheRecord[possibleParentUrl];
      [result addObject:record.fileItem];
    }
  }

  return result;
}

- (FSEventStreamContext)contextWithSelfAsInfo {
  FSEventStreamContext context;

  memset(&context, 0, sizeof(context));
  context.info = (__bridge void *) (self);

  return context;
}

/**
* Performed on a separate thread
*/
- (void)scheduleStream:(id)sender {
  @autoreleasepool {
    _stream = [self newStream];
  }

  FSEventStreamScheduleWithRunLoop(_stream, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
  FSEventStreamStart(_stream);

  CFRunLoopRun();
}

/**
* Performed on a separate thread, however, only called within an @autoreleasepool
*/
- (FSEventStreamRef)newStream {
  NSMutableArray *paths = [[NSMutableArray alloc] initWithCapacity:self.registeredUrls.count];
  for (NSURL *url in self.registeredUrls) {
    [paths addObject:url.path];
  }

  FSEventStreamContext context = [self contextWithSelfAsInfo];

  return FSEventStreamCreate(
      kCFAllocatorDefault,
      &streamCallback,
      &context,
      (__bridge CFArrayRef) paths,
      _lastEventId,
      0.5,
      kFSEventStreamCreateFlagNone
  );
}

- (void)start {
  @synchronized (self) {
    if (_thread) {
      return;
    }

    if (self.registeredUrls.isEmpty) {
      return;
    }

    DDLogDebug(@"Starting the thread %@", qThreadName);
    _thread = [[NSThread alloc] initWithTarget:self selector:@selector(scheduleStream:) object:self];
    _thread.name = qThreadName;

    [_thread start];

    // We probe the thread whether it is ready for events. When -registerUrl is called consecutively, the FSEventStream
    // could be not ready yet, thus, we wait till everything's started and then return.
    [self performSelector:@selector(probe:) onThread:_thread withObject:self waitUntilDone:YES];
  }
}

/**
* This method is used to probe whether the thread is ready for events.
*/
- (void)probe:(id)sender {
  return;
}

- (void)stop {
  @synchronized (self) {
    if (!_thread) {
      return;
    }

    _lastEventId = FSEventStreamGetLatestEventId(_stream);

    FSEventStreamStop(_stream);
    FSEventStreamInvalidate(_stream);
    FSEventStreamRelease(_stream);

    DDLogDebug(@"Stopping the thread %@", qThreadName);
    [_thread cancel];

    _stream = NULL;
    _thread = nil;
  }
}

- (void)postNewFileItemsAddedNotification:(id)sender {
  DDLogDebug(@"Posting new file items added notification");
  [_notificationCenter postNotificationName:qChunkOfNewFileItemsAddedEvent object:nil];
}
@end
