/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

#import "NeoVimServer.h"
#import "NeoVimMsgIds.h"
#import "server_globals.h"


static const double qTimeout = 10.0;

#define data_to_array(type)                                               \
static type *data_to_ ## type ## _array(NSData *data, NSUInteger count) { \
  NSUInteger length = count * sizeof( type );                             \
  if (data.length != length) {                                            \
    return NULL;                                                          \
  }                                                                       \
  return ( type *) data.bytes;                                            \
}

data_to_array(int)
data_to_array(NSInteger)

@interface NeoVimServer ()

- (void)handleMessageWithId:(SInt32)msgid data:(NSData *)data;

@end

static CFDataRef local_server_callback(CFMessagePortRef local, SInt32 msgid, CFDataRef data, void *info) {
  @autoreleasepool {
    NeoVimServer *neoVimServer = (NeoVimServer *) info;
    [neoVimServer handleMessageWithId:msgid data:(NSData *) data];
    return NULL;
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
  }

  CFRunLoopRef runLoop = CFRunLoopGetCurrent();
  CFRunLoopSourceRef runLoopSrc = CFMessagePortCreateRunLoopSource(kCFAllocatorDefault, _localServerPort, 0);
  CFRunLoopAddSource(runLoop, runLoopSrc, kCFRunLoopCommonModes);
  CFRelease(runLoopSrc);
  CFRunLoopRun();
}

- (void)sendMessageWithId:(NeoVimServerMsgId)msgid {
  [self sendMessageWithId:msgid data:nil];
}

- (void)sendMessageWithId:(NeoVimServerMsgId)msgid data:(NSData *)data {
  if (_remoteServerPort == NULL) {
    NSLog(@"WARNING: remote server is null");
    return;
  }

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

- (void)handleMessageWithId:(SInt32)msgid data:(NSData *)data {
  switch (msgid) {

    case NeoVimAgentMsgIdAgentReady:
      server_start_neovim();
      return;

    case NeoVimAgentMsgIdInput: {
      NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
      server_vim_input(string);
      [string release];

      return;
    }

    case NeoVimAgentMsgIdInputMarked: {
      NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
      server_vim_input_marked_text(string);
      [string release];

      return;
    }

    case NeoVimAgentMsgIdDelete: {
      NSInteger *values = data_to_NSInteger_array(data, 1);
      server_delete(values[0]);
      return;
    }

    case NeoVimAgentMsgIdResize: {
      int *values = data_to_int_array(data, 2);
      server_resize(values[0], values[1]);
      return;
    }

    case NeoVimAgentMsgIdRedraw:
      server_redraw();
      return;

    default:
      return;
  }
}

@end
