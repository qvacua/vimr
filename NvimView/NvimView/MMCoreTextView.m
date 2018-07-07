/* vi:set ts=8 sts=4 sw=4 ft=objc:
 *
 * VIM - Vi IMproved		by Bram Moolenaar
 *				MacVim GUI port by Bjorn Winckler
 *
 * Do ":help uganda"  in Vim to read copying and usage conditions.
 * Do ":help credits" in Vim to see a list of people who contributed.
 * See README.txt for an overview of the Vim source code.
 */

/**
 * Extracted from 351faf929e4abe32ea4cc31078d1a625fc86a69f of MacVim, 2018-07-03
 * https://github.com/macvim-dev/macvim
 * See VIM.LICENSE
 */

// We suppress the following warnings since the original code does have it...
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wshorten-64-to-32"

#import "MMCoreTextView.h"

// @formatter:off

    static CTFontRef
lookupFont(NSMutableArray *fontCache, const unichar *chars, UniCharCount count,
           CTFontRef currFontRef)
{
    CGGlyph glyphs[count];

    // See if font in cache can draw at least one character
    NSUInteger i;
    for (i = 0; i < [fontCache count]; ++i) {
        NSFont *font = [fontCache objectAtIndex:i];

        if (CTFontGetGlyphsForCharacters((CTFontRef)font, chars, glyphs, count))
            return (CTFontRef)[font retain];
    }

    // Ask Core Text for a font (can be *very* slow, which is why we cache
    // fonts in the first place)
    CFRange r = { 0, count };
    CFStringRef strRef = CFStringCreateWithCharacters(NULL, chars, count);
    CTFontRef newFontRef = CTFontCreateForString(currFontRef, strRef, r);
    CFRelease(strRef);

    // Verify the font can actually convert all the glyphs.
    if (!CTFontGetGlyphsForCharacters(newFontRef, chars, glyphs, count))
        return nil;

    if (newFontRef)
        [fontCache addObject:(NSFont *)newFontRef];

    return newFontRef;
}

    static CFAttributedStringRef
attributedStringForString(NSString *string, const CTFontRef font,
                          BOOL useLigatures)
{
    NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                            (id)font, kCTFontAttributeName,
                            // 2 - full ligatures including rare
                            // 1 - basic ligatures
                            // 0 - no ligatures
                            [NSNumber numberWithBool:useLigatures],
                            kCTLigatureAttributeName,
                            nil
    ];

    return CFAttributedStringCreate(NULL, (CFStringRef)string,
                                    (CFDictionaryRef)attrs);
}

    static UniCharCount
fetchGlyphsAndAdvances(const CTLineRef line, CGGlyph *glyphs, CGSize *advances,
                       CGPoint *positions, UniCharCount length)
{
    NSArray *glyphRuns = (NSArray*)CTLineGetGlyphRuns(line);

    // get a hold on the actual character widths and glyphs in line
    UniCharCount offset = 0;
    for (id item in glyphRuns) {
        CTRunRef run  = (CTRunRef)item;
        CFIndex count = CTRunGetGlyphCount(run);

        if (count > 0) {
            if (count > length - offset)
                count = length - offset;

            CFRange range = CFRangeMake(0, count);

            if (glyphs != NULL)
                CTRunGetGlyphs(run, range, &glyphs[offset]);
            if (advances != NULL)
                CTRunGetAdvances(run, range, &advances[offset]);
            if (positions != NULL)
                CTRunGetPositions(run, range, &positions[offset]);

            offset += count;
            if (offset >= length)
                break;
        }
    }

    return offset;
}

    static UniCharCount
gatherGlyphs(CGGlyph glyphs[], UniCharCount count)
{
    // Gather scattered glyphs that was happended by Surrogate pair chars
    UniCharCount glyphCount = 0;
    NSUInteger pos = 0;
    NSUInteger i;
    for (i = 0; i < count; ++i) {
        if (glyphs[i] != 0) {
            ++glyphCount;
            glyphs[pos++] = glyphs[i];
        }
    }
    return glyphCount;
}

    static UniCharCount
