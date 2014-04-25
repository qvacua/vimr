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


static NSString *const qParentFileItemToCacheKey = @"parent-file-item-to-cache-key";
static NSString *const qRootUrlKey = @"root-url-key";
static NSString *const qThreadName = @"com.qvacua.VimR.VRFileItemManager";

NSString *const qChunkOfNewFileItemsAddedEvent = @"chunk-of-new-file-items-added-event";

#define LOG_FLAG_CACHING (1 << 5)
#define DDLogCaching(frmt, ...) ASYNC_LOG_OBJC_MAYBE(ddLogLevel, LOG_FLAG_CACHING,  0, frmt, ##__VA_ARGS__)

static const int ddLogLevel = LOG_LEVEL_DEBUG;
//static const int ddLogLevel = LOG_LEVEL_DEBUG;// | LOG_FLAG_CACHING;

static DDFileLogger *file_logger_for_cache;


@interface VRFileItemManager ()

@property (readonly) NSMutableDictionary *url2CachedFileItem;
@property (readonly) NSMutableArray *mutableFileItemsForTargetUrl;
@property (copy) NSURL *currentTargetUrl;

@property (readonly) NSMutableSet *mutableCurrentlyCachingUrls;
@property (readonly) NSMutableSet *mutableCurrentlyTraversedUrls;

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

TB_AUTOWIRE(fileManager)
TB_AUTOWIRE(notificationCenter);

#pragma mark Properties
- (NSArray *)fileItemsOfTargetUrl {
  return self.mutableFileItemsForTargetUrl;
}

- (NSArray *)registeredUrls {
  return self.url2CachedFileItem.allKeys;
}

- (NSSet *)currentlyTraversedUrls {
  return self.mutableCurrentlyTraversedUrls;
}

- (NSSet *)currentlyCachingUrls {
  return self.mutableCurrentlyCachingUrls;
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
    _currentTargetUrl = url;

    VRFileItem *targetItem = _url2CachedFileItem[url];
    if (!targetItem) {
      DDLogWarn(@"The URL %@ is not yet registered.", url);
      return NO;
    }

    [_mutableFileItemsForTargetUrl removeAllObjects];

    // We don't add targetItem to mutableFileItemsForTargetUrl, since it is a dir.
    dispatch(^{
      [self traverseFileItemChildHierarchyForRequest:targetItem forRootUrl:url];
    });

    return YES;
  }
}

- (void)resetTargetUrl {
  @synchronized (self) {
    _currentTargetUrl = nil;
  }
}

- (void)cleanUp {
  [self stop];
}

#pragma mark NSObject
- (id)init {
  self = [super init];
  RETURN_NIL_WHEN_NOT_SELF

  _lastEventId = kFSEventStreamEventIdSinceNow;

  _url2CachedFileItem = [[NSMutableDictionary alloc] initWithCapacity:5];
  _mutableFileItemsForTargetUrl = [[NSMutableArray alloc] initWithCapacity:500];
  _currentTargetUrl = nil;

  _mutableCurrentlyCachingUrls = [[NSMutableSet alloc] initWithCapacity:100];
  _mutableCurrentlyTraversedUrls = [[NSMutableSet alloc] initWithCapacity:100];

#ifdef DEBUG
  static dispatch_once_t once_token;
  dispatch_once(&once_token, ^{
    file_logger_for_cache = [[DDFileLogger alloc] init];
    file_logger_for_cache.maximumFileSize = 20 * (1024 * 1024); // 20 MB
    [DDLog addLogger:file_logger_for_cache withLogLevel:LOG_FLAG_CACHING];
  });
#endif

  return self;
}

