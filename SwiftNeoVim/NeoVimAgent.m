/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

#import "NeoVimAgent.h"
#import "NeoVimMsgIds.h"
#import "Logger.h"
#import "NeoVimBuffer.h"
#import "NeoVimWindow.h"


static const double qTimeout = 10;
static const double qForceExitDelay = 5;

#define data_to_array(type)                                               \
static type *data_to_ ## type ## _array(NSData *data, NSUInteger count) { \
  NSUInteger length = count * sizeof( type );                             \
  if (data.length != length) {                                            \
    return NULL;                                                          \
  }                                                                       \
  return ( type *) data.bytes;                                            \
}


data_to_array(NSInteger)
data_to_array(bool)
data_to_array(CellAttributes)

static void log_cfmachport_error(SInt32 err, NeoVimAgentMsgId msgid, NSData *inputData) {
  switch (err) {
    case kCFMessagePortSendTimeout:
      log4Warn("Got response kCFMessagePortSendTimeout = %d for the msg %ld with data %@.",
          err, (long) msgid, inputData);
    case kCFMessagePortReceiveTimeout:
      log4Warn("Got response kCFMessagePortReceiveTimeout = %d for the msg %ld with data %@.",
          err, (long) msgid, inputData);
    case kCFMessagePortIsInvalid:
      log4Warn("Got response kCFMessagePortIsInvalid = %d for the msg %ld with data %@.",
          err, (long) msgid, inputData);
    case kCFMessagePortTransportError:
      log4Warn("Got response kCFMessagePortTransportError = %d for the msg %ld with data %@.",
          err, (long) msgid, inputData);
    case kCFMessagePortBecameInvalidError:
      log4Warn("Got response kCFMessagePortBecameInvalidError = %d for the msg %ld with data %@.",
          err, (long) msgid, inputData);
      return;

    default:
      return;
  }
}


@interface NeoVimAgent ()

- (void)handleMessageWithId:(SInt32)msgid data:(NSData *)data;

@end


static CFDataRef local_server_callback(CFMessagePortRef local __unused, SInt32 msgid, CFDataRef data, void *info) {
  @autoreleasepool {
    NeoVimAgent *agent = (__bridge NeoVimAgent *) info;
    [agent handleMessageWithId:msgid data:(__bridge NSData *) (data)];
  }

  return NULL;
}


@implementation NeoVimAgent {
  NSString *_uuid;

  CFMessagePortRef _remoteServerPort;

  CFMessagePortRef _localServerPort;
  NSThread *_localServerThread;
  CFRunLoopRef _localServerRunLoop;

  NSTask *_neoVimServerTask;

  bool _neoVimIsReady;
  NSCondition *_neoVimReadyCondition;
  bool _isInitErrorPresent;

  NSInteger _initialWidth;
  NSInteger _initialHeight;

  volatile uint32_t _neoVimIsQuitting;
}

- (instancetype)initWithUuid:(NSString *)uuid {
  self = [super init];
  if (self == nil) {
    return nil;
  }

  _uuid = uuid;
  _useInteractiveZsh = NO;
  _neoVimIsReady = NO;
  _neoVimReadyCondition = [NSCondition new];
  _isInitErrorPresent = NO;

  _initialWidth = 30;
  _initialHeight = 15;

  _neoVimIsQuitting = 0;

  _neoVimHasQuit = false;
  _neoVimQuitCondition = [NSCondition new];

  return self;
}

- (bool)neoVimIsQuitting {
  return _neoVimIsQuitting == 1;
}

- (void)debug {
#ifdef DEBUG
  [self sendMessageWithId:NeoVimAgentDebug1 data:nil expectsReply:NO];
#endif
}

- (void)forceQuit {
  log4Error("Force-quitting NeoVimServer %@", _uuid);

  OSAtomicOr32Barrier(1, &_neoVimIsQuitting);

  [self closeMachPorts];
  [self forceExitNeoVimServer];

  [_neoVimQuitCondition lock];
  _neoVimHasQuit = true;
  [_neoVimQuitCondition signal];
  [_neoVimQuitCondition unlock];

  log4Error("Force-quit NeoVimServer %@", _uuid);

}

// We cannot use -dealloc for this since -dealloc is not called until the run loop in the thread stops.
- (void)quit {
  OSAtomicOr32Barrier(1, &_neoVimIsQuitting);

  [self closeMachPorts];

  [_neoVimServerTask waitUntilExit];

  [_neoVimQuitCondition lock];
  _neoVimHasQuit = true;
  [_neoVimQuitCondition signal];
  [_neoVimQuitCondition unlock];

  log4Info("NeoVimServer %@ exited successfully", _uuid);
}

