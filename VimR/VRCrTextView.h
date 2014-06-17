/**
* Tae Won Ha — @hataewon
*
* http://taewon.de
* http://qvacua.com
*
* See LICENSE
*/

#import <Cocoa/Cocoa.h>


@protocol VRCrTextViewDelegate <NSObject>

@required
- (void)carriageReturnWithModifierFlags:(NSUInteger)modifierFlags;

@end


@interface VRCrTextView : NSTextView

@property (weak) id<VRCrTextViewDelegate> crDelegate;

- (void)keyDown:(NSEvent *)theEvent;

@end
