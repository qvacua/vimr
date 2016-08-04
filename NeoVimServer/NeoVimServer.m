/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

#import "NeoVimServer.h"
#import "server_globals.h"
#import "Logging.h"


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

- (NSData *)handleMessageWithId:(SInt32)msgid data:(NSData *)data;

@end

static CFDataRef local_server_callback(CFMessagePortRef local, SInt32 msgid, CFDataRef data, void *info) {
  @autoreleasepool {
    NeoVimServer *neoVimServer = (__bridge NeoVimServer *) info;
    NSData *responseData = [neoVimServer handleMessageWithId:msgid data:(__bridge NSData *) data];

    if (responseData == nil) {
      return NULL;
    }

    log4Debug("server returning data: %@", responseData);
    return CFDataCreateCopy(kCFAllocatorDefault, (__bridge CFDataRef) responseData);
  }
}


@implementation NeoVimServer {
  NSString *_localServerName;
  NSString *_remoteServerName;

  CFMessagePortRef _remoteServerPort;

  NSThread *_localServerThread;
  CFMessagePortRef _localServerPort;
  CFRunLoopRef _localServerRunLoop;
}

- (instancetype)initWithLocalServerName:(NSString *)localServerName remoteServerName:(NSString *)remoteServerName {
  self = [super init];
  if (self == nil) {
    return nil;
  }

  _localServerName = localServerName;
  _remoteServerName = remoteServerName;

  _localServerThread = [[NSThread alloc] initWithTarget:self selector:@selector(runLocalServer) object:nil];
  [_localServerThread start];

  _remoteServerPort = CFMessagePortCreateRemote(kCFAllocatorDefault, (__bridge CFStringRef) _remoteServerName);

  return self;
}

- (void)dealloc {
  if (CFMessagePortIsValid(_remoteServerPort)) {
    CFMessagePortInvalidate(_remoteServerPort);
  }
  CFRelease(_remoteServerPort);

  if (CFMessagePortIsValid(_localServerPort)) {
    CFMessagePortInvalidate(_localServerPort);
  }
  CFRelease(_localServerPort);

  CFRunLoopStop(_localServerRunLoop);
  [_localServerThread cancel];
}

- (void)runLocalServer {
  @autoreleasepool {
    unsigned char shouldFree = false;
    CFMessagePortContext localContext = {
        .version = 0,
        .info = (__bridge void *) self,
        .retain = NULL,
        .release = NULL,
        .copyDescription = NULL
    };

    _localServerPort = CFMessagePortCreateLocal(
        kCFAllocatorDefault,
        (__bridge CFStringRef) _localServerName,
        local_server_callback,
        &localContext,
        &shouldFree
    );

    // FIXME: handle shouldFree == true
  }

  _localServerRunLoop = CFRunLoopGetCurrent();
  CFRunLoopSourceRef runLoopSrc = CFMessagePortCreateRunLoopSource(kCFAllocatorDefault, _localServerPort, 0);
  CFRunLoopAddSource(_localServerRunLoop, runLoopSrc, kCFRunLoopCommonModes);
  CFRelease(runLoopSrc);
  CFRunLoopRun();
}

- (void)sendMessageWithId:(NeoVimServerMsgId)msgid {
  [self sendMessageWithId:msgid data:nil];
}

- (void)sendMessageWithId:(NeoVimServerMsgId)msgid data:(NSData *)data {
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

- (void)notifyReadiness {
  [self sendMessageWithId:NeoVimServerMsgIdServerReady data:nil];
}

- (NSData *)handleMessageWithId:(SInt32)msgid data:(NSData *)data {
  switch (msgid) {

    case NeoVimAgentMsgIdAgentReady:
      server_start_neovim();
      return nil;

    case NeoVimAgentMsgIdCommand: {
      NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
      server_vim_command(string);

      return nil;
    }

    case NeoVimAgentMsgIdInput: {
      NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
      server_vim_input(string);

      return nil;
    }

    case NeoVimAgentMsgIdInputMarked: {
      NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
      server_vim_input_marked_text(string);

      return nil;
    }

    case NeoVimAgentMsgIdDelete: {
      NSInteger *values = data_to_NSInteger_array(data, 1);
      server_delete(values[0]);
      return nil;
    }

    case NeoVimAgentMsgIdResize: {
      int *values = data_to_int_array(data, 2);
      server_resize(values[0], values[1]);
      return nil;
    }

    case NeoVimAgentMsgIdRedraw:
      server_redraw();
      return nil;

    case NeoVimAgentMsgIdDirtyDocs: {
      bool dirty = server_has_dirty_docs();
      return [NSData dataWithBytes:&dirty length:sizeof(bool)];
    }

    default:
      return nil;
  }
}

@end
