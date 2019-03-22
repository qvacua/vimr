/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

#import <Foundation/Foundation.h>

#import "NvimServer.h"
#import "Logging.h"


NvimServer *_neovim_server;
os_log_t logger;

static void observe_parent_termination(CFRunLoopRef mainRunLoop) {
  const pid_t parent_pid = getppid();

  const dispatch_queue_t queue = dispatch_get_global_queue(
      DISPATCH_QUEUE_PRIORITY_DEFAULT, 0
  );
  dispatch_source_t source = dispatch_source_create(
      DISPATCH_SOURCE_TYPE_PROC,
      (uintptr_t) parent_pid,
      DISPATCH_PROC_EXIT,
      queue
  );

  if (source == NULL) {
    os_log_error(logger, "No parent process monitoring...");
    return;
  }

  dispatch_source_set_event_handler(source, ^{
    os_log_fault(logger, "Exiting neovim server due to parent termination.");
    CFRunLoopStop(mainRunLoop);
    dispatch_source_cancel(source);
  });

  dispatch_resume(source);
}

int main(int argc, const char *argv[]) {
  logger = os_log_create("com.qvacua.NvimServer", "server");

  CFRunLoopRef const mainRunLoop = CFRunLoopGetCurrent();
  observe_parent_termination(mainRunLoop);

  @autoreleasepool {
    NSArray<NSString *> *const arguments
        = [NSProcessInfo processInfo].arguments;
    NSString *const remoteServerName = arguments[1];
    NSString *const localServerName = arguments[2];
    NSArray<NSString *> *const nvimArgs = argc > 3
        ? [arguments subarrayWithRange:NSMakeRange(3, (NSUInteger) (argc - 3))]
        : nil;

    _neovim_server = [
        [NvimServer alloc] initWithLocalServerName:localServerName
                                  remoteServerName:remoteServerName
                                          nvimArgs:nvimArgs
    ];
    os_log_debug(
        logger,
        "Started neovim server '%@' with args '%@'"
        " and connected it with the remote agent '%@'.",
        localServerName, nvimArgs, remoteServerName
    );

    [_neovim_server notifyReadiness];
  }

  CFRunLoopRun();

  os_log_debug(logger, "NvimServer returning.");
  return 0;
}
