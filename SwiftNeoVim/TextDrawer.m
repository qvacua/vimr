/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 *
 * Almost a verbatim copy from MacVim by Bjorn Winckler
 * See VIM.LICENSE
 */

#import "TextDrawer.h"
#import "MMCoreTextView.h"

#define ALPHA(color_code)    (((color_code >> 24) & 0xff) / 255.0f)
#define RED(color_code)      (((color_code >> 16) & 0xff) / 255.0f)
#define GREEN(color_code)    (((color_code >>  8) & 0xff) / 255.0f)
#define BLUE(color_code)     (((color_code      ) & 0xff) / 255.0f)

static dispatch_once_t token;
static NSMutableDictionary *colorCache;

static CGColorRef color_for(unsigned int value) {
  NSColor *color = colorCache[@(value)];
  if (color == nil) {
    color = [NSColor colorWithSRGBRed:RED(value) green:GREEN(value) blue:BLUE(value) alpha:1];
    colorCache[@(value)] = color;
  }

  return color.CGColor;
}

@implementation TextDrawer {
  NSLayoutManager *_layoutManager;

  NSFont *_font;
  CGFloat _ascent;
  CGFloat _underlinePosition;
  CGFloat _underlineThickness;
  CGFloat _linespacing;

  NSMutableArray *_fontLookupCache;
  NSMutableDictionary *_fontTraitCache;
}

- (CGFloat)baselineOffset {
  return _cellSize.height - _ascent;
}

- (void)setLinespacing:(CGFloat)linespacing {
  // FIXME: reasonable min and max
  _linespacing = linespacing;
  _cellSize = [self cellSizeWithFont:_font linespacing:_linespacing];
}

- (void)setFont:(NSFont *)font {
  [_font autorelease];

  _font = [font retain];
  [_fontTraitCache removeAllObjects];
  [_fontLookupCache removeAllObjects];

  _cellSize = [self cellSizeWithFont:font linespacing:_linespacing];

  _ascent = CTFontGetAscent((CTFontRef) _font);
  _leading = CTFontGetLeading((CTFontRef) _font);
  _descent = CTFontGetDescent((CTFontRef) _font);
  _underlinePosition = CTFontGetUnderlinePosition((CTFontRef) _font); // This seems to take the thickness into account
  // TODO: Maybe we should use 0.5 or 1 as minimum thickness for Retina and non-Retina, respectively.
  _underlineThickness = CTFontGetUnderlineThickness((CTFontRef) _font);
}

- (instancetype _Nonnull)initWithFont:(NSFont *_Nonnull)font {
  dispatch_once (&token, ^{
    colorCache = [[NSMutableDictionary alloc] init];
  });

  self = [super init];
  if (self == nil) {
    return nil;
  }

  _usesLigatures = NO;
  _linespacing = 1;

  _layoutManager = [[NSLayoutManager alloc] init];
  _fontLookupCache = [[NSMutableArray alloc] init];
  _fontTraitCache = [[NSMutableDictionary alloc] init];

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
    [self drawUnderline:positions count:positionsCount color:attrs.foreground context:context];
  }

  [self drawString:string positions:positions
         fontTrait:attrs.fontTrait foreground:attrs.foreground
           context:context];

  CGContextRestoreGState(context);
}

- (void)drawUnderline:(const CGPoint *_Nonnull)positions
                count:(NSInteger)count
                color:(unsigned int)color
              context:(CGContextRef _Nonnull)context
{
  CGContextSetFillColorWithColor(context, color_for(color));
  CGRect rect = {
      {positions[0].x, positions[0].y + _underlinePosition},
      {positions[0].x + positions[count - 1].x + _cellSize.width, _underlineThickness}
  };
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

  CGGlyph *glyphs = malloc(unilength * sizeof(CGGlyph));
  CTFontRef fontWithTraits = [self fontWithTrait:fontTrait];

  CGContextSetFillColorWithColor(context, color_for(foreground));
  recurseDraw(unichars, glyphs, positions, unilength, context, fontWithTraits, _fontLookupCache, _usesLigatures);

  CFRelease(fontWithTraits);
  free(glyphs);
  if (unibuffer != NULL) {
    free(unibuffer);
  }
}

- (CGSize)cellSizeWithFont:(NSFont *)font linespacing:(CGFloat)linespacing {
  // cf. https://developer.apple.com/library/mac/documentation/TextFonts/Conceptual/CocoaTextArchitecture/FontHandling/FontHandling.html
  CGFloat ascent = CTFontGetAscent((CTFontRef) _font);
  CGFloat descent = CTFontGetDescent((CTFontRef) _font);
  CGFloat leading = CTFontGetLeading((CTFontRef) _font);

  CGSize result = CGSizeMake(
      round([@"m" sizeWithAttributes:@{ NSFontAttributeName : _font }].width),
      ceil(linespacing * (ascent + descent + leading))
  );

  return result;
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

  if (traits == 0) {
    return CFRetain(_font);
  }

  NSFont *cachedFont = _fontTraitCache[@(traits)];
  if (cachedFont != nil) {
    return CFRetain(cachedFont);
  }

  CTFontRef fontWithTraits = CTFontCreateCopyWithSymbolicTraits((CTFontRef) _font, 0.0, NULL, traits, traits);
  if (fontWithTraits == NULL) {
    return CFRetain(_font);
  }

  _fontTraitCache[@(traits)] = (NSFont *) fontWithTraits;

  return fontWithTraits;
}

@end
