/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

#import <Foundation/Foundation.h>
#import "NeoVimXpc.h"

@protocol NeoVimUi;

@interface NeoVimXpcImpl : NSObject <NeoVimXpc>

- (instancetype)init;

- (void)setNeoVimUi:(id<NeoVimUi>)ui;

@end
