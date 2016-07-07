//
//  Server.m
//  nvox
//
//  Created by Tae Won Ha on 07/07/16.
//  Copyright © 2016 Tae Won Ha. All rights reserved.
//

#import "XpcMatchMakerServer.h"
#import "NeoVimXpcManagerProtocol.h"


@implementation XpcMatchMakerServer {
  id <NeoVimXpcManagerProtocol> _neoVimXpcManager;
}

- (instancetype)initWithUuid:(NSString *)uuid neoVimXpcManager:(id <NeoVimXpcManagerProtocol>)neoVimXpcManager {
  self = [super init];
  if (self == nil) {
    return nil;
  }

  _uuid = uuid;
  _neoVimXpcManager = neoVimXpcManager;

  return self;
}

- (void)registerNeoVimWithUuid:(NSString *)neoVimUuid endpoint:(NSData *)endpointData {
  NSLog(@"register: %@", neoVimUuid);

  NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:endpointData];
  NSXPCListenerEndpoint *endpoint = [unarchiver decodeObject];
  
  [_neoVimXpcManager shouldAcceptEndpoint:endpoint forNeoVimUuid:neoVimUuid];
}

@end
