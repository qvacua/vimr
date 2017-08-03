@import Cocoa;
@import CoreText;

size_t recurseDraw(
    const unichar *chars,
    CGGlyph *glyphs, CGPoint *positions, UniCharCount length,
    CGContextRef context,
    CTFontRef fontRef,
    NSMutableArray *fontCache,
    BOOL useLigatures
);
