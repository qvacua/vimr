/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

#import <Foundation/Foundation.h>
#import "NeoVimXpc.h"

@protocol NeoVimUi;

@interface NeoVimXpcImpl : NSObject <NeoVimXpc>

- (instancetype)initWithNeoVimUi:(id<NeoVimUi>)ui;

@end