- (void)closeMachPorts {
  CFRunLoopStop(_localServerRunLoop);
  [_localServerThread cancel];

  if (CFMessagePortIsValid(_remoteServerPort)) {
    CFMessagePortInvalidate(_remoteServerPort);
  }
  CFRelease(_remoteServerPort);
  _remoteServerPort = NULL;

  if (CFMessagePortIsValid(_localServerPort)) {
    CFMessagePortInvalidate(_localServerPort);
  }
  CFRelease(_localServerPort);
  _localServerPort = NULL;
}

-(void)forceExitNeoVimServer {
  log4Warn("Forcing backend neovim process to terminate after %lf seconds.", qForceExitDelay);
  [_neoVimServerTask interrupt];
  [_neoVimServerTask terminate];
}

- (void)launchNeoVimUsingLoginShell {
  NSString *shellPath = [NSProcessInfo processInfo].environment[@"SHELL"];
  if (shellPath == nil) {
    shellPath = @"/bin/bash";
  }

  NSString *shellName = shellPath.lastPathComponent;
  NSMutableArray *shellArgs = [NSMutableArray new];
  if (![shellName isEqualToString:@"tcsh"]) {
    // tcsh does not like the -l option
    [shellArgs addObject:@"-l"];
  }
  if (_useInteractiveZsh && [shellName isEqualToString:@"zsh"]) {
    [shellArgs addObject:@"-i"];
  }

  NSPipe *inputPipe = [NSPipe pipe];
  _neoVimServerTask = [[NSTask alloc] init];

#ifndef DEBUG
  NSFileHandle *nullFileHandle = [NSFileHandle fileHandleWithNullDevice];
  _neoVimServerTask.standardOutput = nullFileHandle;
  _neoVimServerTask.standardError = nullFileHandle;
#endif

  _neoVimServerTask.standardInput = inputPipe;
  _neoVimServerTask.currentDirectoryPath = self.cwd == nil ? NSHomeDirectory() : self.cwd.path;
  _neoVimServerTask.launchPath = shellPath;
  _neoVimServerTask.arguments = shellArgs;
  [_neoVimServerTask launch];

  NSString *cmd = [NSString stringWithFormat:@"NVIM_LISTEN_ADDRESS=%@ exec \"%@\" '%@' '%@'",
                                             [NSString stringWithFormat:@"/tmp/vimr_%@.sock", _uuid],
                                             [self neoVimServerExecutablePath],
                                             [self localServerName],
                                             [self remoteServerName]];
  if (self.nvimArgs != nil) {
    NSMutableArray *args = [NSMutableArray new];
    for (NSString *arg in self.nvimArgs) {
      [args addObject:[NSString stringWithFormat:@"'%@'", arg]];
    }
    cmd = [cmd stringByAppendingFormat:@" %@", [args componentsJoinedByString:@" "]];
  }

  cmd = [cmd stringByAppendingString:@" --headless"];

  NSFileHandle *writeHandle = inputPipe.fileHandleForWriting;
  [writeHandle writeData:[cmd dataUsingEncoding:NSUTF8StringEncoding]];
  [writeHandle closeFile];
}

- (bool)runLocalServerAndNeoVimWithWidth:(NSInteger)width height:(NSInteger)height {
  _initialWidth = width;
  _initialHeight = height;

  _localServerThread = [[NSThread alloc] initWithTarget:self selector:@selector(runLocalServer) object:nil];
  [_localServerThread start];

  [self launchNeoVimUsingLoginShell];

  // Wait until neovim is ready.
  NSDate *deadline = [[NSDate date] dateByAddingTimeInterval:qTimeout];
  [_neoVimReadyCondition lock];
  while (!_neoVimIsReady && [_neoVimReadyCondition waitUntilDate:deadline]);
  [_neoVimReadyCondition unlock];
  _neoVimReadyCondition = nil;

  return !_isInitErrorPresent;
}

- (NSURL *)pwd {
  NSData *data = [self sendMessageWithId:NeoVimAgentMsgIdGetPwd data:nil expectsReply:YES];
  if (data == nil) {
    return [NSURL fileURLWithPath:NSHomeDirectory()];
  }

  NSString *path = [NSKeyedUnarchiver unarchiveObjectWithData:data];
  if (path == nil) {
    return [NSURL fileURLWithPath:NSHomeDirectory()];
  }

  NSURL *pwd = [NSURL fileURLWithPath:path];
  if (pwd == nil) {
    return [NSURL fileURLWithPath:NSHomeDirectory()];
  }

  return pwd;
}

