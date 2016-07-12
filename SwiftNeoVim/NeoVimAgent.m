/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

#import "NeoVimAgent.h"
#import "NeoVimMsgIds.h"
#import "NeoVimUiBridgeProtocol.h"
#import "Logging.h"


static const double qTimeout = 10;

#define data_to_array(type)                                               \
static type *data_to_ ## type ## _array(NSData *data, NSUInteger count) { \
  NSUInteger length = count * sizeof( type );                             \
  if (data.length != length) {                                            \
    return NULL;                                                          \
  }                                                                       \
  return ( type *) data.bytes;                                            \
}

data_to_array(int)
data_to_array(CellAttributes)

@interface NeoVimAgent ()

- (void)handleMessageWithId:(SInt32)msgid data:(NSData *)data;

@end


static CFDataRef local_server_callback(CFMessagePortRef local, SInt32 msgid, CFDataRef data, void *info) {
  @autoreleasepool {
    NeoVimAgent *agent = (__bridge NeoVimAgent *) info;
    [agent handleMessageWithId:msgid data:(__bridge NSData *) (data)];
  }

  return NULL;
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

  return self;
}

// -dealloc would have been ideal for this, but if you quit the app, -dealloc does not necessarily get called...
- (void)cleanUp {
  CFMessagePortInvalidate(_remoteServerPort);
  CFRelease(_remoteServerPort);

  CFMessagePortInvalidate(_localServerPort);
  CFRelease(_localServerPort);

  [_localServerThread cancel];
  [_neoVimServerTask interrupt];
  [_neoVimServerTask terminate];
}

- (void)establishLocalServer {
  _localServerThread = [[NSThread alloc] initWithTarget:self selector:@selector(runLocalServer) object:nil];
  [_localServerThread start];

  _neoVimServerTask = [[NSTask alloc] init];
  _neoVimServerTask.currentDirectoryPath = NSHomeDirectory();
  _neoVimServerTask.launchPath = [self neoVimServerExecutablePath];
  _neoVimServerTask.arguments = @[ [self localServerName], [self remoteServerName] ];
  [_neoVimServerTask launch];
}

- (void)vimInput:(NSString *)string {
  NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
  [self sendMessageWithId:NeoVimAgentMsgIdInput data:data];
}

- (void)vimInputMarkedText:(NSString *_Nonnull)markedText {
  NSData *data = [markedText dataUsingEncoding:NSUTF8StringEncoding];
  [self sendMessageWithId:NeoVimAgentMsgIdInputMarked data:data];
}

- (void)deleteCharacters:(NSInteger)count {
  NSData *data = [[NSData alloc] initWithBytes:&count length:sizeof(NSInteger)];
  [self sendMessageWithId:NeoVimAgentMsgIdDelete data:data];
}

- (void)forceRedraw {
  [self sendMessageWithId:NeoVimAgentMsgIdRedraw data:nil];
}

- (void)resizeToWidth:(int)width height:(int)height {
  int values[] = { width, height };
  NSData *data = [[NSData alloc] initWithBytes:values length:(2 * sizeof(int))];
  [self sendMessageWithId:NeoVimAgentMsgIdResize data:data];
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
  }

  CFRunLoopRef runLoop = CFRunLoopGetCurrent();
  CFRunLoopSourceRef runLoopSrc = CFMessagePortCreateRunLoopSource(kCFAllocatorDefault, _localServerPort, 0);
  CFRunLoopAddSource(runLoop, runLoopSrc, kCFRunLoopCommonModes);
  CFRelease(runLoopSrc);
  CFRunLoopRun();
}

- (void)establishNeoVimConnection {
  _remoteServerPort = CFMessagePortCreateRemote(
      kCFAllocatorDefault,
      (__bridge CFStringRef) [self remoteServerName]
  );

  [self sendMessageWithId:NeoVimAgentMsgIdAgentReady data:nil];
}

- (void)sendMessageWithId:(NeoVimAgentMsgId)msgid data:(NSData *)data {
  if (_remoteServerPort == NULL) {
    log4Warn("Remote server is null: The msg (%lu:%@) could not be sent.", (unsigned long) msgid, data);
    return;
  }

  SInt32 responseCode = CFMessagePortSendRequest(
      _remoteServerPort, msgid, (__bridge CFDataRef) data, qTimeout, qTimeout, NULL, NULL
  );

  if (responseCode == kCFMessagePortSuccess) {
    return;
  }

  log4Warn("The msg (%lu:%@) could not be sent: %d", (unsigned long) msgid, data, responseCode);
}

