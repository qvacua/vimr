/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import <CocoaLumberjack/DDFileLogger.h>
#import "VRFileItemManager.h"
#import "VRUtils.h"
#import "VRFileItem.h"
#import "NSArray+VR.h"
#import "NSMutableArray+VR.h"
#import "NSURL+VR.h"
#import "VRFileItemOperation.h"


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


static NSString *const qThreadName = @"com.qvacua.VimR.VRFileItemManager";


NSString *const qChunkOfNewFileItemsAddedEvent = @"chunk-of-new-file-items-added-event";


@interface VRFileItemManager ()

@property (readonly) NSMutableDictionary *url2CachedFileItem;
@property (readonly) NSMutableArray *mutableFileItemsForTargetUrl;
@property (readonly) NSOperationQueue *operationQueue;

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
}

@autowire(fileManager)
@autowire(notificationCenter);

#pragma mark Properties
- (NSArray *)fileItemsOfTargetUrl {
  return self.mutableFileItemsForTargetUrl;
}

- (NSArray *)registeredUrls {
  return self.url2CachedFileItem.allKeys;
}

#pragma mark Public
- (void)registerUrl:(NSURL *)url {
  // TODO: handle symlinks and aliases

  @synchronized (self) {
    if ([_url2CachedFileItem.allKeys containsObject:url]) {
      DDLogWarn(@"%@ is already registered, noop", url);
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
    _url2CachedFileItem[url] = [[VRFileItem alloc] initWithUrl:url isDir:YES];

    [self stop];
    [self start];
  }
}

- (void)unregisterUrl:(NSURL *)url {
  @synchronized (self) {
    DDLogDebug(@"Unregistering %@", url);
    [_url2CachedFileItem removeObjectForKey:url];

    [self stop];
    [self start];
  }
}

- (BOOL)setTargetUrl:(NSURL *)url {
  @synchronized (self) {
    // Just to be safe...
    [self resetTargetUrl];
    _operationQueue.suspended = NO;

    VRFileItem *targetItem = _url2CachedFileItem[url];
    if (!targetItem) {
      DDLogWarn(@"The URL %@ is not yet registered.", url);
      return NO;
    }

    [_mutableFileItemsForTargetUrl removeAllObjects];

    // We don't add targetItem to mutableFileItemsForTargetUrl, since it is a dir.
    [self.operationQueue addOperation:
        [[VRFileItemOperation alloc] initWithMode:VRFileItemOperationTraverseMode
                                             dict:@{
                                                 qFileItemOperationRootUrlKey : url,
                                                 qFileItemOperationParentItemKey : targetItem,
                                                 qFileItemOperationOperationQueueKey : _operationQueue,
                                                 qFileItemOperationFileItemManagerKey : self,
                                                 qFileItemOperationNotificationCenterKey : _notificationCenter,
                                                 qFileItemOperationFileItemsKey : _mutableFileItemsForTargetUrl,
                                                 qFileItemOperationFileManagerKey : _fileManager,
                                             }]
    ];

    return YES;
  }
}

- (void)resetTargetUrl {
  @synchronized (_operationQueue) {
    [_operationQueue setSuspended:YES];
    [_operationQueue cancelAllOperations];
  }

  @synchronized (_mutableFileItemsForTargetUrl) {
    [_mutableFileItemsForTargetUrl removeAllObjects];
  }
}

- (void)cleanUp {
  @synchronized (_operationQueue) {
    _operationQueue.suspended = YES;
    [_operationQueue cancelAllOperations];

    [self stop];
  }
}

- (void)pause {
  @synchronized (_operationQueue) {
    _operationQueue.suspended = YES;

    for (VRFileItemOperation *operation in _operationQueue.operations) {
      [operation pause];
    }
  }
}

- (void)resume {
  @synchronized (_operationQueue) {
    _operationQueue.suspended = NO;

    for (VRFileItemOperation *operation in _operationQueue.operations) {
      [operation resume];
    }
  }
}

- (BOOL)isBusy {
  @synchronized (_operationQueue) {
    return _operationQueue.operationCount > 0;
  }
}

- (NSUInteger)operationCount {
  @synchronized (_operationQueue) {
    return _operationQueue.operationCount;
  }
}


#pragma mark NSObject
- (id)init {
  self = [super init];
  RETURN_NIL_WHEN_NOT_SELF

  _lastEventId = kFSEventStreamEventIdSinceNow;

  _url2CachedFileItem = [[NSMutableDictionary alloc] initWithCapacity:5];
  _mutableFileItemsForTargetUrl = [[NSMutableArray alloc] initWithCapacity:500];

  _operationQueue = [[NSOperationQueue alloc] init];
  _operationQueue.maxConcurrentOperationCount = 1;

#ifdef DEBUG
  setup_file_logger();
#endif

  return self;
}

#pragma mark Private
/**
* Performed on a separate thread
*/
- (void)invalidateCacheForPaths:(char **)paths eventCount:(NSUInteger)eventCount {
  @autoreleasepool {
    for (NSUInteger i = 0; i < eventCount; i++) {

      // There is +fileURLWithFileSystemRepresentation:isDirectory:relativeToURL: of NSURL, but I'm not quite sure,
      // what to think of isDirectory argument. Thus, use NSFileManager first to convert the paths to NSString.
      NSString *path = [self.fileManager stringWithFileSystemRepresentation:paths[i] length:strlen(paths[i])];
      NSURL *url = [NSURL fileURLWithPath:path];

      // NOTE: We could optimize here: Evaluate the flag for each URL and issue either a shallow or deep scan.
      // This however may be (or is) an overkill. For time being we issue only deep scan.
      [self invalidateCacheForUrl:url];
    }
  };
}

/**
* Performed on a separate thread, however, only called within an @autoreleasepool
*/
- (void)invalidateCacheForUrl:(NSURL *)url {
  @synchronized (self) {
    NSArray *parentUrls = [self parentUrlsForUrl:url];

    for (NSURL *parentUrl in parentUrls) {
      VRFileItem *parentItem = _url2CachedFileItem[parentUrl];

      VRFileItem *matchingItem = [self findFileItemForUrl:url inParent:parentItem];
      if (matchingItem) {
          DDLogDebug(@"Invalidating cache for %@ of the parent %@", matchingItem, parentUrl);

          matchingItem.shouldCacheChildren = YES;
      }

      if (!matchingItem) {
        DDLogDebug(@"%@ in %@ not yet cached, noop", url, parentUrl);
      }
    }
  }
}

- (VRFileItem *)findFileItemForUrl:(NSURL *)url inParent:(VRFileItem *)parent {
  if ([parent.url isEqual:url]) {
    return parent;
  }

  for (VRFileItem *child in parent.children) {
    if ([child.url isEqual:url]) {
      return child;
    }

    if (child.isDir && [child.url isParentToUrl:url]) {
      return [self findFileItemForUrl:url inParent:child];
    }
  }

  return nil;
}

/**
* Performed on a separate thread, however, only called within an @autoreleasepool
*
* Pre-order traversal of file items.
* When stop of the block is set to YES, then that item is returned and the traversal stops.
*/
- (VRFileItem *)traverseFileItem:(VRFileItem *)parent usingBlock:(void (^)(VRFileItem *item, BOOL *stop))block {
  BOOL stop = NO;

  VRStack *nodeStack = [[NSMutableArray alloc] initWithCapacity:50];
  [nodeStack push:parent];

  __weak VRFileItem *currentItem;
  while (nodeStack.count > 0) {
    currentItem = [nodeStack pop];
    if (currentItem.dir) {
      [nodeStack pushArray:currentItem.children];
    }

    block(currentItem, &stop);

    if (stop) {
      return currentItem;
    }
  }

  return nil;
}

// TODO: extract this in an util class and test it!
- (NSArray *)parentUrlsForUrl:(NSURL *)url {
  NSString *childPath = url.path;

  NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:5];
  for (NSURL *possibleParent in self.registeredUrls) {
    NSString *parentPath = possibleParent.path;
    if (parentPath.length > childPath.length) {
      continue;
    }

    if ([[childPath substringToIndex:parentPath.length] isEqualToString:parentPath]) {
      [result addObject:possibleParent];
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
* This method is used probe whether the thread is ready for events.
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

@end