- (void)vimInput:(NSString *)string {
  NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
  [self sendMessageWithId:NeoVimAgentMsgIdInput data:data expectsReply:NO];
}

- (void)vimInputMarkedText:(NSString *_Nonnull)markedText {
  NSData *data = [markedText dataUsingEncoding:NSUTF8StringEncoding];
  [self sendMessageWithId:NeoVimAgentMsgIdInputMarked data:data expectsReply:NO];
}

- (void)deleteCharacters:(NSInteger)count {
  NSData *data = [[NSData alloc] initWithBytes:&count length:sizeof(NSInteger)];
  [self sendMessageWithId:NeoVimAgentMsgIdDelete data:data expectsReply:NO];
}

- (NSString *)escapedFileName:(NSString *)fileName {
  NSArray<NSString *> *fileNames = [self escapedFileNames:@[fileName]];
  if (fileNames.count == 0) {
    return nil;
  }

  return fileNames[0];
}

- (void)focusGained:(bool)gained {
  bool values[] = {gained};
  NSData *data = [[NSData alloc] initWithBytes:values length:sizeof(bool)];
  [self sendMessageWithId:NeoVimAgentMsgIdFocusGained data:data expectsReply:NO];
}

- (void)scrollHorizontal:(NSInteger)horiz vertical:(NSInteger)vert at:(Position)position {
  NSInteger values[] = {horiz, vert, position.row, position.column};
  NSData *data = [[NSData alloc] initWithBytes:values length:4 * sizeof(NSInteger)];
  [self sendMessageWithId:NeoVimAgentMsgIdScroll data:data expectsReply:NO];
}

- (NSArray <NSString *> *)escapedFileNames:(NSArray <NSString *> *)fileNames {
  NSData *data = [NSKeyedArchiver archivedDataWithRootObject:fileNames];
  NSData *response = [self sendMessageWithId:NeoVimAgentMsgIdGetEscapeFileNames data:data expectsReply:YES];
  if (response == nil) {
    log4Warn("The response for the msg %ld was nil.", (long) NeoVimAgentMsgIdGetEscapeFileNames);
    return @[];
  }

  return [NSKeyedUnarchiver unarchiveObjectWithData:response];
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

  _localServerRunLoop = CFRunLoopGetCurrent();
  CFRunLoopSourceRef runLoopSrc = CFMessagePortCreateRunLoopSource(kCFAllocatorDefault, _localServerPort, 0);
  CFRunLoopAddSource(_localServerRunLoop, runLoopSrc, kCFRunLoopCommonModes);
  CFRelease(runLoopSrc);
  CFRunLoopRun();
}

- (void)establishNeoVimConnection {
  _remoteServerPort = CFMessagePortCreateRemote(
      kCFAllocatorDefault,
      (__bridge CFStringRef) [self remoteServerName]
  );

  NSInteger values[] = { _initialWidth, _initialHeight };
  NSData *data = [NSData dataWithBytes:values length:2 * sizeof(NSInteger)];

  [self sendMessageWithId:NeoVimAgentMsgIdAgentReady data:data expectsReply:NO];
}

