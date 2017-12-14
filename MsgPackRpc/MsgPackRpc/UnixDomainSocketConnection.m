/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

#import "UnixDomainSocketConnection.h"
#import <sys/socket.h>
#import <sys/un.h>

@interface UnixDomainSocketConnection ()

- (void)dataCallbackWithData:(NSData *)data;

@end

static void socket_call_back(
    CFSocketRef s,
    CFSocketCallBackType type,
    CFDataRef address,
    const void *raw_data,
    void *info
) {
  @autoreleasepool {
    UnixDomainSocketConnection *socket = (__bridge UnixDomainSocketConnection *) info;

    switch (type) {
      case kCFSocketDataCallBack: {
        if (raw_data == NULL) {
          NSLog(@"callback: data NULL");
          return;
        }

        NSData *data = [[NSData alloc] initWithData:(__bridge NSData *) raw_data];
        [socket dataCallbackWithData:data];
        break;
      }

      default:
        break;
    }
  }
}

@implementation UnixDomainSocketConnection {
  int _native_socket;
  struct sockaddr_un _sockaddr;

  NSString *_path;

  CFRunLoopRef _run_loop;
  CFRunLoopSourceRef _run_loop_source;

  NSThread *_thread;
}

- (bool)isRunning {
  return [_thread isExecuting];
}

- (instancetype)initWithPath:(NSString *)path {
  self = [super init];
  if (self == nil) {
    return nil;
  }

  _timeout = 5;
  _path = path;

  return self;
}

- (void)dealloc {
  if ([_thread isExecuting]) {
    CFRunLoopStop(_run_loop);
  }

  if (_run_loop_source != NULL) {
    CFRelease(_run_loop_source);
  }

  if (_socket != NULL) {
    CFRelease(_socket);
  }

  close(_native_socket);
}

- (NSError *)connectAndRun {
  if ((_native_socket = socket(AF_UNIX, SOCK_STREAM, 0)) == -1) {
    NSLog(@"Error: Unix domain socket NULL!");
    return [NSError errorWithDomain:NSPOSIXErrorDomain code:-1 userInfo:@{
        NSLocalizedDescriptionKey: @"Could not create unix domain socket.",
    }];
  }

  _sockaddr.sun_family = AF_UNIX;
  strcpy(_sockaddr.sun_path, [_path cStringUsingEncoding:NSUTF8StringEncoding]);
  if (connect(_native_socket, (struct sockaddr *) &_sockaddr, (socklen_t) SUN_LEN(&_sockaddr)) == -1) {
    NSLog(@"Error: Could not connect to the socket!");
    close(_native_socket);
    return [NSError errorWithDomain:NSPOSIXErrorDomain code:-1 userInfo:@{
        NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Could not connect to socket %s", _sockaddr.sun_path]
    }];
  }

  CFSocketContext context;
  context.copyDescription = NULL;
  context.release = NULL;
  context.retain = NULL;
  context.version = 0;
  context.info = (__bridge void *) self;

  _socket = CFSocketCreateWithNative(
      NULL,
      _native_socket,
      kCFSocketConnectCallBack | kCFSocketDataCallBack,
      socket_call_back,
      &context
  );

  if (_socket == nil) {
    NSLog(@"Error: CFSocket is NULL!");
    close(_native_socket);
    return [NSError errorWithDomain:NSPOSIXErrorDomain code:-1 userInfo:@{
        NSLocalizedDescriptionKey: [NSString stringWithFormat:@"CFSocket is NULL for %s", _sockaddr.sun_path]
    }];
  }

  _run_loop_source = CFSocketCreateRunLoopSource(NULL, _socket, 0);
  _thread = [[NSThread alloc] initWithTarget:self selector:@selector(threadMain) object:nil];
  [_thread start];

  return nil;
}

- (void)disconnectAndStop {
  if (_socket != NULL && CFSocketIsValid(_socket)) {
    CFRunLoopStop(_run_loop);
    CFSocketInvalidate(_socket);
    [_thread cancel];
  }
}

- (void)threadMain {
  _run_loop = CFRunLoopGetCurrent();
  CFRunLoopAddSource(_run_loop, _run_loop_source, kCFRunLoopDefaultMode);
  CFRunLoopRun();
}

- (CFSocketError)writeData:(NSData *)data {
  if (_socket == NULL || !CFSocketIsValid(_socket)) {
    NSLog(@"Socket NULL or invalid, but trying to send %@", data);
    return kCFSocketError;
  }

  return CFSocketSendData(_socket, NULL, (__bridge CFDataRef) data, _timeout);
}

- (void)dataCallbackWithData:(NSData *)data {
  if (_dataCallback == nil) {
    return;
  }

  _dataCallback(data);
}

@end
