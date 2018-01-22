/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

@import Foundation;

#import "SharedTypes.h"


@interface NvimServer : NSObject

- (instancetype)initWithLocalServerName:(NSString *)localServerName
                       remoteServerName:(NSString *)remoteServerName
                               nvimArgs:(NSArray<NSString *> *)nvimArgs;

- (void)sendMessageWithId:(NeoVimServerMsgId)msgid;
- (void)sendMessageWithId:(NeoVimServerMsgId)msgid data:(NSData *)data;
- (void)notifyReadiness;

@end
