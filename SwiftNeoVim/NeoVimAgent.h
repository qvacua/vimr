/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

@import Cocoa;


#import "NeoVimUiBridgeProtocol.h"


@class NeoVimBuffer;
@class NeoVimTab;
@class NeoVimWindow;


NS_ASSUME_NONNULL_BEGIN

@interface NeoVimAgent : NSObject

@property (nonatomic) bool useInteractiveZsh;
@property (nonatomic) NSURL *cwd;
@property (nonatomic, nullable) NSArray<NSString *> *nvimArgs;
@property (readonly) bool neoVimIsQuitting;
@property (nonatomic, weak) id <NeoVimUiBridgeProtocol> bridge;

@property (readonly) bool neoVimHasQuit;
@property (readonly) NSCondition *neoVimQuitCondition;

- (instancetype)initWithUuid:(NSString *)uuid;

- (void)debug;

- (void)forceQuit;
- (void)quit;

- (bool)runLocalServerAndNeoVimWithWidth:(NSInteger)width height:(NSInteger)height;

- (NSURL *)pwd;
- (void)vimCommand:(NSString *)string;

- (void)vimInput:(NSString *)string;
- (void)vimInputMarkedText:(NSString *)markedText;
- (void)deleteCharacters:(NSInteger)count;

- (void)resizeToWidth:(int)width height:(int)height;
- (void)cursorGoToRow:(int)row column:(int)column;

- (NSString * _Nullable)escapedFileName:(NSString *)fileName;
- (NSArray<NSString *> *)escapedFileNames:(NSArray<NSString *> *)fileNames;
//- (NSArray<NeoVimBuffer *> *)buffers;
- (NSArray<NeoVimTab*> *)tabs;

- (void)scrollHorizontal:(NSInteger)horiz vertical:(NSInteger)vert at:(Position)position;
- (void)selectWindow:(NeoVimWindow *)window;

// WAITS
- (NSString * _Nullable)vimCommandOutput:(NSString *)string;
- (NSNumber * _Nullable)boolOption:(NSString *)option;
- (void)setBoolOption:(NSString *)option to:(bool)value;

- (void)focusGained:(bool)gained;

@end

NS_ASSUME_NONNULL_END
