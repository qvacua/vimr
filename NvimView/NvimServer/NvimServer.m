/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

#import "NvimServer.h"
#import "server_ui.h"
#import "Logging.h"
#import "CocoaCategories.h"

// FileInfo and Boolean are #defined by Carbon and NeoVim: Since we don't need the Carbon versions of them, we rename
// them.
#define FileInfo CarbonFileInfo
#define Boolean CarbonBoolean

#import <nvim/main.h>


// When #define'd you can execute the NvimServer binary and neovim will be started:
// $ ./NvimServer local remote
#undef DEBUG_NEOVIM_SERVER_STANDALONE
//#define DEBUG_NEOVIM_SERVER_STANDALONE


static const double qTimeout = 5;


@interface NvimServer ()

- (NSArray<NSString *> *)nvimArgs;

@end

static CFDataRef data_async(CFDataRef data, argv_callback cb) {
  loop_schedule(&main_loop, event_create(cb, 3, data));
  return NULL;
}

static CFDataRef local_server_callback(CFMessagePortRef local, SInt32 msgid, CFDataRef data, void *info) {
  CFRetain(data); // release in the loop callbacks! (or in the case clause when not passed to the callback)

  switch (msgid) {

    case NvimBridgeMsgIdAgentReady: {
      @autoreleasepool {
        NSInteger *values = (NSInteger *) CFDataGetBytePtr(data);
        NvimServer *nvimServer = (__bridge NvimServer *) info;

        start_neovim(values[0], values[1], nvimServer.nvimArgs);

        CFRelease(data);
      }
      return NULL;
    }

    case NvimBridgeMsgIdScroll:
      return data_async(data, neovim_scroll);

    case NvimBridgeMsgIdResize:
      return data_async(data, neovim_resize);

    case NvimBridgeMsgIdInput:
      return data_async(data, neovim_vim_input);

    case NvimBridgeMsgIdDeleteInput:
      return data_async(data, neovim_delete_and_input);

    case NvimBridgeMsgIdFocusGained:
      return data_async(data, neovim_focus_gained);

    default:
      CFRelease(data);
      return NULL;

  }
}


@implementation NvimServer {
  NSString *_localServerName;
  NSString *_remoteServerName;
  NSArray<NSString *> *_nvimArgs;

  CFMessagePortRef _remoteServerPort;

  NSThread *_localServerThread;
  CFMessagePortRef _localServerPort;
  CFRunLoopRef _localServerRunLoop;
}

- (NSArray<NSString *> *)nvimArgs {
  return _nvimArgs;
}

- (instancetype)initWithLocalServerName:(NSString *)localServerName
                       remoteServerName:(NSString *)remoteServerName
                               nvimArgs:(NSArray<NSString *> *)nvimArgs {

  self = [super init];
  if (self == nil) {
    return nil;
  }

  _localServerName = localServerName;
  _remoteServerName = remoteServerName;
  _nvimArgs = nvimArgs;

  _localServerThread = [[NSThread alloc] initWithTarget:self selector:@selector(runLocalServer) object:nil];
  _localServerThread.name = localServerName;
  [_localServerThread start];

#ifndef DEBUG_NEOVIM_SERVER_STANDALONE
  _remoteServerPort = CFMessagePortCreateRemote(kCFAllocatorDefault, (__bridge CFStringRef) _remoteServerName);
#endif

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

#ifdef DEBUG_NEOVIM_SERVER_STANDALONE
  server_start_neovim();
#endif

  CFRunLoopRun();
}

- (void)sendMessageWithId:(NvimServerMsgId)msgid {
  [self sendMessageWithId:msgid data:NULL];
}

- (void)sendMessageWithId:(NvimServerMsgId)msgid data:(CFDataRef)data {
#ifdef DEBUG_NEOVIM_SERVER_STANDALONE
  return;
#endif

  if (_remoteServerPort == NULL) {
    WLOG("Remote server is null: The msg (%lu) could not be sent.", (unsigned long) msgid);
    return;
  }

  SInt32 responseCode = CFMessagePortSendRequest(_remoteServerPort, msgid, data, qTimeout, qTimeout, NULL, NULL);

  if (responseCode == kCFMessagePortSuccess) {
    return;
  }

  WLOG("The msg (%lu) could not be sent: %d", (unsigned long) msgid, responseCode);
}

- (void)notifyReadiness {
#ifndef DEBUG_NEOVIM_SERVER_STANDALONE
  [self sendMessageWithId:NvimServerMsgIdServerReady data:NULL];
#endif
}

@end
