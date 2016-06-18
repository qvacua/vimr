/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

@import Cocoa;
@import CoreText;

#import "NeoVimUiBridgeProtocol.h"

@interface TextDrawer : NSObject

@property (nonatomic, nonnull, retain) NSFont *font;
@property (nonatomic, readonly) CGFloat lineSpace;
@property (nonatomic, readonly) CGSize cellSize;

- (instancetype _Nonnull)initWithFont:(NSFont *_Nonnull)font;

- (void)drawString:(NSString *_Nonnull)string
         positions:(CGPoint *_Nonnull)positions positionsCount:(NSInteger)positionsCount
    highlightAttrs:(CellAttributes)attrs
           context:(CGContextRef _Nonnull)context;

@end