- (NSData *)sendMessageWithId:(NeoVimAgentMsgId)msgid data:(NSData *)data expectsReply:(bool)expectsReply {
  if (_neoVimIsQuitting == 1) {
    // This happens often, e.g. when exiting full screen by closing all buffers. We try to resize the window after
    // the message port has been closed. This is a quick-and-dirty fix.
    // TODO: Fix for real...
    log4Warn("Neovim is quitting, but trying to send message: %lu", (unsigned long) msgid);
    return nil;
  }

  if (_remoteServerPort == NULL) {
    log4Warn("Remote server is null: The msg %lu with data %@ could not be sent.", (unsigned long) msgid, data);
    return nil;
  }

  CFDataRef responseData = NULL;
  CFStringRef replyMode = expectsReply ? kCFRunLoopDefaultMode : NULL;

  SInt32 responseCode = CFMessagePortSendRequest(
      _remoteServerPort, msgid, (__bridge CFDataRef) data, qTimeout, qTimeout, replyMode, &responseData
  );

  if (_neoVimIsQuitting == 1) {
    return nil;
  }

  if (responseCode != kCFMessagePortSuccess) {
    log_cfmachport_error(responseCode, msgid, data);

    if (_neoVimIsQuitting == 0) {
      [_bridge ipcBecameInvalid:
          [NSString stringWithFormat:
              @"Reason: sending msg to neovim failed for %lu with %d", (unsigned long) msgid, responseCode
          ]
      ];
    }

    return nil;
  }

  if (responseData == NULL) {
    return nil;
  }

  NSData *result = (__bridge_transfer NSData *) responseData;
  return result;
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

    case NeoVimServerMsgIdNeoVimReady: {
      bool *value = data_to_bool_array(data, 1);
      _isInitErrorPresent = value[0];

      [_neoVimReadyCondition lock];
      _neoVimIsReady = YES;
      [_neoVimReadyCondition signal];
      [_neoVimReadyCondition unlock];

      return;
    }

    case NeoVimServerMsgIdResize: {
      NSInteger *values = data_to_NSInteger_array(data, 2);
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
      NSInteger *values = data_to_NSInteger_array(data, 4);
      [_bridge gotoPosition:(Position) {.row = values[0], .column = values[1]}
               textPosition:(Position) {.row = values[2], .column = values[3]}];
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
      NSInteger *values = data_to_NSInteger_array(data, 1);
      [_bridge modeChange:(CursorModeShape) values[0]];
      return;
    }

    case NeoVimServerMsgIdSetScrollRegion: {
      NSInteger *values = data_to_NSInteger_array(data, 4);
      [_bridge setScrollRegionToTop:values[0] bottom:values[1] left:values[2] right:values[3]];
      return;
    }

    case NeoVimServerMsgIdScroll: {
      NSInteger *values = data_to_NSInteger_array(data, 1);
      [_bridge scroll:values[0]];
      return;
    }

    case NeoVimServerMsgIdSetHighlightAttributes: {
      CellAttributes *values = data_to_CellAttributes_array(data, 1);
      [_bridge highlightSet:values[0]];
      return;
    }

    case NeoVimServerMsgIdPut:
    case NeoVimServerMsgIdPutMarked: {
      NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

      if (msgid == NeoVimServerMsgIdPut) {
        [_bridge put:string];
      } else {
        [_bridge putMarkedText:string];
      }

      return;
    }

    case NeoVimServerMsgIdUnmark: {
      NSInteger *values = data_to_NSInteger_array(data, 2);
      [_bridge unmarkRow:values[0] column:values[1]];
      return;
    }

    case NeoVimServerMsgIdBell:
      [_bridge bell];
      return;

    case NeoVimServerMsgIdVisualBell:
      [_bridge visualBell];
      return;

    case NeoVimServerMsgIdFlush: {
      [_bridge flush];
      return;
    }

    case NeoVimServerMsgIdSetForeground: {
      NSInteger *values = data_to_NSInteger_array(data, 1);
      [_bridge updateForeground:values[0]];
      return;
    }

    case NeoVimServerMsgIdSetBackground: {
      NSInteger *values = data_to_NSInteger_array(data, 1);
      [_bridge updateBackground:values[0]];
      return;
    }

    case NeoVimServerMsgIdSetSpecial: {
      NSInteger *values = data_to_NSInteger_array(data, 1);
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

    case NeoVimServerMsgIdDirtyStatusChanged: {
      bool *values = data_to_bool_array(data, 1);
      [_bridge setDirtyStatus:values[0]];
      return;
    }

    case NeoVimServerMsgIdCwdChanged: {
      if (data == nil) {
        return;
      }

      [_bridge cwdChanged:[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]];
      return;
    }

    case NeoVimServerMsgIdColorSchemeChanged: {
      NSInteger *values = (NSInteger *) data.bytes;
      NSMutableArray *array = [NSMutableArray new];
      for (int i = 0; i < 5; i++) {
        [array addObject:@(values[i])];
      }
      [_bridge colorSchemeChanged:array];
      return;
    }

    case NeoVimServerMsgIdAutoCommandEvent: {
      if (data.length == 2 * sizeof(NSInteger)) {
        NSInteger *values = (NSInteger *) data.bytes;
        NeoVimAutoCommandEvent event = (NeoVimAutoCommandEvent) values[0];
        NSInteger bufferHandle = (values + 1)[0];
        [_bridge autoCommandEvent:event bufferHandle:bufferHandle];
      } else {
        NSInteger *values = data_to_NSInteger_array(data, 1);
        [_bridge autoCommandEvent:(NeoVimAutoCommandEvent) values[0] bufferHandle:-1];
      }
      return;
    }

    default:
      return;
  }
}

@end
