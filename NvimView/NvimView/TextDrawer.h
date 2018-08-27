/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

#import <Cocoa/Cocoa.h>
#import <CoreText/CoreText.h>


#import "SharedTypes.h"


typedef struct {
    FontTrait fontTrait;

    NSInteger foreground;
    NSInteger background;
    NSInteger special;
    bool reverse;
} OldCellAttributes;

@interface TextDrawer : NSObject

@property (nonatomic, nonnull, retain) NSFont *font;
@property (nonatomic) bool usesLigatures;
@property (nonatomic, readonly) CGFloat baselineOffset;
@property (nonatomic, readonly) CGFloat leading;
@property (nonatomic, readonly) CGFloat descent;
@property (nonatomic) CGFloat linespacing;
@property (nonatomic, readonly) CGSize cellSize;

- (instancetype _Nonnull)initWithFont:(NSFont *_Nonnull)font;

- (void)drawString:(NSString *_Nonnull)string
         positions:(CGPoint *_Nonnull)positions positionsCount:(NSInteger)positionsCount
    highlightAttrs:(OldCellAttributes)attrs
           context:(CGContextRef _Nonnull)context;

@end
