/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

#import <Foundation/Foundation.h>
#import "NeoVimUiBridgeProtocol.h"
#import "NeoVimServerMsgIds.h"


@interface NeoVimServer : NSObject

- (instancetype)initWithUuid:(NSString *)uuid
             localServerName:(NSString *)localServerName
            remoteServerName:(NSString *)remoteServerName;

- (NSData *)handleMessageWithId:(SInt32)msgid data:(NSData *)data;
- (void)sendMessageWithId:(NeoVimServerMsgId)msgid;
- (void)sendMessageWithId:(NeoVimServerMsgId)msgid data:(NSData *)data;
- (void)notifyReadiness;

@end
