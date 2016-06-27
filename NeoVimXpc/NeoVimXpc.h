/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

@import Foundation;

@protocol NeoVimXpc <NSObject>

/**
 * It seems that the XPC service does not get instantiated as long as no actual calls are made. However, we want neovim
 * run as soon as we establish the connection. To achieve this, the client can call -probe which does not call anything
 * on neovim.
 */
- (void)probe;

- (void)vimInput:(NSString * _Nonnull)input;
- (void)vimInputMarkedText:(NSString *_Nonnull)markedText;

- (void)debugScreenLines;

@end
