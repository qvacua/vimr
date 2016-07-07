//
//  XpcMatchMaker.m
//  XpcMatchMaker
//
//  Created by Tae Won Ha on 07/07/16.
//  Copyright © 2016 Tae Won Ha. All rights reserved.
//

#import "XpcMatchMaker.h"
#import "XpcMatchMakerServer.h"
#import "NeoVimXpcManagerProtocol.h"


@implementation XpcMatchMaker {
  NSConnection *_connection;
  NSString *_uuid;
  XpcMatchMakerServer *_server;
  id <NeoVimXpcManagerProtocol> _neoVimXpcManager;
}

- (instancetype)initWithNeoVimXpcManager:(id <NeoVimXpcManagerProtocol>)neoVimXpcManager {
  self = [super init];
  if (self == nil) {
    return nil;
  }
  
  _neoVimXpcManager = neoVimXpcManager;
  
  return self;
}

- (void)setServerUuid:(NSString *)uuid {
  _uuid = uuid;
  
  _server = [[XpcMatchMakerServer alloc] initWithUuid:_uuid neoVimXpcManager:_neoVimXpcManager];

  _connection = [[NSConnection alloc] init];
  _connection.rootObject = _server;

  NSString *serverId = [NSString stringWithFormat:@"com.qvacua.nvox.xpc-match-maker.%@", _server.uuid];
  NSLog(@"server name: %@", serverId);
  if (![_connection registerName:serverId]) {
    NSLog(@"The xpc match maker server could not be started!");
  }

  [[NSRunLoop currentRunLoop] run];
}

@end
