/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

@import Cocoa;


#import "NvimUiBridgeProtocol.h"


NS_ASSUME_NONNULL_BEGIN

@interface UiClient : NSObject

@property (nonatomic) bool useInteractiveZsh;
@property (nonatomic, copy) NSURL *cwd;
@property (nonatomic, nullable, retain) NSArray<NSString *> *nvimArgs;
@property (readonly) bool neoVimIsQuitting;
@property (nonatomic, weak) id <NvimUiBridgeProtocol> bridge;

@property (readonly) bool neoVimHasQuit;
@property (readonly) NSCondition *neoVimQuitCondition;

- (instancetype)initWithUuid:(NSString *)uuid;

- (void)debug;

- (void)forceQuit;
- (void)quit;

- (bool)runLocalServerAndNeoVimWithWidth:(NSInteger)width height:(NSInteger)height;

- (void)vimInput:(NSString *)string;
- (void)vimInputMarkedText:(NSString *)markedText;
- (void)deleteCharacters:(NSInteger)count;

- (void)resizeToWidth:(int)width height:(int)height;

- (NSString * _Nullable)escapedFileName:(NSString *)fileName;
- (NSArray<NSString *> *)escapedFileNames:(NSArray<NSString *> *)fileNames;

- (void)scrollHorizontal:(NSInteger)horiz vertical:(NSInteger)vert at:(Position)position;

- (void)focusGained:(bool)gained;

@end

NS_ASSUME_NONNULL_END
