/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

@import Cocoa;


@protocol NeoVimUiBridgeProtocol;
@class NeoVimBuffer;


NS_ASSUME_NONNULL_BEGIN

@interface NeoVimAgent : NSObject

@property (nonatomic, weak) id <NeoVimUiBridgeProtocol> bridge;

- (instancetype)initWithUuid:(NSString *)uuid;
- (void)quit;

- (void)runLocalServerAndNeoVimWithPath:(NSString *)path;

- (void)vimCommand:(NSString *)string;

- (void)vimInput:(NSString *)string;
- (void)vimInputMarkedText:(NSString *_Nonnull)markedText;
- (void)deleteCharacters:(NSInteger)count;

- (void)resizeToWidth:(int)width height:(int)height;

- (bool)hasDirtyDocs;
- (NSString *)escapedFileName:(NSString *)fileName;
- (NSArray<NSString *> *)escapedFileNames:(NSArray<NSString *> *)fileNames;
- (NSArray<NeoVimBuffer *> *)buffers;

@end

NS_ASSUME_NONNULL_END
