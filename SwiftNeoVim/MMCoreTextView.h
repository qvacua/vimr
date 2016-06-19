@import Cocoa;
@import CoreText;

void recurseDraw(
    const unichar *chars,
    CGGlyph *glyphs, CGPoint *positions, UniCharCount length,
    CGContextRef context,
    CTFontRef fontRef,
    NSMutableArray *fontCache,
    BOOL useLigatures
);
