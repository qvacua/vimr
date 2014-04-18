/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import "VRUrlManager.h"
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
    __weak VRUrlManager *urlManager = (__bridge VRUrlManager *) callBackInfo;

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

@implementation VRUrlManager {
    FSEventStreamRef stream;
    NSThread *thread;
}

TB_AUTOWIRE(fileManager)


#pragma mark Public
- (void)start {
    thread = [[NSThread alloc] initWithTarget:self selector:@selector(scheduleStream:) object:self];

    [thread start];
}

- (void)stop {
    FSEventStreamStop(stream);
    FSEventStreamInvalidate(stream);
    FSEventStreamRelease(stream);

    [thread cancel];
}

#pragma mark NSObject
- (id)init {
    self = [super init];
    RETURN_NIL_WHEN_NOT_SELF

    NSArray *paths = @[
            @"/Users/hat/Downloads",
    ];

    FSEventStreamContext context= [self contextWithSelfAsInfo];
    stream = FSEventStreamCreate(
            kCFAllocatorDefault,
            &streamCallback,
            &context,
            (__bridge CFArrayRef) paths,
            kFSEventStreamEventIdSinceNow,
            0.3,
            kFSEventStreamCreateFlagWatchRoot
    );

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
    FSEventStreamScheduleWithRunLoop(stream, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    FSEventStreamStart(stream);

    CFRunLoopRun();
}

@end
