//
//  NeoVimUiClient.m
//  nvox
//
//  Created by Tae Won Ha on 08/07/16.
//  Copyright © 2016 Tae Won Ha. All rights reserved.
//

#import "NeoVimUiWrapper.h"
#import "NeoVimXpc.h"

typedef NS_ENUM(NSUInteger, MainAppMsgId) {
    MainAppMsgIdRemoteNeoVimReady = 0
};


static CFDataRef local_server_callback(CFMessagePortRef local, SInt32 msgid, CFDataRef data, void *info) {
  NeoVimUiWrapper *wrapper = (__bridge NeoVimUiWrapper *)info;
  NSData *responseData = [wrapper handleMessageWithId:msgid data:(__bridge NSData *)(data)];
  if (responseData == NULL) {
    return NULL;
  }

  return CFDataCreate(kCFAllocatorDefault, responseData.bytes, responseData.length);
}


//  let executablePath = NSBundle.mainBundle().bundlePath + "/Contents/XPCServices/DummyXpc.xpc/Contents/MacOS/DummyXpc"
@implementation NeoVimUiWrapper {
  NSString *_uuid;

  id <NeoVimXpc> _xpc;

  CFMessagePortRef _remoteServerPort;

  CFMessagePortRef _localServerPort;
  NSThread *_localServerThread;
  CFRunLoopSourceRef _localServerRunLoopSrc;
}

- (instancetype)initWithUuid:(NSString *)uuid xpc:(id <NeoVimXpc>)xpc {
  self = [super init];
  if (self == nil) {
    return nil;
  }

  _xpc = xpc;
  _uuid = uuid;


  return self;
}

- (void)dealloc {
  CFMessagePortInvalidate(_localServerPort);
  CFRelease(_localServerPort);
  CFRelease(_localServerRunLoopSrc);

  [_localServerThread cancel];
}

- (void)runLocalServer {
  _localServerThread = [[NSThread alloc] initWithTarget:self selector:@selector(doRunLocalServer) object:nil];
  [_localServerThread start];
}

- (void)doRunLocalServer {
  NSString *localServerName = [NSString stringWithFormat:@"com.qvacua.nvox.%@", _uuid];
  NSLog(@"main app server name: %@", localServerName);
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
      (__bridge CFStringRef) localServerName,
      local_server_callback,
      &localContext,
      &shouldFreeLocalServer
  );
  // FIXME: handle shouldFreeLocalServer = true

  _localServerRunLoopSrc = CFMessagePortCreateRunLoopSource(kCFAllocatorDefault, _localServerPort, 0);
  CFRunLoopRef cfRunLoop = [NSRunLoop currentRunLoop].getCFRunLoop;
  CFRunLoopAddSource(cfRunLoop, _localServerRunLoopSrc, kCFRunLoopCommonModes);
  [[NSRunLoop currentRunLoop] run];
}

- (NSData *)handleMessageWithId:(SInt32)msgid data:(NSData *)data {
  switch (msgid) {
    case MainAppMsgIdRemoteNeoVimReady: {
      NSLog(@"!!!!!!!!!!!!!!!!!!!!!!!!! %d", msgid);

      _remoteServerPort = CFMessagePortCreateRemote(kCFAllocatorDefault, (__bridge CFStringRef) _uuid);

      NSData *somedata = [@"some data" dataUsingEncoding:NSUTF8StringEncoding];
      SInt32 reponseCode = CFMessagePortSendRequest(
          _remoteServerPort, 13, (__bridge CFDataRef) somedata, 10, 10, NULL, NULL
      );
      if (reponseCode == kCFMessagePortSuccess) {
        NSLog(@"!!!!!!!! SUCCESS!!!!");
      }
      return nil;
    }
    default:
      return nil;
  }
}

@end
