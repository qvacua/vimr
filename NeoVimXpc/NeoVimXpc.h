/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

#import <Foundation/Foundation.h>

@protocol NeoVimXpc

- (void)upperCaseString:(NSString *)aString withReply:(void (^)(NSString *))reply;

- (void)doSth;
    
@end
