/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

#import <Foundation/Foundation.h>
#import "NeoVimXpc.h"

@protocol NeoVimUiBridgeProtocol;

@interface NeoVimXpcImpl : NSObject <NeoVimXpc>

- (instancetype)initWithNeoVimUi:(id<NeoVimUiBridgeProtocol>)ui;

- (void)vimInput:(NSString *)input;

@end
