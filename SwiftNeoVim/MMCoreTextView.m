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
 * Extracted from snapshot-131 of MacVim
 * https://github.com/macvim-dev/macvim
 * See VIM.LICENSE
 */

// We suppress the following warnings since the original code does have it...
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wshorten-64-to-32"

#import "MMCoreTextView.h"

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
                            [NSNumber numberWithInteger:(useLigatures ? 1 : 0)],
                            kCTLigatureAttributeName,
                            nil
    ];

    return CFAttributedStringCreate(NULL, (CFStringRef)string,
                                    (CFDictionaryRef)attrs);
}

    static UniCharCount
fetchGlyphsAndAdvances(const CTLineRef line, CGGlyph *glyphs, CGSize *advances,
                       UniCharCount length)
{
    NSArray *glyphRuns = (NSArray*)CTLineGetGlyphRuns(line);

    // get a hold on the actual character widths and glyphs in line
    UniCharCount offset = 0;
    for (id item in glyphRuns) {
        CTRunRef run  = (CTRunRef)item;
        CFIndex count = CTRunGetGlyphCount(run);

        if (count > 0 && count - offset > length)
            count = length - offset;

        CFRange range = CFRangeMake(0, count);

        if (glyphs != NULL)
            CTRunGetGlyphs(run, range, &glyphs[offset]);
        if (advances != NULL)
            CTRunGetAdvances(run, range, &advances[offset]);

        offset += count;
        if (offset >= length)
            break;
    }

    return offset;
}

    static size_t
gatherGlyphs(CGGlyph glyphs[], UniCharCount count)
{
    // Gather scattered glyphs that was happended by Surrogate pair chars
    size_t glyphCount = 0;
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
ligatureGlyphsForChars(const unichar *chars, CGGlyph *glyphs,
                       CGPoint *positions, UniCharCount length, CTFontRef font)
{
    // CoreText has no simple wait of retrieving a ligature for a set of
    // UniChars. The way proposed on the CoreText ML is to convert the text to
    // an attributed string, create a CTLine from it and retrieve the Glyphs
    // from the CTRuns in it.
    CGGlyph refGlyphs[length];
    CGPoint refPositions[length];

    memcpy(refGlyphs, glyphs, sizeof(CGGlyph) * length);
    memcpy(refPositions, positions, sizeof(CGSize) * length);

    memset(glyphs, 0, sizeof(CGGlyph) * length);

    NSString *plainText = [NSString stringWithCharacters:chars length:length];
    CFAttributedStringRef ligatureText = attributedStringForString(plainText,
                                                                   font, YES);

    CTLineRef ligature = CTLineCreateWithAttributedString(ligatureText);

    CGSize ligatureRanges[length], regularRanges[length];

    // get the (ligature)glyphs and advances for the new text
    UniCharCount offset = fetchGlyphsAndAdvances(ligature, glyphs,
                                                 ligatureRanges, length);
    // fetch the advances for the base text
    CTFontGetAdvancesForGlyphs(font, kCTFontOrientationDefault, refGlyphs,
                               regularRanges, length);

    CFRelease(ligatureText);
    CFRelease(ligature);

    // tricky part: compare both advance ranges and chomp positions which are
    // covered by a single ligature while keeping glyphs not in the ligature
    // font.
#define fequal(a, b) (fabs((a) - (b)) < FLT_EPSILON)
#define fless(a, b)((a) - (b) < FLT_EPSILON) && (fabs((a) - (b)) > FLT_EPSILON)

    CFIndex skip = 0;
    CFIndex i;
    for (i = 0; i < offset && skip + i < length; ++i) {
        memcpy(&positions[i], &refPositions[skip + i], sizeof(CGSize));

        if (fequal(ligatureRanges[i].width, regularRanges[skip + i].width)) {
            // [mostly] same width
            continue;
        } else if (fless(ligatureRanges[i].width,
                         regularRanges[skip + i].width)) {
            // original is wider than our result - use the original glyph
            // FIXME: this is currently the only way to detect emoji (except
            // for 'glyph[i] == 5')
            glyphs[i] = refGlyphs[skip + i];
            continue;
        }

        // no, that's a ligature
        // count how many positions this glyph would take up in the base text
        CFIndex j = 0;
        float width = ceil(regularRanges[skip + i].width);

        while ((int)width < (int)ligatureRanges[i].width
                && skip + i + j < length) {
            width += ceil(regularRanges[++j + skip + i].width);
        }
        skip += j;
    }

#undef fless
#undef fequal

    // as ligatures combine characters it is required to adjust the
    // original length value
    return offset;
}

    size_t
recurseDraw(const unichar *chars, CGGlyph *glyphs, CGPoint *positions,
            UniCharCount length, CGContextRef context, CTFontRef fontRef,
            NSMutableArray *fontCache, BOOL useLigatures)
{
    if (CTFontGetGlyphsForCharacters(fontRef, chars, glyphs, length)) {
        // All chars were mapped to glyphs, so draw all at once and return.
        if (useLigatures) {
            length = ligatureGlyphsForChars(chars, glyphs, positions, length,
                                            fontRef);
        } else {
            // only fixup surrogate pairs if we're not using ligatures
            length = gatherGlyphs(glyphs, length);
        }

        CTFontDrawGlyphs(fontRef, glyphs, positions, length, context);
        return length;
    }

    CGPoint *positionsStart = positions;
    CGGlyph *glyphsEnd = glyphs+length, *g = glyphs;
    CGPoint *p;
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
            }
            size_t count = g - glyphs;
            if (surrogatePair)
                count = gatherGlyphs(glyphs, count);
            CTFontDrawGlyphs(fontRef, glyphs, positions, count, context);
            p = positions + count;
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
            }

            // Try to find a fallback font that can render the entire
            // invalid range. If that fails, repeatedly halve the attempted
            // range until a font is found.
            size_t count = c - chars;
            size_t attemptedCount = count;
            CTFontRef fallback = nil;
            bool endsWithSurrogate;
            bool beginsWithSurrogate;
            beginsWithSurrogate = count > 0
                    ? CFStringIsSurrogateHighCharacter(chars[0])
                    : false;
            while (fallback == nil && attemptedCount > 0) {
                fallback = lookupFont(fontCache, chars, attemptedCount,
                                      fontRef);
                if (fallback) continue;
                if (attemptedCount == 2 && beginsWithSurrogate) {
                    attemptedCount = 0;
                    continue;
                }

                attemptedCount /= 2;
                if (attemptedCount <= 0) continue;

                const unichar last = chars[attemptedCount - 1];
                endsWithSurrogate = CFStringIsSurrogateHighCharacter(last);
                if (!endsWithSurrogate) continue;

                ++attemptedCount;
            }

            if (!fallback)
                return positionsStart - positions;

            size_t attemptedPcount =recurseDraw(chars,
                    glyphs, positions, attemptedCount, context,
                    fallback, fontCache, useLigatures);

            // If only a portion of the invalid range was rendered above,
            // the remaining range needs to be attempted by subsequent
            // iterations of the draw loop.
            c -= count - attemptedCount;
            g -= count - attemptedCount;
            p = positions + attemptedPcount;

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
    return positionsStart - positions;
}

#pragma clang diagnostic pop
