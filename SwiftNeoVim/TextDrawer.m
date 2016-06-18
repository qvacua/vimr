/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 *
 * Almost a verbatim copy from MacVim by Bjorn Winckler
 * See VIM.LICENSE
 */

#import "TextDrawer.h"
#import "MMCoreTextView.h"
#import "NeoVimUiBridgeProtocol.h"

#define ALPHA(color_code)    (((color_code >> 24) & 0xff) / 255.0f)
#define RED(color_code)      (((color_code >> 16) & 0xff) / 255.0f)
#define GREEN(color_code)    (((color_code >>  8) & 0xff) / 255.0f)
#define BLUE(color_code)     (((color_code      ) & 0xff) / 255.0f)

@implementation TextDrawer {
  NSLayoutManager *_layoutManager;

  NSFont *_font;
  CGFloat _fontDescent;
  CGFloat _lineGap;

  NSMutableArray *_fontLookupCache;
  NSMutableDictionary *_fontTraitCache;
}

- (void)setFont:(NSFont *)font {
  [_font autorelease];
  _font = [font retain];

  _cellSize = CGSizeMake(
      round([@"m" sizeWithAttributes:@{ NSFontAttributeName : _font }].width),
      [_layoutManager defaultLineHeightForFont:_font] + _lineSpace
  );
  // https://developer.apple.com/library/mac/documentation/TextFonts/Conceptual/CocoaTextArchitecture/FontHandling/FontHandling.html
  _lineGap = _cellSize.height - _font.ascender - _font.descender;
  _fontDescent = CTFontGetDescent((CTFontRef) _font);
}

- (instancetype)initWithFont:(NSFont *_Nonnull)font {
  self = [super init];
  if (self == nil) {
    return nil;
  }

  _layoutManager = [[NSLayoutManager alloc] init];
  _fontLookupCache = [[NSMutableArray alloc] init];
  _fontTraitCache = [[NSMutableDictionary alloc] init];

  _lineSpace = 4;
  self.font = font;

  return self;
}

- (void)dealloc {
  [_layoutManager release];
  [_font release];
  [_fontLookupCache release];
  [_fontTraitCache release];

  [super dealloc];
}

/**
 * We assume that the background is drawn elsewhere and that the caller has already called
 *
 * CGContextSetTextMatrix(context, CGAffineTransformIdentity); // or some other matrix
 * CGContextSetTextDrawingMode(context, kCGTextFill); // or some other mode
 */
- (void)drawString:(NSString *_Nonnull)string
         positions:(CGPoint *_Nonnull)positions
    positionsCount:(NSInteger)positionsCount
    highlightAttrs:(CellAttributes)attrs
           context:(CGContextRef _Nonnull)context
{
  CGContextSaveGState(context);

  if (attrs.fontTrait & FontTraitUnderline) {
    CGRect rect = {
        {positions[0].x, positions[0].y - 1},
        {positions[0].x + positions[positionsCount - 1].x + _cellSize.width, 1}
    };
    [self drawUnderline:rect color:attrs.special context:context];
  }

  [self drawString:string positions:positions
         fontTrait:attrs.fontTrait foreground:attrs.foreground
           context:context];

  CGContextRestoreGState(context);
}

- (void)drawUnderline:(CGRect)rect color:(unsigned int)color context:(CGContextRef _Nonnull)context {
  CGContextSetRGBFillColor(context, RED(color), GREEN(color), BLUE(color), ALPHA(color));
  CGContextFillRect(context, rect);
}

- (void)drawString:(NSString *_Nonnull)nsstring
         positions:(CGPoint *_Nonnull)positions
         fontTrait:(FontTrait)fontTrait
        foreground:(unsigned int)foreground
           context:(CGContextRef _Nonnull)context
{
  CFStringRef string = (CFStringRef) nsstring;

  UniChar *unibuffer = NULL;
  UniCharCount unilength = (UniCharCount) CFStringGetLength(string);
  const UniChar *unichars = CFStringGetCharactersPtr(string);
  if (unichars == NULL) {
    unibuffer = malloc(unilength * sizeof(UniChar));
    CFStringGetCharacters(string, CFRangeMake(0, unilength), unibuffer);
    unichars = unibuffer;
  }

  CGGlyph *glyphs = malloc(unilength * sizeof(UniChar));
  CTFontRef fontWithTraits = [self fontWithTrait:fontTrait];

  CGContextSetRGBFillColor(context, RED(foreground), GREEN(foreground), BLUE(foreground), 1.0);
  recurseDraw(unichars, glyphs, positions, unilength, context, fontWithTraits, _fontLookupCache, YES);

  CFRelease(fontWithTraits);
  free(glyphs);
  if (unibuffer != NULL) {
    free(unibuffer);
  }
}

/**
 * The caller _must_ CFRelease the returned CTFont!
 */
- (CTFontRef)fontWithTrait:(FontTrait)fontTrait {
  if (fontTrait == FontTraitNone) {
    return CFRetain(_font);
  }

  CTFontSymbolicTraits traits = (CTFontSymbolicTraits) 0;
  if (fontTrait & FontTraitBold) {
    traits |= kCTFontBoldTrait;
  }

  if (fontTrait & FontTraitItalic) {
    traits |= kCTFontItalicTrait;
  }

  NSFont *cachedFont = _fontTraitCache[@(traits)];
  if (cachedFont != nil) {
    return CFRetain(cachedFont);
  }

  if (traits == 0) {
    return CFRetain(_font);
  }

  CTFontRef fontWithTraits = CTFontCreateCopyWithSymbolicTraits((CTFontRef) _font, 0.0, NULL, traits, traits);
  if (fontWithTraits == NULL) {
    return CFRetain(_font);
  }

  _fontTraitCache[@(traits)] = (NSFont *) fontWithTraits;

  return fontWithTraits;
}

@end
