/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import "VRFileBrowserOutlineView.h"
#import "NSTableView+VR.h"
#import "VRMainWindowController.h"

static const int qEscCharacter = '\033';


@implementation VRNode

- (NSString *)description {
  NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
  [description appendFormat:@"self.url=%@", self.url];
  [description appendFormat:@", self.name=%@", self.name];
  [description appendFormat:@", self.children=%@", self.children];
  [description appendFormat:@", self.dir=%d", self.dir];
  [description appendFormat:@", self.hidden=%d", self.hidden];
  [description appendFormat:@", self.item=%@", self.item];
  [description appendString:@">"];
  return description;
}

@end


@implementation VRFileBrowserOutlineView

- (void)keyDown:(NSEvent *)theEvent {
  NSString *characters = [theEvent charactersIgnoringModifiers];
  if (characters.length != 1) {
    [super keyDown:theEvent];
    return;
  }

  unichar key = [characters characterAtIndex:0];
  switch (key) {
    case 'h':
      [self viMotionLeft:self event:theEvent];
      return;
    case 'j':
      [self viMotionDown:self event:theEvent];
      return;
    case 'k':
      [self viMotionUp:self event:theEvent];
      return;
    case 'l':
      [self viMotionRight:self event:theEvent];
      return;
    case ' ':
      [self actionSpace:self event:theEvent];
      return;
    case 'o':
      [self actionOpenInNewTab:self event:theEvent];
      return;
    case 'O':
      [self actionOpenInCurrentTab:self event:theEvent];
      return;
    case 's':
      [self actionOpenInVerticalSplit:self event:theEvent];
      return;
    case 'i':
      [self actionOpenInHorizontalSplit:self event:theEvent];
      return;
    case NSCarriageReturnCharacter:
      [self actionCarriageReturn:self event:theEvent];
      return;
    case qEscCharacter:
      [self actionEscape:self event:theEvent];
      return;
    default:
      [super keyDown:theEvent];
  }
}

- (VRNode *)selectedItem {
  NSInteger selectedRow = self.selectedRow;
  if (selectedRow < 0) { return nil; }

  return [self itemAtRow:selectedRow];
}

#pragma mark Actions
- (void)viMotionLeft:(id)sender event:(NSEvent *)event {
  [self performDoubleAction];
}

- (void)viMotionUp:(id)sender event:(NSEvent *)event {
  [self moveSelectionByDelta:-1];
}

- (void)viMotionDown:(id)sender event:(NSEvent *)event {
  [self moveSelectionByDelta:1];
}

- (void)viMotionRight:(id)sender event:(NSEvent *)event {
  [self performDoubleAction];
}

- (void)actionSpace:(id)sender event:(NSEvent *)event {
  [self performDoubleAction];
}

- (void)actionCarriageReturn:(id)sender event:(NSEvent *)event {
  [self performDoubleAction];
}

- (void)actionEscape:(id)sender event:(NSEvent *)event {
  [self.window makeFirstResponder:[self.window.windowController vimView].textView];
}

- (void)actionOpenInNewTab:(id)sender event:(NSEvent *)event {
  [self openInMode:VROpenModeInNewTab];
}

- (void)actionOpenInCurrentTab:(id)sender event:(NSEvent *)event {
  [self openInMode:VROpenModeInCurrentTab];
}

- (void)actionOpenInVerticalSplit:(id)sender event:(NSEvent *)event {
  [self openInMode:VROpenModeInVerticalSplit];
}

- (void)actionOpenInHorizontalSplit:(id)sender event:(NSEvent *)event {
  [self openInMode:VROpenModeInHorizontalSplit];
}

- (void)performDoubleAction {
  [self sendAction:self.doubleAction to:self.target];
}

- (void)openInMode:(VROpenMode)mode {
  VRNode *selectedItem = [self selectedItem];
  if (!selectedItem) {return;}
  
  if (!selectedItem.dir) {
    [(VRMainWindowController *) self.window.windowController openFileWithUrls:selectedItem.url openMode:mode];
    return;
  }
  
  if ([self isItemExpanded:selectedItem]) {
    [self collapseItem:selectedItem];
  } else {
    [self expandItem:selectedItem];
  }
}

@end
