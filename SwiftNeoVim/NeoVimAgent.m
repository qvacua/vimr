/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

#import "NeoVimAgent.h"
#import "NeoVimServerMsgIds.h"


static const int qTimeout = 10;

@interface NeoVimAgent ()

- (NSData *)handleMessageWithId:(SInt32)msgid data:(NSData *)data;

@end


static CFDataRef local_server_callback(CFMessagePortRef local, SInt32 msgid, CFDataRef data, void *info) {
  @autoreleasepool {
    NeoVimAgent *agent = (__bridge NeoVimAgent *) info;
    NSData *responseData = [agent handleMessageWithId:msgid data:(__bridge NSData *) (data)];
    if (responseData == NULL) {
      return NULL;
    }

    return CFDataCreate(kCFAllocatorDefault, responseData.bytes, responseData.length);
  }
}


@implementation NeoVimAgent {
  NSString *_uuid;

  CFMessagePortRef _localServerPort;
  NSThread *_localServerThread;

  NSTask *_neoVimServerTask;
  CFMessagePortRef _remoteServerPort;
}

- (instancetype)initWithUuid:(NSString *)uuid {
  self = [super init];
  if (self == nil) {
    return nil;
  }

  _uuid = uuid;
  _localServerThread = [[NSThread alloc] initWithTarget:self selector:@selector(runLocalServer) object:nil];
  [_localServerThread start];

  _neoVimServerTask = [[NSTask alloc] init];
  _neoVimServerTask.launchPath = [self neoVimServerExecutablePath];
  NSLog(@"%@", [self neoVimServerExecutablePath]);

  _neoVimServerTask.arguments = @[ _uuid, [self localServerName], [self remoteServerName] ];
  [_neoVimServerTask launch];


  return self;
}

- (NSString *)neoVimServerExecutablePath {
  return [[[NSBundle bundleForClass:[self class]] builtInPlugInsPath] stringByAppendingPathComponent:@"NeoVimServer"];
}

- (void)dealloc {
  CFMessagePortInvalidate(_localServerPort);
  CFRelease(_localServerPort);

  [_localServerThread cancel];

  [_neoVimServerTask terminate];
  NSLog(@"terminated...");
}

- (void)runLocalServer {
  @autoreleasepool {
    CFMessagePortContext localContext = {
        .version = 0,
        .info = (__bridge void *) self,
        .retain = NULL,
        .release = NULL,
        .copyDescription = NULL
    };

    unsigned char shouldFreeLocalServer = false;
    _localServerPort = CFMessagePortCreateLocal(
        kCFAllocatorDefault,
        (__bridge CFStringRef) [self localServerName],
        local_server_callback,
        &localContext,
        &shouldFreeLocalServer
    );

    // FIXME: handle shouldFreeLocalServer = true

    CFRunLoopRef runLoop = CFRunLoopGetCurrent();
    CFRunLoopSourceRef runLoopSrc = CFMessagePortCreateRunLoopSource(kCFAllocatorDefault, _localServerPort, 0);
    CFRunLoopAddSource(runLoop, runLoopSrc, kCFRunLoopCommonModes);
    CFRelease(runLoopSrc);
    CFRunLoopRun();
  }
}

- (NSData *)handleMessageWithId:(SInt32)msgid data:(NSData *)data {
  NSLog(@"msg received: %d -> %@", msgid, data);

  switch (msgid) {

    case NeoVimServerMsgIdServerReady:
      return [self setupNeoVimServer];

    case NeoVimServerMsgIdNeoVimReady:
      return nil;

    case NeoVimServerMsgIdResize:
      return nil;

    case NeoVimServerMsgIdClear:
      return nil;

    case NeoVimServerMsgIdEolClear:
      return nil;

    case NeoVimServerMsgIdSetPosition:
      return nil;

    case NeoVimServerMsgIdSetMenu:
      return nil;

    case NeoVimServerMsgIdBusyStart:
      return nil;

    case NeoVimServerMsgIdBusyStop:
      return nil;

    case NeoVimServerMsgIdMouseOn:
      return nil;

    case NeoVimServerMsgIdMouseOff:
      return nil;

    case NeoVimServerMsgIdModeChange:
      return nil;

    case NeoVimServerMsgIdSetScrollRegion:
      return nil;

    case NeoVimServerMsgIdScroll:
      return nil;

    case NeoVimServerMsgIdSetHighlightAttributes:
      return nil;

    case NeoVimServerMsgIdPut:
      return nil;

    case NeoVimServerMsgIdPutMarked:
      return nil;

    case NeoVimServerMsgIdUnmark:
      return nil;

    case NeoVimServerMsgIdBell:
      return nil;

    case NeoVimServerMsgIdFlush:
      return nil;

    case NeoVimServerMsgIdSetForeground:
      return nil;

    case NeoVimServerMsgIdSetBackground:
      return nil;

    case NeoVimServerMsgIdSetSpecial:
      return nil;

    case NeoVimServerMsgIdSetTitle:
      return nil;

    case NeoVimServerMsgIdSetIcon:
      return nil;

    case NeoVimServerMsgIdStop:
      return nil;

    default:
      return nil;
  }
}

- (NSData *)setupNeoVimServer {
  _remoteServerPort = CFMessagePortCreateRemote(
      kCFAllocatorDefault,
      (__bridge CFStringRef) [self remoteServerName]
  );

  SInt32 responseCode = CFMessagePortSendRequest(
      _remoteServerPort, NeoVimAgendMsgIdAgentReady, nil, qTimeout, qTimeout, NULL, NULL
  );
  if (responseCode == kCFMessagePortSuccess) {
    NSLog(@"!!!!!!!! SUCCESS!!!!");
  }

  return nil;
}

- (NSString *)localServerName {
  return [NSString stringWithFormat:@"com.qvacua.nvox.%@", _uuid];
}

- (NSString *)remoteServerName {
  return [NSString stringWithFormat:@"com.qvacua.nvox.neovim-server.%@", _uuid];
}

@end
