/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import "VRFileItemManager.h"
#import "VRLog.h"
#import "VRUtils.h"
#import "VRFileItem.h"
#import "NSArray+VR.h"
#import "NSMutableArray+VR.h"


typedef void (^VRHandlerForCachedChildrenBlock)(NSArray *);

static NSString *const qHandlerForCachedChildrenKey = @"handler-for-cached-children-key";
static NSString *const qParentFileItemToCacheKey = @"parent-file-item-to-cache-key";
static NSString *const qThreadName = @"com.qvacua.VimR.VRFileItemManager";


@interface VRFileItemManager ()

@property (readonly) NSMutableDictionary *url2CachedFileItem;
@property (readonly) NSMutableArray *mutableFileItemsForTargetUrl;
@property BOOL shouldCancelScanning;

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

#pragma mark Properties
- (NSArray *)fileItemsOfTargetUrl {
  return self.mutableFileItemsForTargetUrl;
}

- (NSArray *)registeredUrls {
  return self.url2CachedFileItem.allKeys;
}

#pragma mark Public
- (void)registerUrl:(NSURL *)url {
  @synchronized (self) {
    if ([_url2CachedFileItem.allKeys containsObject:url]) {
      log4Warn(@"%@ is already registered.", url);
      return;
    }

    if (![self isDir:url]) {
      log4Warn(@"%@ is not a dir.", url);
      return;
    }

    _url2CachedFileItem[url] = [[VRFileItem alloc] initWithUrl:url isDir:YES];

    [self stop];
    [self start];
  }
}

- (void)unregisterUrl:(NSURL *)url {
  @synchronized (self) {
    [_url2CachedFileItem removeObjectForKey:url];

    [self stop];
    [self start];
  }
}

- (BOOL)setTargetUrl:(NSURL *)url {
  self.shouldCancelScanning = NO;

  VRFileItem *targetItem = self.url2CachedFileItem[url];
  if (!targetItem) {
    log4Warn(@"The URL %@ is not yet registered.", url);
    return NO;
  }

  [self.mutableFileItemsForTargetUrl removeAllObjects];

  // We don't add targetItem to mutableFileItemsForTargetUrl, since it is a dir.
  [self traverseFileItemChildHierarchyForRequest:targetItem];

  return YES;
}

- (void)resetTargetUrl {
  self.shouldCancelScanning = YES;
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
  _shouldCancelScanning = NO;

  return self;
}

#pragma mark Private
- (void)traverseFileItemChildHierarchyForRequest:(VRFileItem *)parent {
  if (parent.isCachingChildren) {
    log4Debug(@"File item %@ is currently being cached, noop.", parent.url);
    return;
  }

  if (parent.shouldCacheChildren) {
    // We remove all children when shouldCacheChildren is on, because we do not deep-scan in background, but only set
    // shouldCacheChildren to YES, ie invalidate the cache.
    [parent.children removeAllObjects];

    VRHandlerForCachedChildrenBlock handlerForCachedChildren = ^(NSArray *children) {
      for (VRFileItem *child in children) {
        if (!child.dir) {
          [self addToFileItemsForTargetUrl:child];
        }
      }
    };

    [self performSelector:@selector(cacheChildrenForFileItemAndCallback:) onThread:_thread withObject:@{
        qParentFileItemToCacheKey : parent,
        qHandlerForCachedChildrenKey : handlerForCachedChildren,
    }       waitUntilDone:NO];

    return;
  }

  log4Debug(@"Children of %@ already cached, traversing or adding.", parent.url);
  for (VRFileItem *child in parent.children) {
    if (child.dir) {
      log4Debug(@"Traversing children of %@", child.url);
      [self traverseFileItemChildHierarchyForRequest:child];
    } else {
      [self addToFileItemsForTargetUrl:child];
    }
  }
}

- (void)addToFileItemsForTargetUrl:(VRFileItem *)item {
  [self.mutableFileItemsForTargetUrl addObject:item.url.path];
}

/**
* performed on a separate thread
*/
- (void)cacheChildrenForFileItemAndCallback:(NSDictionary *)dict {
  @autoreleasepool {
    VRFileItem *parent = dict[qParentFileItemToCacheKey];
    VRHandlerForCachedChildrenBlock handlerForCachedChildren = dict[qHandlerForCachedChildrenKey];

    if (self.shouldCancelScanning) {
      log4Debug(@"Cancelling the scanning as requested at %@", parent.url);
      return;
    }

    log4Debug(@"Building children for %@", parent.url);

    parent.isCachingChildren = YES;

    NSArray *childUrls = [self.fileManager contentsOfDirectoryAtURL:parent.url
                                         includingPropertiesForKeys:@[NSURLIsDirectoryKey]
                                                            options:NSDirectoryEnumerationSkipsPackageDescendants
                                                              error:NULL];

    for (NSURL *childUrl in childUrls) {
      [parent.children addObject:[self fileItemFromUrl:childUrl]];
    }

    parent.shouldCacheChildren = NO; // because shouldCacheChildren means, "should add direct descendants"
    parent.isCachingChildren = NO; // direct descendants scanning is done

    handlerForCachedChildren(parent.children);

    for (VRFileItem *child in parent.children) {
      if (self.shouldCancelScanning) {
        log4Debug(@"Cancelling the scanning as requested at %@", parent.url);
        return;
      }

      if (child.dir) {
        [self performSelector:@selector(cacheChildrenForFileItemAndCallback:) onThread:_thread withObject:@{
            qParentFileItemToCacheKey : child,
            qHandlerForCachedChildrenKey : handlerForCachedChildren,
        }       waitUntilDone:NO];
      }
    }
  }
}

- (VRFileItem *)fileItemFromUrl:(NSURL *)url {
  BOOL dir = [self isDir:url];

  return [[VRFileItem alloc] initWithUrl:url isDir:dir];
}

- (BOOL)isDir:(NSURL *)url {
  NSNumber *isDir = nil;
  [url getResourceValue:&isDir forKey:NSURLIsDirectoryKey error:NULL];

  return isDir.boolValue;
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
        log4Debug(@"invalidating cache for %@ of the parent %@", item, parentUrl);
        item.shouldCacheChildren = YES;
        *stop = YES;
      }
    }];

    if (!matchingItem) {
      log4Debug(@"%@ in %@ not yet cached, noop", url, parentUrl);
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

    log4Debug(@"Starting the thread %@", qThreadName);
    _thread = [[NSThread alloc] initWithTarget:self selector:@selector(scheduleStream:) object:self];
    _thread.name = qThreadName;

    [_thread start];
  }
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

    log4Debug(@"Stopping the thread %@", qThreadName);
    [_thread cancel];

    _stream = NULL;
    _thread = nil;
  }
}

@end
