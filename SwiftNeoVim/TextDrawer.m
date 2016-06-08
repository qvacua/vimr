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

@implementation TextDrawer {
  NSMutableArray *fontCache;
}

- (instancetype)init {
  self = [super init];
  if (self == nil) {
    return nil;
  }

  fontCache = [[NSMutableArray alloc] initWithCapacity:4];

  return self;
}

- (void)dealloc {
  [fontCache release];

  [super dealloc];
}

/**
 * We assume that the caller has already called
 *
 * CGContextSetTextMatrix(context, CGAffineTransformIdentity); // or some other matrix
 * CGContextSetTextDrawingMode(context, kCGTextFill); // or some other mode
 */
- (void)drawString:(NSString *_Nonnull)theString
         positions:(CGPoint *_Nonnull)positions
              font:(NSFont *_Nonnull)theFont
        foreground:(int)foreground
        background:(int)background
           context:(CGContextRef _Nonnull)context
{
  CFStringRef string = (CFStringRef) theString;
  CTFontRef font = (CTFontRef) theFont;

  UniChar *unibuffer = NULL;
  UniCharCount unilength = (UniCharCount) CFStringGetLength(string);
  const UniChar *unichars = CFStringGetCharactersPtr(string);
  if (unichars == NULL) {
    unibuffer = malloc(unilength * sizeof(UniChar));
    CFStringGetCharacters(string, CFRangeMake(0, unilength), unibuffer);
    unichars = unibuffer;
  }

  CGGlyph *glyphs = malloc(unilength * sizeof(UniChar));

  recurseDraw(unichars, glyphs, positions, unilength, context, font, fontCache, YES);

  if (unibuffer != NULL) {
    free(unibuffer);
  }

  free(glyphs);
}

@end
