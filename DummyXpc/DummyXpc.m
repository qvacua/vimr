//
//  DummyXpc.m
//  DummyXpc
//
//  Created by Tae Won Ha on 07/07/16.
//  Copyright © 2016 Tae Won Ha. All rights reserved.
//

#import "DummyXpc.h"


@implementation DummyXpc

- (instancetype)init {
  self = [super init];
  if (self == nil) {
    return nil;
  }

  return self;
}

// This implements the example protocol. Replace the body of this class with the implementation of this service's protocol.
- (void)upperCaseString:(NSString *)aString withReply:(void (^)(NSString *))reply {
  NSString *response = [aString uppercaseString];
  reply(response);
}

@end
