/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

@import Cocoa;


@protocol NeoVimUiBridgeProtocol;


NS_ASSUME_NONNULL_BEGIN

@interface NeoVimAgent : NSObject

@property (nonatomic, weak) id <NeoVimUiBridgeProtocol> bridge;

- (instancetype)initWithUuid:(NSString *)uuid;
- (void)cleanUp;
- (void)establishLocalServer;

- (void)vimCommand:(NSString *)string;

- (void)vimInput:(NSString *)string;
- (void)vimInputMarkedText:(NSString *_Nonnull)markedText;
- (void)deleteCharacters:(NSInteger)count;
- (void)forceRedraw;
- (void)resizeToWidth:(int)width height:(int)height;

- (bool)hasDirtyDocs;

@end

NS_ASSUME_NONNULL_END
