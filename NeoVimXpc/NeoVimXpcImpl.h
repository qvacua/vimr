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

- (void)vimInput:(NSString *_Nonnull)input;
- (void)vimInputMarkedText:(NSString *_Nonnull)markedText;
- (NSData *)handleMessageWithId:(SInt32)msgid data:(NSData *)data;
- (void)deleteCharacters:(NSInteger)count;
- (void)forceRedraw;

- (void)resizeToWidth:(int)width height:(int)height;

@end