#pragma mark Private
- (void)traverseFileItemChildHierarchyForRequest:(VRFileItem *)parent forRootUrl:(NSURL *)rootUrl {
  if (parent.isCachingChildren) {
    DDLogCaching(@"File item %@ is currently being cached, noop.", parent.url);
    return;
  }

  if (parent.shouldCacheChildren) {
    // We remove all children when shouldCacheChildren is on, because we do not deep-scan in background, but only set
    // shouldCacheChildren to YES, ie invalidate the cache.
    [parent.children removeAllObjects];

    [self performSelector:@selector(cacheAddToFileItemsForTargetUrl:) onThread:_thread withObject:@{
        qParentFileItemToCacheKey : parent,
        qRootUrlKey : rootUrl,
    }       waitUntilDone:NO];

    return;
  }

  DDLogCaching(@"Children of %@ already cached, traversing or adding.", parent.url);

  NSURL *parentUrl = parent.url;
  [self.mutableCurrentlyTraversedUrls addObject:parentUrl];

  NSMutableArray *fileItemsToAdd = [[NSMutableArray alloc] initWithCapacity:parent.children.count];
  for (VRFileItem *child in parent.children) {
    if ([self shouldCancelForRootUrl:rootUrl]) {
      DDLogCaching(@"Cancelling the traversing as requested at %@", child.url);
      [self.mutableCurrentlyTraversedUrls removeObject:parentUrl];

      return;
    }

    if (child.dir) {
      DDLogCaching(@"Traversing children of %@", child.url);
      [self traverseFileItemChildHierarchyForRequest:child forRootUrl:rootUrl];
    } else {
      [fileItemsToAdd addObject:child];
    }
  }
  [self addAllToFileItemsForTargetUrl:fileItemsToAdd];

  [self.mutableCurrentlyTraversedUrls removeObject:parentUrl];
}

- (BOOL)shouldCancelForRootUrl:(NSURL *)rootUrl {
  return ![self.currentTargetUrl isEqualTo:rootUrl];
}

/**
* performed on a separate thread
*/
- (void)cacheAddToFileItemsForTargetUrl:(NSDictionary *)dict {
  @autoreleasepool {
    VRFileItem *parent = dict[qParentFileItemToCacheKey];
    NSURL *rootUrl = dict[qRootUrlKey];

    if ([self shouldCancelForRootUrl:rootUrl]) {
      DDLogCaching(@"Cancelling the scanning as requested at %@", parent.url);
      return;
    }

    DDLogCaching(@"Building children for %@", parent.url);

    NSURL *parentUrl = parent.url;
    [self.mutableCurrentlyCachingUrls addObject:parentUrl];

    parent.isCachingChildren = YES;

    NSArray *childUrls = [self.fileManager contentsOfDirectoryAtURL:parentUrl
                                         includingPropertiesForKeys:@[NSURLIsDirectoryKey]
                                                            options:NSDirectoryEnumerationSkipsPackageDescendants
                                                              error:NULL];

    NSMutableArray *childrenOfParent = parent.children;

    for (NSURL *childUrl in childUrls) {
      [childrenOfParent addObject:[[VRFileItem alloc] initWithUrl:childUrl isDir:childUrl.isDirectory]];
    }

    parent.shouldCacheChildren = NO; // because shouldCacheChildren means, "should add direct descendants"
    parent.isCachingChildren = NO; // direct descendants scanning is done

    [self.mutableCurrentlyCachingUrls removeObject:parentUrl];

    [self addAllToFileItemsForTargetUrl:childrenOfParent];

    for (VRFileItem *child in childrenOfParent) {
      if ([self shouldCancelForRootUrl:rootUrl]) {
        DDLogCaching(@"Cancelling the scanning as requested at %@", child.url);
        return;
      }

      if (child.dir) {
        [self performSelector:@selector(cacheAddToFileItemsForTargetUrl:) onThread:_thread withObject:@{
            qParentFileItemToCacheKey : child,
            qRootUrlKey : rootUrl,
        }       waitUntilDone:NO];
      }
    }
  }
}

- (void)addAllToFileItemsForTargetUrl:(NSArray *)items {
  for (VRFileItem *child in items) {
    if (!child.dir) {
      [self.mutableFileItemsForTargetUrl addObject:child.url.path];
    }
  }

  dispatch_async(dispatch_get_main_queue(), ^{
    [self.notificationCenter postNotificationName:qChunkOfNewFileItemsAddedEvent object:self];
  });
}

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
  NSArray *parentUrls = [self parentUrlsForUrl:url];

  for (NSURL *parentUrl in parentUrls) {
    VRFileItem *parentItem = self.url2CachedFileItem[parentUrl];

    VRFileItem *matchingItem = [self traverseFileItem:parentItem usingBlock:^(VRFileItem *item, BOOL *stop) {
      if ([item.url isEqualTo:url]) {
        DDLogCaching(@"Invalidating cache for %@ of the parent %@", item, parentUrl);
        item.shouldCacheChildren = YES;
        *stop = YES;
      }
    }];

    if (!matchingItem) {
      DDLogCaching(@"%@ in %@ not yet cached, noop", url, parentUrl);
    }
  }
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

- (NSArray *)parentUrlsForUrl:(NSURL *)url {
  NSString *childPath = url.path;

  NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:5];
  for (NSURL *possibleParent in self.registeredUrls) {
    NSString *parentPath = possibleParent.path;
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
