#import <Cocoa/Cocoa.h>
#import <CoreText/CoreText.h>

void recurseDraw(
    const unichar *chars,
    CGGlyph *glyphs,
    CGPoint *positions,
    UniCharCount length,
    CGContextRef context,
    CTFontRef fontRef,
    NSMutableArray *fontCache,
    BOOL isComposing,
    BOOL useLigatures
);
