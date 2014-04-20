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


@interface VRFileItemManager ()

@property (readonly) NSMutableSet *mutableRegisteredUrls;

// declared here to be used in the callback (and not to make it public)
- (void)reCacheUrls:(NSArray *)fileSystemRep flags:(FSEventStreamEventFlags const [])flags;

@end


void streamCallback(
        ConstFSEventStreamRef stream,
        void *callBackInfo,
        size_t numEvents,
        void *eventPaths,
        const FSEventStreamEventFlags eventFlags[],
        const FSEventStreamEventId eventIds[]
) {
    int i;
    char **paths = eventPaths;
    __weak VRFileItemManager *urlManager = (__bridge VRFileItemManager *) callBackInfo;

    @autoreleasepool {
        NSMutableArray *urls = [[NSMutableArray alloc] initWithCapacity:numEvents];
        for (i = 0; i < numEvents; i++) {
            NSString *path = [urlManager.fileManager stringWithFileSystemRepresentation:paths[i]
                                                                                 length:strlen(paths[i])];
            NSURL *url = [NSURL fileURLWithPath:path];
            [urls addObject:url];
            log4Debug(@"%@ changed!", url);
        }
        [urlManager reCacheUrls:urls flags:eventFlags];
    };
}


@implementation VRFileItemManager {
    NSThread *_thread;
    FSEventStreamRef _stream;
    FSEventStreamEventId _lastEventId;
}

TB_AUTOWIRE(fileManager)

#pragma mark Properties
- (NSSet *)registeredUrls {
    return self.mutableRegisteredUrls;
}

#pragma mark Public
- (VRFileItem *)fileItemForUrl:(NSURL *)url {
    return nil;
}

- (void)registerUrl:(NSURL *)url {
    @synchronized (self) {
        if ([_mutableRegisteredUrls containsObject:url]) {
            return;
        }

        [_mutableRegisteredUrls addObject:url];

        if (_thread) {
            [self stop];
        }
        [self start];

        // TODO: here we request caching of the newly added url?
    }
}

- (void)cleanUp {
    @synchronized (self) {
        [self stop];
    }
}

#pragma mark NSObject
- (id)init {
    self = [super init];
    RETURN_NIL_WHEN_NOT_SELF

    _lastEventId = kFSEventStreamEventIdSinceNow;
    _mutableRegisteredUrls = [[NSMutableSet alloc] initWithCapacity:5];

    return self;
}

#pragma mark Private
- (void)reCacheUrls:(NSArray *)urls flags:(FSEventStreamEventFlags const [])flags {
    [urls enumerateObjectsUsingBlock:^(NSURL *url, NSUInteger idx, BOOL *stop) {
        log4Debug(@"recaching for %@", url);

        FSEventStreamEventFlags flag = flags[idx];

        if (flag & kFSEventStreamEventFlagMustScanSubDirs) {
            log4Debug(@"%@ must subscan", url);
        }
    }];
}

- (FSEventStreamContext)contextWithSelfAsInfo {
    FSEventStreamContext context;

    memset(&context, 0, sizeof(context));
    context.info = (__bridge void *) (self);

    return context;
}

- (void)scheduleStream:(id)sender {
    // this method gets executed by an NSThread, therefore it's responsible for its own autorelease pool
    @autoreleasepool {
        _stream = [self newStream];
    }

    FSEventStreamScheduleWithRunLoop(_stream, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    FSEventStreamStart(_stream);

    CFRunLoopRun();
}

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

        _thread = [[NSThread alloc] initWithTarget:self selector:@selector(scheduleStream:) object:self];
        _thread.name = @"file-item-manager-thread";

        [_thread start];

        [self performSelector:@selector(justTesting:) onThread:_thread withObject:self waitUntilDone:NO];
    }
}

- (void)justTesting:(id)sender {
    @autoreleasepool {
        NSURL *targetUrl = self.registeredUrls.anyObject;

        NSArray *keys = @[
                NSURLIsDirectoryKey,
//                NSURLIsHiddenKey,
//                NSURLIsPackageKey,
//                NSURLIsRegularFileKey,
//                NSURLIsSymbolicLinkKey,
        ];
        enum NSDirectoryEnumerationOptions options = NSDirectoryEnumerationSkipsPackageDescendants;

        VRFileItem *parent = [[VRFileItem alloc] initWithUrl:targetUrl isDir:YES];

        double fetchUrlsTime = measure_time(^{
            [self buildFileItemForParent:parent includingProperties:keys options:options];
        });

        log4Debug(@"Fetching contents of %@ in %.2f s", targetUrl, fetchUrlsTime);
    }
}

- (void)buildFileItemForParent:(VRFileItem *)parent includingProperties:propertyKeys
                       options:(NSDirectoryEnumerationOptions)options {

    NSArray *children = [self.fileManager contentsOfDirectoryAtURL:parent.url includingPropertiesForKeys:propertyKeys
                                                           options:options error:NULL];
    for (NSURL *childUrl in children) {
        NSNumber *isDir = nil;
        [childUrl getResourceValue:&isDir forKey:NSURLIsDirectoryKey error:NULL];
        BOOL dir = isDir.boolValue;

        VRFileItem *child = [[VRFileItem alloc] initWithUrl:childUrl isDir:dir];
        [parent.children addObject:child];

        if (dir) {
            // NOTE: could dispatch async here?
            [self buildFileItemForParent:child includingProperties:propertyKeys options:options];
        }
    }
}

- (void)stop {
    @synchronized (self) {
        _lastEventId = FSEventStreamGetLatestEventId(_stream);

        FSEventStreamStop(_stream);
        FSEventStreamInvalidate(_stream);
        FSEventStreamRelease(_stream);

        [_thread cancel];

        _stream = NULL;
        _thread = nil;
    }
}

@end
