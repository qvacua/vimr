/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

#import <Foundation/Foundation.h>
#import "NeoVimServer.h"
#import "server_globals.h"
#import <sys/event.h>
#import <uv.h>


NeoVimServer *_neovim_server;

// Ensure no parent-less NeoVimServer processes are left when the main app crashes.
// From http://mac-os-x.10953.n7.nabble.com/Ensure-NSTask-terminates-when-parent-application-does-td31477.html
static void observe_parent_termination(void *arg) {
  pid_t ppid = getppid();     // get parent pid

  int kq = kqueue();
  if (kq != -1) {
    struct kevent procEvent;  // wait for parent to exit
    EV_SET(
        &procEvent,    // kevent
        ppid,          // ident
        EVFILT_PROC,   // filter
        EV_ADD,        // flags
        NOTE_EXIT,     // fflags
        0,             // data
        0              // udata
    );

    kevent(kq, &procEvent, 1, &procEvent, 1, 0);
  }

  printf("Terminating--Parent Process Terminated\n");
  exit(0);
}

int main(int argc, const char *argv[]) {
  uv_thread_t parent_observer_thread;
  uv_thread_create(&parent_observer_thread, observe_parent_termination, NULL);

  @autoreleasepool {
    NSArray<NSString *> *arguments = [NSProcessInfo processInfo].arguments;
    NSString *remoteServerName = arguments[1];
    NSString *localServerName = arguments[2];

    _neovim_server = [[NeoVimServer alloc] initWithLocalServerName:localServerName remoteServerName:remoteServerName];
    [_neovim_server notifyReadiness];
  }

  CFRunLoopRun();
  return 0;
}

