/**
* Tae Won Ha — @hataewon
*
* http://taewon.de
* http://qvacua.com
*
* See LICENSE
*/

#import "VRCrTextView.h"


@implementation VRCrTextView

- (void)keyDown:(NSEvent *)theEvent {
  if ([theEvent.charactersIgnoringModifiers characterAtIndex:0] == NSCarriageReturnCharacter) {
    [_crDelegate carriageReturnWithModifierFlags:theEvent.modifierFlags];
    return;
  }

  [super keyDown:theEvent];
}

@end
