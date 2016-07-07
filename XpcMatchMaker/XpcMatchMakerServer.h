//
//  Server.h
//  nvox
//
//  Created by Tae Won Ha on 07/07/16.
//  Copyright © 2016 Tae Won Ha. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol NeoVimXpcManagerProtocol;


@protocol XpcMatchMakerServerProtocol

- (void)registerNeoVimWithUuid:(NSString *)neoVimUuid endpoint:(NSData *)endpointData;

@end


@interface XpcMatchMakerServer : NSObject <XpcMatchMakerServerProtocol>

@property (nonatomic, readonly) NSString *uuid;

- (instancetype)initWithUuid:(NSString *)uuid neoVimXpcManager:(id <NeoVimXpcManagerProtocol>)neoVimXpcManager;

@end