- (NSString *)neoVimServerExecutablePath {
  return [[[NSBundle bundleForClass:[self class]] builtInPlugInsPath] stringByAppendingPathComponent:@"NeoVimServer"];
}

- (NSString *)localServerName {
  return [NSString stringWithFormat:@"com.qvacua.vimr.%@", _uuid];
}

- (NSString *)remoteServerName {
  return [NSString stringWithFormat:@"com.qvacua.vimr.neovim-server.%@", _uuid];
}

- (void)handleMessageWithId:(SInt32)msgid data:(NSData *)data {
  switch (msgid) {

    case NeoVimServerMsgIdServerReady:
      [self establishNeoVimConnection];
      return;

    case NeoVimServerMsgIdNeoVimReady:
      [_bridge neoVimUiIsReady];
      return;

    case NeoVimServerMsgIdResize: {
      int *values = data_to_int_array(data, 2);
      if (values == nil) {
        return;
      }
      [_bridge resizeToWidth:values[0] height:values[1]];
      return;
    }

    case NeoVimServerMsgIdClear:
      [_bridge clear];
      return;

    case NeoVimServerMsgIdEolClear:
      [_bridge eolClear];
      return;

    case NeoVimServerMsgIdSetPosition: {
      int *values = data_to_int_array(data, 4);
      [_bridge gotoPosition:(Position) { .row = values[0], .column = values[1] }
               screenCursor:(Position) { .row = values[2], .column = values[3] }];
      return;
    }

    case NeoVimServerMsgIdSetMenu:
      [_bridge updateMenu];
      return;

    case NeoVimServerMsgIdBusyStart:
      [_bridge busyStart];
      return;

    case NeoVimServerMsgIdBusyStop:
      [_bridge busyStop];
      return;

    case NeoVimServerMsgIdMouseOn:
      [_bridge mouseOn];
      return;

    case NeoVimServerMsgIdMouseOff:
      [_bridge mouseOff];
      return;

    case NeoVimServerMsgIdModeChange: {
      int *values = data_to_int_array(data, 1);
      [_bridge modeChange:values[0]];
      return;
    }

    case NeoVimServerMsgIdSetScrollRegion: {
      int *values = data_to_int_array(data, 4);
      [_bridge setScrollRegionToTop:values[0] bottom:values[1] left:values[2] right:values[3]];
      return;
    }

    case NeoVimServerMsgIdScroll: {
      int *values = data_to_int_array(data, 1);
      [_bridge scroll:values[0]];
      return;
    }

    case NeoVimServerMsgIdSetHighlightAttributes: {
      CellAttributes *values = data_to_CellAttributes_array(data, 1);
      [_bridge highlightSet:values[0]];
      return;
    }

    case NeoVimServerMsgIdPut: {
      NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
      [_bridge put:string];
      return;
    }

    case NeoVimServerMsgIdPutMarked: {
      NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
      [_bridge putMarkedText:string];
      return;
    }

    case NeoVimServerMsgIdUnmark: {
      int *values = data_to_int_array(data, 2);
      [_bridge unmarkRow:values[0] column:values[1]];
      return;
    }

    case NeoVimServerMsgIdBell:
      [_bridge bell];
      return;

    case NeoVimServerMsgIdVisualBell:
      [_bridge visualBell];
      return;

    case NeoVimServerMsgIdFlush:
      [_bridge flush];
      return;

    case NeoVimServerMsgIdSetForeground: {
      int *values = data_to_int_array(data, 1);
      [_bridge updateForeground:values[0]];
      return;
    }

    case NeoVimServerMsgIdSetBackground: {
      int *values = data_to_int_array(data, 1);
      [_bridge updateBackground:values[0]];
      return;
    }

    case NeoVimServerMsgIdSetSpecial: {
      int *values = data_to_int_array(data, 1);
      [_bridge updateSpecial:values[0]];
      return;
    }

    case NeoVimServerMsgIdSetTitle: {
      NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
      [_bridge setTitle:string];
      return;
    }

    case NeoVimServerMsgIdSetIcon: {
      NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
      [_bridge setIcon:string];
      return;
    }

    case NeoVimServerMsgIdStop:
      [_bridge stop];
      return;

    default:
      return;
  }
}

@end