composeGlyphsForChars(const unichar *chars, CGGlyph *glyphs,
                      CGPoint *positions, UniCharCount length, CTFontRef font,
                      BOOL isComposing, BOOL useLigatures)
{
    memset(glyphs, 0, sizeof(CGGlyph) * length);

    NSString *plainText = [NSString stringWithCharacters:chars length:length];
    CFAttributedStringRef composedText = attributedStringForString(plainText,
                                                                   font,
                                                                   useLigatures);

    CTLineRef line = CTLineCreateWithAttributedString(composedText);

    // get the (composing)glyphs and advances for the new text
    UniCharCount offset = fetchGlyphsAndAdvances(line, glyphs, NULL,
                                                 isComposing ? positions : NULL,
                                                 length);

    CFRelease(composedText);
    CFRelease(line);

    // as ligatures composing characters it is required to adjust the
    // original length value
    return offset;
}

    void
recurseDraw(const unichar *chars, CGGlyph *glyphs, CGPoint *positions,
            UniCharCount length, CGContextRef context, CTFontRef fontRef,
            NSMutableArray *fontCache, BOOL isComposing, BOOL useLigatures)
{
    if (CTFontGetGlyphsForCharacters(fontRef, chars, glyphs, length)) {
        // All chars were mapped to glyphs, so draw all at once and return.
        length = composeGlyphsForChars(chars, glyphs, positions, length,
                                       fontRef, isComposing, useLigatures);
        CTFontDrawGlyphs(fontRef, glyphs, positions, length, context);
        return;
    }

    CGGlyph *glyphsEnd = glyphs+length, *g = glyphs;
    CGPoint *p = positions;
    const unichar *c = chars;
    while (glyphs < glyphsEnd) {
        if (*g) {
            // Draw as many consecutive glyphs as possible in the current font
            // (if a glyph is 0 that means it does not exist in the current
            // font).
            BOOL surrogatePair = NO;
            while (*g && g < glyphsEnd) {
                if (CFStringIsSurrogateHighCharacter(*c)) {
                    surrogatePair = YES;
                    g += 2;
                    c += 2;
                } else {
                    ++g;
                    ++c;
                }
                ++p;
            }

            int count = g-glyphs;
            if (surrogatePair)
                count = gatherGlyphs(glyphs, count);
            CTFontDrawGlyphs(fontRef, glyphs, positions, count, context);
        } else {
            // Skip past as many consecutive chars as possible which cannot be
            // drawn in the current font.
            while (0 == *g && g < glyphsEnd) {
                if (CFStringIsSurrogateHighCharacter(*c)) {
                    g += 2;
                    c += 2;
                } else {
                    ++g;
                    ++c;
                }
                ++p;
            }

            // Try to find a fallback font that can render the entire
            // invalid range. If that fails, repeatedly halve the attempted
            // range until a font is found.
            UniCharCount count = c - chars;
            UniCharCount attemptedCount = count;
            CTFontRef fallback = nil;
            while (fallback == nil && attemptedCount > 0) {
                fallback = lookupFont(fontCache, chars, attemptedCount,
                                      fontRef);
                if (!fallback)
                    attemptedCount /= 2;
            }

            if (!fallback)
                return;

            recurseDraw(chars, glyphs, positions, attemptedCount, context,
                        fallback, fontCache, isComposing, useLigatures);

            // If only a portion of the invalid range was rendered above,
            // the remaining range needs to be attempted by subsequent
            // iterations of the draw loop.
            c -= count - attemptedCount;
            g -= count - attemptedCount;
            p -= count - attemptedCount;

            CFRelease(fallback);
        }

        if (glyphs == g) {
           // No valid chars in the glyphs. Exit from the possible infinite
           // recursive call.
           break;
        }

        chars = c;
        glyphs = g;
        positions = p;
    }
}

// @formatter:on

#pragma clang diagnostic pop
