/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import "VRFileBrowserOutlineView.h"
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


BOOL IsPrintableAscii(unichar key) {
  return key >= 32 && key < 127;
}


@interface VRFileBrowserOutlineView ()

@property (readonly) BOOL lineEditing;
@property (readonly) NSString *lineEditingPrompt;

@end


@implementation VRFileBrowserOutlineView {
  NSString *_lineEditingString;
}

- (instancetype)initWithFrame:(NSRect)frameRect {
  if ((self = [super initWithFrame:frameRect])) {
    _lineEditingString = @"";
  }
  return self;
}

#pragma mark Line Editing

- (BOOL)lineEditing {
  switch (self.actionMode) {
    case VRFileBrowserActionModeSearch:
    case VRFileBrowserActionModeMenuAdd:
    case VRFileBrowserActionModeMenuMove:
    case VRFileBrowserActionModeMenuCopy:
      return YES;
    default:
      return NO;
  }
}

- (NSString *)lineEditingPrompt {
  switch (self.actionMode) {
    case VRFileBrowserActionModeSearch:
      return @"/";
    case VRFileBrowserActionModeMenuAdd:
      return @"Add node: ";
    case VRFileBrowserActionModeMenuMove:
      return @"Move to: ";
    case VRFileBrowserActionModeMenuCopy:
      return @"Copy to: ";
    default:
      return @"";
  }
}

- (void)updateLineEditingStatusMessage {
  [self.actionDelegate updateStatusMessage:[NSString stringWithFormat:@"%@%@", self.lineEditingPrompt, _lineEditingString]];
}

- (void)endLineEditing {
  VRFileBrowserActionMode _newMode = VRFileBrowserActionModeNormal;
  
  switch (_actionMode) {
    case VRFileBrowserActionModeSearch:
      [self.actionDelegate actionSearch:_lineEditingString];
      break;
    case VRFileBrowserActionModeMenuAdd:
      [self.actionDelegate actionAddPath:_lineEditingString];
      break;
    case VRFileBrowserActionModeMenuMove:
    case VRFileBrowserActionModeMenuCopy:
      if ([self.actionDelegate actionCheckClobberForPath:_lineEditingString]) {
        [self.actionDelegate updateStatusMessage:@"Overwrite existing file? (y)es (n)o"];
        _newMode = VRFileBrowserActionModeConfirmation;
      } else {
        _actionMode == VRFileBrowserActionModeMenuMove ?
        [self.actionDelegate actionMoveToPath:_lineEditingString] :
        [self.actionDelegate actionCopyToPath:_lineEditingString];
      }
      break;
    default:
      break;
  }
  
  _actionMode = _newMode;
}

#pragma mark NSResponder

