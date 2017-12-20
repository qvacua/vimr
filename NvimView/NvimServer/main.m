/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

@import Foundation;

#import "NvimServer.h"
#import "server_globals.h"
#import "Logging.h"
#import "CocoaCategories.h"


NvimServer *_neovim_server;
CFRunLoopRef _mainRunLoop;

static void observe_parent_termination() {
  pid_t parentPID = getppid();

  dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
  dispatch_source_t source = dispatch_source_create(
      DISPATCH_SOURCE_TYPE_PROC, (uintptr_t) parentPID, DISPATCH_PROC_EXIT, queue
  );

  if (source == NULL) {
    WLOG("No parent process monitoring...");
    return;
  }

  dispatch_source_set_event_handler(source, ^{
    WLOG("Exiting neovim server due to parent termination.");
    CFRunLoopStop(_mainRunLoop);
    dispatch_source_cancel(source);
  });

  dispatch_resume(source);
}

int main(int argc, const char *argv[]) {
  _mainRunLoop = CFRunLoopGetCurrent();
  observe_parent_termination();

  @autoreleasepool {
    NSArray<NSString *> *arguments = [NSProcessInfo processInfo].arguments;
    NSString *remoteServerName = arguments[1];
    NSString *localServerName = arguments[2];
    NSArray<NSString *> *nvimArgs = argc > 3 ? [arguments subarrayWithRange:NSMakeRange(3, (NSUInteger) (argc - 3))]
                                             : nil;

    _neovim_server = [[NvimServer alloc] initWithLocalServerName:localServerName
                                                  remoteServerName:remoteServerName
                                                          nvimArgs:nvimArgs];
    DLOG("Started neovim server '%s' with args '%@' and connected it with the remote agent '%s'.",
        localServerName.cstr, nvimArgs, remoteServerName.cstr);

    [_neovim_server notifyReadiness];
  }

  CFRunLoopRun();

  DLOG("NvimServer returning.");
  return 0;
}
