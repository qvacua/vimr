/**
* Tae Won Ha — @hataewon
*
* http://taewon.de
* http://qvacua.com
*
* See LICENSE
*/

#import "VRFileBrowserOutlineView.h"
#import "VRUtils.h"


static const unichar cZero = '\0'; // marks an 'undefined last key'
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


static inline BOOL IsPrintableAscii(unichar key) {
  return key >= 32 && key < 127;
}


@implementation VRFileBrowserOutlineView {
  NSString *_lineEditingString;
  NSString *_lastSearch;
  unichar _lastKey;
}

#pragma mark NSView
- (instancetype)initWithFrame:(NSRect)frameRect {
  self = [super initWithFrame:frameRect];
  RETURN_NIL_WHEN_NOT_SELF

  _lineEditingString = @"";
  _lastKey = cZero;

  return self;
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
          _lineEditingString = [_lineEditingString substringToIndex:_lineEditingString.length - 1];
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

  // So we are done processing the keyDown event and performed our actions.
  // We now remember the last key (useful for the 'gg' movement to the top of
  // the view.
  _lastKey = key;
}

- (BOOL)resignFirstResponder {
  BOOL resign = [super resignFirstResponder];

  if (resign) {
    [self actionReset];
  }

  return resign;
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
    case NSLeftArrowFunctionKey:
    case 'h':
      [self.actionDelegate actionOpenDefault];
      return YES;
    case NSDownArrowFunctionKey:
    case 'j':
      [self.actionDelegate actionMoveDown];
      return YES;
    case NSUpArrowFunctionKey:
    case 'k':
      [self.actionDelegate actionMoveUp];
      return YES;
    case NSRightArrowFunctionKey:
    case 'l':
      [self.actionDelegate actionOpenDefault];
      return YES;
    case ' ':
      [self.actionDelegate actionOpenDefault];
      return YES;
    case 'o':
      [self.actionDelegate actionOpenDefault];
      return YES;
    case 't':
      if ([self.actionDelegate actionNodeIsDirectory]) {
        return NO;
      } else {
        [self.actionDelegate actionOpenInNewTab];
        return YES;
      }
    case 's':
      if ([self.actionDelegate actionNodeIsDirectory]) {
        return NO;
      } else {
        [self.actionDelegate actionOpenInVerticalSplit];
        return YES;
      }
    case 'i':
      if ([self.actionDelegate actionNodeIsDirectory]) {
        return NO;
      } else {
        [self.actionDelegate actionOpenInHorizontalSplit];
        return YES;
      }
    case NSCarriageReturnCharacter:
      [self.actionDelegate actionOpenDefault];
      return YES;
    case qEscCharacter:
      [self.actionDelegate actionFocusVimView];
      return YES;
    case 'n':
    case 'N':
      if (_lastSearch == nil) {
        return NO;
      }
      key == 'n' ? [self.actionDelegate actionSearch:_lastSearch] : [self.actionDelegate actionReverseSearch:_lastSearch];
      return YES;
    case '/':
      _actionMode = VRFileBrowserActionModeSearch;
      return YES;
    case 'm':
      _actionMode = VRFileBrowserActionModeMenu;
      [self.actionDelegate updateStatusMessage:@"Actions: (a)dd (m)ove (d)elete (c)opy"];
      return YES;
    case 'g':
      if (_lastKey == 'g') {
        _lastKey = cZero;
        [self.actionDelegate actionMoveToTop];
      }
      return YES;
    case 'G':
      [self.actionDelegate actionMoveToBottom];
      return YES;
    default:
      return NO;
  }
}

- (BOOL)processKeyModeMenu:(unichar)key {
  if (![self.actionDelegate actionCanActOnNode] && key != 'a') {
    [self actionReset];
    return NO;
  }

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

#pragma mark Public
- (VRNode *)selectedItem {
  NSInteger selectedRow = self.selectedRow;
  if (selectedRow < 0) {return nil;}

  return [self itemAtRow:selectedRow];
}

- (void)actionReset {
  _actionMode = VRFileBrowserActionModeNormal;
  [self.actionDelegate updateStatusMessage:@""];
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


#pragma mark Private
- (void)updateLineEditingStatusMessage {
  [self.actionDelegate updateStatusMessage:SF(@"%@%@", self.lineEditingPrompt, _lineEditingString)];
}

- (void)endLineEditing {
  VRFileBrowserActionMode newMode = VRFileBrowserActionModeNormal;
  [self.actionDelegate updateStatusMessage:@""];

  switch (_actionMode) {
    case VRFileBrowserActionModeSearch:
      _lastSearch = _lineEditingString;
      [self.actionDelegate actionSearch:_lineEditingString];
      break;
    case VRFileBrowserActionModeMenuAdd:
      [self.actionDelegate actionAddPath:_lineEditingString];
      break;
    case VRFileBrowserActionModeMenuMove:
    case VRFileBrowserActionModeMenuCopy:
      if ([self.actionDelegate actionCheckClobberForPath:_lineEditingString]) {
        [self.actionDelegate updateStatusMessage:@"Overwrite existing file? (y)es (n)o"];
        newMode = VRFileBrowserActionModeConfirmation;
      } else {
        _actionMode == VRFileBrowserActionModeMenuMove ?
            [self.actionDelegate actionMoveToPath:_lineEditingString] :
            [self.actionDelegate actionCopyToPath:_lineEditingString];
      }
      break;
    default:
      break;
  }

  _actionMode = newMode;
}

@end