- (void)keyDown:(NSEvent *)event {
  NSString *characters = [event charactersIgnoringModifiers];
  unichar key = 0;
  if (characters.length == 1) {
    key = [characters characterAtIndex:0];
  }
  
  if (self.actionMode != VRFileBrowserActionModeNormal && key == qEscCharacter) {
    [self.actionDelegate updateStatusMessage:@"Type <Esc> again to focus text"];
    _actionMode = VRFileBrowserActionModeNormal;
    return;
  }
  
  if (self.lineEditing) {
    switch (key) {
      case NSCarriageReturnCharacter:
        _lineEditingString = [_lineEditingString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if (_lineEditingString.length == 0) {
          [self.actionDelegate actionIgnore];
          [self updateLineEditingStatusMessage];
        } else {
          [self endLineEditing];
        }
        break;
      case NSDeleteCharacter:
        if (_lineEditingString.length > 0)
          _lineEditingString = [_lineEditingString substringToIndex:_lineEditingString.length-1];
        else {
          _lineEditingString = @"";
        }
        [self updateLineEditingStatusMessage];
        break;
      default:
        if (IsPrintableAscii(key)) {
          _lineEditingString = [_lineEditingString stringByAppendingString:[NSString stringWithCharacters:&key length:1]];
          [self updateLineEditingStatusMessage];
        } else {
          [self.actionDelegate actionIgnore];
        }
        break;
    }
  } else {
    if ([self processKey:key]) {
      if (self.lineEditing) {
        _lineEditingString = @"";
        [self updateLineEditingStatusMessage];
      }
    } else {
      [self.actionDelegate actionIgnore];
    }
  }
}

#pragma mark Key Processing

- (BOOL)processKey:(unichar)key {
  switch (self.actionMode) {
    case VRFileBrowserActionModeNormal:
      return [self processKeyModeNormal:key];
    case VRFileBrowserActionModeMenu:
      return [self processKeyModeMenu:key];
    case VRFileBrowserActionModeConfirmation:
      return [self processKeyModeConfirmation:key];
    default:
      return NO;
  }
}

- (BOOL)processKeyModeNormal:(unichar)key {
  [self.actionDelegate updateStatusMessage:@""];
  switch (key) {
    case 'h':
      [self.actionDelegate actionOpenDefault];
      return YES;
    case 'j':
      [self.actionDelegate actionMoveDown];
      return YES;
    case 'k':
      [self.actionDelegate actionMoveUp];
      return YES;
    case 'l':
      [self.actionDelegate actionOpenDefault];
      return YES;
    case ' ':
      [self.actionDelegate actionOpenDefault];
      return YES;
    case 'o':
      [self.actionDelegate actionOpenDefault];
      return YES;
    case 'O':
      [self.actionDelegate actionOpenDefaultAlt];
      return YES;
    case 's':
      [self.actionDelegate actionOpenInVerticalSplit];
      return YES;
    case 'i':
      [self.actionDelegate actionOpenInHorizontalSplit];
      return YES;
    case NSCarriageReturnCharacter:
      [self.actionDelegate actionOpenDefault];
      return YES;
    case qEscCharacter:
      [self.actionDelegate actionFocusVimView];
      return YES;
    case '/':
      _actionMode = VRFileBrowserActionModeSearch;
      return YES;
    case 'm':
      _actionMode = VRFileBrowserActionModeMenu;
      [self.actionDelegate updateStatusMessage:@"Actions: (a)dd (m)ove (d)elete (c)opy"];
      return YES;
    default:
      return NO;
  }
}

- (BOOL)processKeyModeMenu:(unichar)key {
  switch (key) {
    case 'a':
      _actionMode = VRFileBrowserActionModeMenuAdd;
      _actionSubMode = VRFileBrowserActionModeMenuAdd;
      return YES;
    case 'm':
      _actionMode = VRFileBrowserActionModeMenuMove;
      _actionSubMode = VRFileBrowserActionModeMenuMove;
      return YES;
    case 'd':
      _actionMode = VRFileBrowserActionModeConfirmation;
      _actionSubMode = VRFileBrowserActionModeMenuDelete;
      [self.actionDelegate updateStatusMessage:@"Delete? (y)es (n)o"];
      return YES;
    case 'c':
      _actionMode = VRFileBrowserActionModeMenuCopy;
      _actionSubMode = VRFileBrowserActionModeMenuCopy;
      return YES;
    default:
      return NO;
  }
}

- (BOOL)processKeyModeConfirmation:(unichar)key {
  switch (key) {
    case 'y':
      [self.actionDelegate updateStatusMessage:@""];
      switch (_actionSubMode) {
        case VRFileBrowserActionModeMenuMove:
          [self.actionDelegate actionMoveToPath:_lineEditingString];
          break;
        case VRFileBrowserActionModeMenuDelete:
          [self.actionDelegate actionDelete];
          break;
        case VRFileBrowserActionModeMenuCopy:
          [self.actionDelegate actionCopyToPath:_lineEditingString];
        default:
          break;
      }
      _actionMode = VRFileBrowserActionModeNormal;
      return YES;
    case 'n':
      switch (_actionSubMode) {
        case VRFileBrowserActionModeMenuMove:
        case VRFileBrowserActionModeMenuCopy:
          _actionMode = _actionSubMode;
          [self updateLineEditingStatusMessage];
          break;
        default:
          [self.actionDelegate updateStatusMessage:@""];
          _actionMode = VRFileBrowserActionModeNormal;
          break;
      }
      return YES;
    default:
      return NO;
  }
}

- (VRNode *)selectedItem {
  NSInteger selectedRow = self.selectedRow;
  if (selectedRow < 0) { return nil; }

  return [self itemAtRow:selectedRow];
}

@end
