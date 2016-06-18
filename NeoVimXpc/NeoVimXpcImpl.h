/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

@import Foundation;

#import "NeoVimXpc.h"

@protocol NeoVimUiBridgeProtocol;

@interface NeoVimXpcImpl : NSObject <NeoVimXpc>

- (instancetype _Nonnull)initWithNeoVimUi:(id<NeoVimUiBridgeProtocol> _Nonnull)ui;

- (void)probe;

- (void)vimInput:(NSString * _Nonnull)input;

- (void)debugScreenLines;

@end
