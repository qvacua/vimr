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
        for (i = 0; i < numEvents; i++) {
            NSString *path = [urlManager.fileManager stringWithFileSystemRepresentation:paths[i]
                                                                                 length:strlen(paths[i])];
            NSURL *url = [NSURL fileURLWithPath:path];
            unsigned int flags = eventFlags[i];
            log4Debug(@"URL %@ changed w/flags 0x%08x", url, flags);
        }
    };
}

@interface VRFileItemManager ()

@property (readonly) NSMutableSet *mutableMonitoredUrls;

@end

@implementation VRFileItemManager {
    NSThread *_thread;
    FSEventStreamRef _stream;
    FSEventStreamEventId _lastEventId;
}

TB_AUTOWIRE(fileManager)

#pragma mark Properties
- (NSSet *)monitoredUrls {
    return self.mutableMonitoredUrls;
}

#pragma mark Public
- (void)monitorUrl:(NSURL *)url {
    @synchronized (self) {
        if ([_mutableMonitoredUrls containsObject:url]) {
            log4Debug(@"%@ already monitored", url);
            return;
        }

        [_mutableMonitoredUrls addObject:url];

        [self restart];
    }
}

#pragma mark NSObject
- (id)init {
    self = [super init];
    RETURN_NIL_WHEN_NOT_SELF

    _lastEventId = kFSEventStreamEventIdSinceNow;

    return self;
}

#pragma mark Private
- (FSEventStreamContext)contextWithSelfAsInfo {
    FSEventStreamContext context;

    memset(&context, 0, sizeof(context));
    context.info = (__bridge void *) (self);

    return context;
}

- (void)scheduleStream:(id)sender {
    _stream = [self newStream];

    FSEventStreamScheduleWithRunLoop(_stream, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    FSEventStreamStart(_stream);

    CFRunLoopRun();
}

- (FSEventStreamRef)newStream {
    NSMutableArray *paths = [[NSMutableArray alloc] initWithCapacity:self.monitoredUrls.count];
    for (NSURL *url in self.monitoredUrls) {
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
            kFSEventStreamCreateFlagWatchRoot
    );
}

- (void)restart {
    @synchronized (self) {
        [self stop];
        [self start];
    }
}

- (void)start {
    @synchronized (self) {
        if (_thread) {
            return;
        }

        _thread = [[NSThread alloc] initWithTarget:self selector:@selector(scheduleStream:) object:self];
        _thread.name = @"file-item-manager-thread";

        [_thread start];
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
