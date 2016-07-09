/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

#import <Foundation/Foundation.h>
#import "NeoVimServer.h"
#import "server_globals.h"


NeoVimServer *_neovim_server;

int main(int argc, const char *argv[]) {
  @autoreleasepool {
    NSArray<NSString *> *arguments = [NSProcessInfo processInfo].arguments;
    NSString *uuid = arguments[1];
    NSString *remoteServerName = arguments[2];
    NSString *localServerName = arguments[3];

    _neovim_server = [[NeoVimServer alloc] initWithUuid:uuid
                                        localServerName:localServerName
                                       remoteServerName:remoteServerName];
    [_neovim_server notifyReadiness];

    CFRunLoopRun();
  }

  return 0;
}

