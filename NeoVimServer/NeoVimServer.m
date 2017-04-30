/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

#import "NeoVimServer.h"
#import "server_globals.h"
#import "Logging.h"
#import "CocoaCategories.h"
#import "DataWrapper.h"

// FileInfo and Boolean are #defined by Carbon and NeoVim: Since we don't need the Carbon versions of them, we rename
// them.
#define FileInfo CarbonFileInfo
#define Boolean CarbonBoolean

#import <nvim/vim.h>
#import <nvim/main.h>


// When #define'd you can execute the NeoVimServer binary and neovim will be started:
// $ ./NeoVimServer local remote
#undef DEBUG_NEOVIM_SERVER_STANDALONE
//#define DEBUG_NEOVIM_SERVER_STANDALONE


static const double qTimeout = 10;


@interface NeoVimServer ()

- (NSCondition *)outputCondition;
- (void)handleQuitMsg;

@end

static CFDataRef data_sync(CFDataRef data, NSCondition *condition, argv_callback cb) {
  DataWrapper *wrapper = [[DataWrapper alloc] init];
  NSDate *deadline = [[NSDate date] dateByAddingTimeInterval:qTimeout];

  [condition lock];

  loop_schedule(&main_loop, event_create(cb, 3, data, condition, wrapper));

  while (wrapper.isDataReady == false && [condition waitUntilDate:deadline]);
  [condition unlock];

  if (wrapper.data == nil) {
    return NULL;
  }

  return CFDataCreateCopy(kCFAllocatorDefault, (__bridge CFDataRef) wrapper.data);
}

static CFDataRef local_server_callback(CFMessagePortRef local, SInt32 msgid, CFDataRef data, void *info) {
  @autoreleasepool {
    NeoVimServer *neoVimServer = (__bridge NeoVimServer *) info;
    NSCondition *outputCondition = neoVimServer.outputCondition;
    CFRetain(data); // release in the loop callbacks!

    switch (msgid) {

      case NeoVimAgentMsgIdAgentReady:
        start_neovim();
        return NULL;

      case NeoVimAgentMsgIdQuit:
        [neoVimServer handleQuitMsg];
        return NULL;

      case NeoVimAgentMsgIdCommandOutput: return data_sync(data, outputCondition, neovim_vim_command_output);

      case NeoVimAgentMsgIdSelectWindow: return data_sync (data, outputCondition, neovim_select_window);

      case NeoVimAgentMsgIdGetTabs: return data_sync(data, outputCondition, neovim_tabs);
      
      case NeoVimAgentMsgIdGetBuffers: return data_sync(data, outputCondition, neovim_buffers);

      case NeoVimAgentMsgIdGetBoolOption: return data_sync(data, outputCondition, neovim_get_bool_option);

      case NeoVimAgentMsgIdSetBoolOption: return data_sync(data, outputCondition, neovim_set_bool_option);

      case NeoVimAgentMsgIdGetEscapeFileNames: return data_sync(data, outputCondition, neovim_escaped_filenames);

      case NeoVimAgentMsgIdGetDirtyDocs: return data_sync(data, outputCondition, neovim_has_dirty_docs);

      case NeoVimAgentMsgIdResize: return data_sync (data, outputCondition, neovim_resize);

      case NeoVimAgentMsgIdCommand: return data_sync (data, outputCondition, neovim_vim_command);

      case NeoVimAgentMsgIdInput: return data_sync (data, outputCondition, neovim_vim_input);

      case NeoVimAgentMsgIdInputMarked: return data_sync (data, outputCondition, neovim_vim_input_marked_text);

      case NeoVimAgentMsgIdDelete: return data_sync (data, outputCondition, neovim_delete);

      case NeoVimAgentMsgIdCursorGoto: return data_sync (data, outputCondition, neovim_cursor_goto);

      default: return NULL;

    }
  }
}


@implementation NeoVimServer {
  NSString *_localServerName;
  NSString *_remoteServerName;

  CFMessagePortRef _remoteServerPort;

  NSThread *_localServerThread;
  CFMessagePortRef _localServerPort;
  CFRunLoopRef _localServerRunLoop;

  NSCondition *_outputCondition;
}

- (NSCondition *)outputCondition {
  return _outputCondition;
}

- (instancetype)initWithLocalServerName:(NSString *)localServerName remoteServerName:(NSString *)remoteServerName {
  self = [super init];
  if (self == nil) {
    return nil;
  }

  _outputCondition = [[NSCondition alloc] init];

  _localServerName = localServerName;
  _remoteServerName = remoteServerName;

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

- (void)sendMessageWithId:(NeoVimServerMsgId)msgid {
  [self sendMessageWithId:msgid data:nil];
}

- (void)sendMessageWithId:(NeoVimServerMsgId)msgid data:(NSData *)data {
#ifdef DEBUG_NEOVIM_SERVER_STANDALONE
  return;
#endif

  if (_remoteServerPort == NULL) {
    WLOG("Remote server is null: The msg (%lu:%s) could not be sent.", (unsigned long) msgid, data.cdesc);
    return;
  }

  SInt32 responseCode = CFMessagePortSendRequest(
      _remoteServerPort, msgid, (__bridge CFDataRef) data, qTimeout, qTimeout, NULL, NULL
  );

  if (responseCode == kCFMessagePortSuccess) {
    return;
  }

  WLOG("The msg (%lu:%s) could not be sent: %d", (unsigned long) msgid, data.cdesc, responseCode);
}

- (void)notifyReadiness {
#ifndef DEBUG_NEOVIM_SERVER_STANDALONE
  [self sendMessageWithId:NeoVimServerMsgIdServerReady data:nil];
#endif
}

- (void)quit {
  quit_neovim();
}

- (void)handleQuitMsg {
  // exit() after returning the response such that the agent can get the response and so does not log a warning.
  [self performSelector:@selector(quit) onThread:_localServerThread withObject:nil waitUntilDone:NO];
}

@end
