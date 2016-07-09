/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

#import "NeoVimServer.h"
#import "NeoVimServerMsgIds.h"
#import "server_globals.h"


static const double qTimeout = 10.0;

static CFDataRef local_server_callback(CFMessagePortRef local, SInt32 msgid, CFDataRef data, void *info) {
  @autoreleasepool {
    NeoVimServer *neoVimServer = (NeoVimServer *) info;
    NSData *responseData = [neoVimServer handleMessageWithId:msgid data:(NSData *) data];
    if (responseData == NULL) {
      return NULL;
    }

    return CFDataCreate(kCFAllocatorDefault, responseData.bytes, responseData.length);
  }
}


@implementation NeoVimServer {
  NSString *_uuid;
  NSString *_localServerName;
  NSString *_remoteServerName;

  NSThread *_localServerThread;
  CFMessagePortRef _localServerPort;

  CFMessagePortRef _remoteServerPort;
}

- (instancetype)initWithUuid:(NSString *)uuid
             localServerName:(NSString *)localServerName
            remoteServerName:(NSString *)remoteServerName
{
  self = [super init];
  if (self == nil) {
    return nil;
  }

  _uuid = [uuid retain];
  _localServerName = [localServerName retain];
  _remoteServerName = [remoteServerName retain];

  _localServerThread = [[NSThread alloc] initWithTarget:self selector:@selector(runLocalServer) object:nil];
  [_localServerThread start];

  _remoteServerPort = CFMessagePortCreateRemote(kCFAllocatorDefault, (CFStringRef) _remoteServerName);

  return self;
}

- (void)dealloc {
  [_uuid release];
  [_localServerName release];
  [_remoteServerName release];

  CFMessagePortInvalidate(_localServerPort);
  CFRelease(_localServerPort);

  [_localServerThread cancel];
  [_localServerThread release];

  CFMessagePortInvalidate(_remoteServerPort);
  CFRelease(_remoteServerPort);

  [super dealloc];
}

- (NSData *)handleMessageWithId:(SInt32)msgid data:(NSData *)data {
  NSLog(@"msg received: %d -> %@", msgid, data);

  switch (msgid) {

    case NeoVimAgendMsgIdAgentReady:
      start_neovim();
      return nil;

    case NeoVimAgentMsgIdInput:
      return nil;

    case NeoVimAgentMsgIdInputMarked:
      return nil;

    case NeoVimAgentMsgIdDelete:
      return nil;

    case NeoVimAgentMsgIdResize:
      return nil;

    case NeoVimAgentMsgIdRedraw:
      return nil;

    default:
      return nil;
  }
}

- (void)runLocalServer {
  @autoreleasepool {
    unsigned char shouldFree = false;
    CFMessagePortContext localContext = {
        .version = 0,
        .info = (void *) self,
        .retain = NULL,
        .release = NULL,
        .copyDescription = NULL
    };

    _localServerPort = CFMessagePortCreateLocal(
        kCFAllocatorDefault,
        (CFStringRef) _localServerName,
        local_server_callback,
        &localContext,
        &shouldFree
    );

    // FIXME: handle shouldFree == true

    CFRunLoopRef runLoop = CFRunLoopGetCurrent();
    CFRunLoopSourceRef runLoopSrc = CFMessagePortCreateRunLoopSource(kCFAllocatorDefault, _localServerPort, 0);
    CFRunLoopAddSource(runLoop, runLoopSrc, kCFRunLoopCommonModes);
    CFRelease(runLoopSrc);
    CFRunLoopRun();
  }
}

- (void)sendMessageWithId:(NeoVimServerMsgId)msgid {
  [self sendMessageWithId:msgid data:nil];
}

- (void)sendMessageWithId:(NeoVimServerMsgId)msgid data:(NSData *)data {
  SInt32 responseCode = CFMessagePortSendRequest(
      _remoteServerPort, msgid, (CFDataRef) data, qTimeout, qTimeout, NULL, NULL
  );

  if (responseCode == kCFMessagePortSuccess) {
    return;
  }

  NSLog(@"WARNING: (%d:%@) could not be sent!", (int) msgid, data);
}

- (void)notifyReadiness {
  [self sendMessageWithId:NeoVimServerMsgIdServerReady data:nil];
}

@end
