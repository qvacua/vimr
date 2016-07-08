//
//  NeoVimUiClient.h
//  nvox
//
//  Created by Tae Won Ha on 08/07/16.
//  Copyright © 2016 Tae Won Ha. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol NeoVimXpc;

NS_ASSUME_NONNULL_BEGIN

@interface NeoVimUiWrapper : NSObject

- (instancetype)initWithUuid:(NSString *)uuid xpc:(id<NeoVimXpc>)xpc;

- (void)runLocalServer;

- (NSData *)handleMessageWithId:(SInt32)msgid data:(NSData *)data;

@end

NS_ASSUME_NONNULL_END
