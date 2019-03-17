/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

#import <Foundation/Foundation.h>

#import "NvimServer.h"
#import "server_ui.h"
#import "Logging.h"
#import "CocoaCategories.h"


NvimServer *_neovim_server;
os_log_t glog;

static void observe_parent_termination(CFRunLoopRef mainRunLoop) {
  pid_t parentPID = getppid();

  dispatch_queue_t queue = dispatch_get_global_queue(
      DISPATCH_QUEUE_PRIORITY_DEFAULT, 0
  );
  dispatch_source_t source = dispatch_source_create(
      DISPATCH_SOURCE_TYPE_PROC,
      (uintptr_t) parentPID,
      DISPATCH_PROC_EXIT,
      queue
  );

  if (source == NULL) {
    os_log_error(glog, "No parent process monitoring...");
    return;
  }

  dispatch_source_set_event_handler(source, ^{
    os_log_fault(glog, "Exiting neovim server due to parent termination.");
    CFRunLoopStop(mainRunLoop);
    dispatch_source_cancel(source);
  });

  dispatch_resume(source);
}

int main(int argc, const char *argv[]) {
  glog = os_log_create("com.qvacua.NvimServer", "server");

  CFRunLoopRef mainRunLoop = CFRunLoopGetCurrent();
  observe_parent_termination(mainRunLoop);

  @autoreleasepool {
    NSArray<NSString *> *arguments = [NSProcessInfo processInfo].arguments;
    NSString *remoteServerName = arguments[1];
    NSString *localServerName = arguments[2];
    NSArray<NSString *> *nvimArgs = argc > 3
        ? [arguments subarrayWithRange:NSMakeRange(3, (NSUInteger) (argc - 3))]
        : nil;

    _neovim_server = [
        [NvimServer alloc] initWithLocalServerName:localServerName
                                  remoteServerName:remoteServerName
                                          nvimArgs:nvimArgs
    ];
    os_log(glog, "Started neovim server '%s' with args '%@'"
                 " and connected it with the remote agent '%s'.",
        localServerName.cstr, nvimArgs, remoteServerName.cstr);

    [_neovim_server notifyReadiness];
  }

  CFRunLoopRun();

  os_log(glog, "NvimServer returning.");
  return 0;
}
