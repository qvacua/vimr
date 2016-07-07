//
//  XpcMatchMaker.h
//  XpcMatchMaker
//
//  Created by Tae Won Ha on 07/07/16.
//  Copyright © 2016 Tae Won Ha. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XpcMatchMakerProtocol.h"


@protocol NeoVimXpcManagerProtocol;

// This object implements the protocol which we have defined. It provides the actual behavior for the service. It is 'exported' by the service to make it available to the process hosting the service over an NSXPCConnection.
@interface XpcMatchMaker : NSObject <XpcMatchMakerProtocol>

- (instancetype)initWithNeoVimXpcManager:(id <NeoVimXpcManagerProtocol>)neoVimXpcManager;

@end
