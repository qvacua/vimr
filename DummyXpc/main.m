//
//  main.m
//  DummyXpc
//
//  Created by Tae Won Ha on 07/07/16.
//  Copyright © 2016 Tae Won Ha. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DummyXpc.h"
#import "XpcMatchMakerServer.h"


@interface NSXPCListener (nvox)

- (id)replacementObjectForPortCoder:(NSPortCoder *)encoder;

@end

@implementation NSXPCListener (nvox)

- (id)replacementObjectForPortCoder:(NSPortCoder *)encoder {
  if (encoder.isBycopy) {
    return self;
  }

  return [super replacementObjectForPortCoder:encoder];
}

@end


@interface ServiceDelegate : NSObject <NSXPCListenerDelegate>
@end

@implementation ServiceDelegate

- (BOOL)listener:(NSXPCListener *)listener shouldAcceptNewConnection:(NSXPCConnection *)newConnection {
  // This method is where the NSXPCListener configures, accepts, and resumes a new incoming NSXPCConnection.

  // Configure the connection.
  // First, set the interface that the exported object implements.
  newConnection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(DummyXpcProtocol)];

  // Next, set the object that the connection exports. All messages sent on the connection to this service will be sent to the exported object to handle. The connection retains the exported object.
  DummyXpc *exportedObject = [DummyXpc new];
  newConnection.exportedObject = exportedObject;

  // Resuming the connection allows the system to deliver more incoming messages.
  [newConnection resume];

  // Returning YES from this method tells the system that you have accepted this connection. If you want to reject the connection for some reason, call -invalidate on the connection and return NO.
  return YES;
}

@end

int main(int argc, const char *argv[]) {
  ServiceDelegate *delegate = [ServiceDelegate new];

  NSArray<NSString *> *arguments = [NSProcessInfo processInfo].arguments;
  NSString *serverUuid = arguments[1];
  NSString *serverName = [NSString stringWithFormat:@"com.qvacua.nvox.xpc-match-maker.%@", serverUuid];
  NSLog(@"server name: %@", serverName);

  NSConnection *connection = [NSConnection connectionWithRegisteredName:serverName host:nil];
  id server = connection.rootProxy;
  [server setProtocolForProxy:@protocol(XpcMatchMakerServerProtocol)];
  
  NSXPCListener *listener = [NSXPCListener anonymousListener];
  listener.delegate = delegate;

  NSMutableData *endpointData = [NSMutableData new];
  NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:endpointData];
  [archiver encodeObject:listener.endpoint];
  [server registerNeoVimWithUuid:arguments[2] endpoint:endpointData];

  // Resuming the serviceListener starts this service. This method does not return.
  [listener resume];

  return 0;
}
