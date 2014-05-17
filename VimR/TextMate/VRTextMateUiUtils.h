/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import <Cocoa/Cocoa.h>


/**
* Frameworks/OakAppKit/src/OakUIConstructionFunctions.mm
* v2.0-alpha.9537
*/
@interface OakDividerLineView : NSBox

@property (nonatomic) NSColor *primaryColor;
@property (nonatomic) NSColor *secondaryColor;
@property (nonatomic) BOOL usePrimaryColor;
@property (nonatomic) NSSize intrinsicContentSize;

@end


extern OakDividerLineView *OakCreateDividerLineWithColor(NSColor *color, NSColor *secondaryColor);
extern NSBox *OakCreateVerticalLine(NSColor *primaryColor, NSColor *secondaryColor);

