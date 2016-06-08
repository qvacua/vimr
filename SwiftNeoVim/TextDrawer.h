/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

@import Cocoa;
@import CoreText;

@interface TextDrawer : NSObject

- (void)drawString:(NSString *_Nonnull)theString
         positions:(CGPoint *_Nonnull)positions
              font:(NSFont *_Nonnull)font
        foreground:(int)foreground
        background:(int)background
           context:(CGContextRef _Nonnull)context;

@end
