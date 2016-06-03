/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

#import <Foundation/Foundation.h>
#import "NeoVimXpcImpl.h"

@interface NVXpcDelegate : NSObject <NSXPCListenerDelegate>
@end

@implementation NVXpcDelegate

- (BOOL)listener:(NSXPCListener *)listener shouldAcceptNewConnection:(NSXPCConnection *)newConnection {
  newConnection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(NeoVimXpc)];
  newConnection.exportedObject = [NeoVimXpcImpl new];
  [newConnection resume];

  return YES;
}

@end

int main(int argc, const char *argv[]) {
  NVXpcDelegate *delegate = [NVXpcDelegate new];

  NSXPCListener *listener = [NSXPCListener serviceListener];
  listener.delegate = delegate;

  // this method does not return
  [listener resume];

  return 0;
}
