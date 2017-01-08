/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

@import Foundation;

#import "NeoVimServer.h"
#import "server_globals.h"
#import "Logging.h"
#import "CocoaCategories.h"


NeoVimServer *_neovim_server;
CFRunLoopRef _mainRunLoop;

void observe_parent_termination() {
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

    _neovim_server = [[NeoVimServer alloc] initWithLocalServerName:localServerName remoteServerName:remoteServerName];
    DLOG("Started neovim server '%s' and connected it with the remote agent '%s'.",
         localServerName.cstr, remoteServerName.cstr);

    [_neovim_server notifyReadiness];
  }

  CFRunLoopRun();
  WLOG("Returning neovim server");
  return 0;
}
