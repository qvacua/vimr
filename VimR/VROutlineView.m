/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import "VROutlineView.h"


static const int qEscCharacter = '\033';


@implementation VROutlineView

- (void)keyDown:(NSEvent *)theEvent {
  NSString *characters = [theEvent charactersIgnoringModifiers];
  if (characters.length != 1) {
    [super keyDown:theEvent];
    return;
  }

  unichar key = [characters characterAtIndex:0];
  switch (key) {
    case 'h':
      [_movementsAndActionDelegate viMotionLeft:self event:theEvent];
      return;
    case 'j':
      [_movementsAndActionDelegate viMotionDown:self event:theEvent];
      return;
    case 'k':
      [_movementsAndActionDelegate viMotionUp:self event:theEvent];
      return;
    case 'l':
      [_movementsAndActionDelegate viMotionRight:self event:theEvent];
      return;
    case ' ':
      [_movementsAndActionDelegate actionSpace:self event:theEvent];
      return;
    case NSCarriageReturnCharacter:
      [_movementsAndActionDelegate actionCarriageReturn:self event:theEvent];
      return;
    case qEscCharacter:
      [_movementsAndActionDelegate actionEscape:self event:theEvent];
      return;
    default:
      [super keyDown:theEvent];
  }
}

- (id)selectedItem {
  NSInteger selectedRow = self.selectedRow;
  if (selectedRow < 0) { return nil; }

  return [self itemAtRow:selectedRow];
}

@end
