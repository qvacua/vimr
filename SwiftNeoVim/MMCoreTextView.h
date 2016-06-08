@import Cocoa;
@import CoreText;

CTFontRef lookupFont(NSMutableArray *fontCache, const unichar *chars, UniCharCount count, CTFontRef currFontRef);
CFAttributedStringRef attributedStringForString(NSString *string, const CTFontRef font, BOOL useLigatures);
UniCharCount fetchGlyphsAndAdvances(const CTLineRef line, CGGlyph *glyphs, CGSize *advances, UniCharCount length);
UniCharCount gatherGlyphs(CGGlyph glyphs[], UniCharCount count);
UniCharCount ligatureGlyphsForChars(const unichar *chars, CGGlyph *glyphs, CGPoint *positions, UniCharCount length, CTFontRef font);
void recurseDraw(const unichar *chars, CGGlyph *glyphs, CGPoint *positions, UniCharCount length, CGContextRef context, CTFontRef fontRef, NSMutableArray *fontCache, BOOL useLigatures);
