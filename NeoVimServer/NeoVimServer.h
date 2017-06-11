/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

@import Foundation;

#import "NeoVimMsgIds.h"


@interface NeoVimServer : NSObject

- (instancetype)initWithLocalServerName:(NSString *)localServerName
                       remoteServerName:(NSString *)remoteServerName
                               nvimArgs:(NSArray<NSString *> *)nvimArgs;

- (void)sendMessageWithId:(NeoVimServerMsgId)msgid;
- (void)sendMessageWithId:(NeoVimServerMsgId)msgid data:(NSData *)data;
- (void)notifyReadiness;

@end
