/**
* Tae Won Ha — @hataewon
*
* http://taewon.de
* http://qvacua.com
*
* See LICENSE
*/

#import <MacVimFramework/MacVimFramework.h>
#import <CocoaLumberjack/DDLog.h>
#import "VRWorkspaceView.h"
#import "VRTextMateUiUtils.h"
#import "VRFileBrowserView.h"
#import "VRMainWindowController.h"
#import "VRDefaultLogSetting.h"
#import "VRUtils.h"


#define SQ(x) ((x)*(x))
#define CONSTRAINT(str, ...) [_myConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat: str, ##__VA_ARGS__] options:0 metrics:nil views:views]]


static const int qDefaultFileBrowserWidth = 175;
static const int qMinimumFileBrowserWidth = 100;


/**
* Copied and modified from TextMate -Tae
*
* Frameworks/DocumentWindow/src/ProjectLayoutView.mm
* v2.0-alpha.9537
*/
@implementation VRWorkspaceView {
  NSLayoutConstraint *_fileBrowserWidthConstraint;
  NSLayoutConstraint *_vimViewWidthConstraint;
  NSLayoutConstraint *_vimViewHeightConstraint;
  NSMutableArray *_myConstraints;

  NSUInteger _dragIncrement;
  BOOL _mouseDownRecursionGuard;

  NSView *_fileBrowserDivider;

  NSPathControl *_pathControl;
  NSPopUpButton *_settingsButton;
}

#pragma mark Properties
- (void)setShowStatusBar:(BOOL)showStatusBar {
  _showStatusBar = showStatusBar;
  self.needsUpdateConstraints = YES;
}

- (void)setVimView:(MMVimView *)aVimView {
  _vimView = [self replaceView:_vimView withView:aVimView];
  [self updateMetrics];
}

- (void)setFileBrowserView:(VRFileBrowserView *)aFileBrowserView {
  NSBox *dividerView = aFileBrowserView ? OakCreateVerticalLine([NSColor controlShadowColor], nil) : nil;

  _fileBrowserDivider = [self replaceView:_fileBrowserDivider withView:dividerView];
  _fileBrowserView = [self replaceView:_fileBrowserView withView:aFileBrowserView];
}

- (CGFloat)sidebarAndDividerWidth {
  if (_fileBrowserView) {
    return _fileBrowserWidth + 1;
  }

  return 0;
}

- (CGFloat)defaultFileBrowserAndDividerWidth {
  return qDefaultFileBrowserWidth + 1;
}

- (void)updateMetrics {
  _dragIncrement = (NSUInteger) _vimView.textView.cellSize.width;
}

- (void)setFileBrowserOnRight:(BOOL)flag {
  if (_fileBrowserOnRight != flag) {
    _fileBrowserOnRight = flag;

    if (_fileBrowserView) {
      self.needsUpdateConstraints = YES;
    }
  }
}

#pragma mark IBActions
- (IBAction)toggleSyncWorkspaceWithPwd:(NSMenuItem *)sender {
  _syncWorkspaceWithPwd = !_syncWorkspaceWithPwd;
  [_fileBrowserView reload];
}

- (IBAction)toggleShowFoldersFirst:(NSMenuItem *)sender {
  _showFoldersFirst = !_showFoldersFirst;
  [_fileBrowserView reload];
}

- (IBAction)toggleShowHiddenFiles:(NSMenuItem *)sender {
  _showHiddenFiles = !_showHiddenFiles;
  [_fileBrowserView reload];
}

- (IBAction)toggleStatusBar:(NSMenuItem *)sender {
  _showStatusBar = !_showStatusBar;
  self.needsUpdateConstraints = YES;
}

#pragma mark Public
- (void)setUrlOfPathControl:(NSURL *)url {
  _pathControl.URL = url;
}

#pragma mark NSUserInterfaceValidations
- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem {
  SEL action = anItem.action;

  if (action == @selector(toggleStatusBar:)) {
    if (_showStatusBar) {
      [(NSMenuItem *) anItem setTitle:@"Hide Status Bar"];
    } else {
      [(NSMenuItem *) anItem setTitle:@"Show Status Bar"];
    }

    return YES;
  }

  if (action == @selector(toggleShowFoldersFirst:)
      || action == @selector(toggleShowHiddenFiles:)
      || action == @selector(toggleSyncWorkspaceWithPwd:)) {

    // TODO: there must be a better way to do this...
    [self setStateOfFileBrowserFlagsForMenuItem:anItem];

    return _fileBrowserView != nil;
  }

  return NO;
}

- (void)setStateOfFileBrowserFlagsForMenuItem:(NSMenuItem *)item {
  SEL action = item.action;

  if (action == @selector(toggleShowFoldersFirst:)) {
    item.state = _showFoldersFirst;
    return;
  }

  if (action == @selector(toggleShowHiddenFiles:)) {
    item.state = _showHiddenFiles;
    return;
  }

  if (action == @selector(toggleSyncWorkspaceWithPwd:)) {
    item.state = _syncWorkspaceWithPwd;
    return;
  }
}

#pragma mark NSView
- (id)initWithFrame:(NSRect)aRect {
  self = [super initWithFrame:aRect];
  RETURN_NIL_WHEN_NOT_SELF

  _myConstraints = [NSMutableArray array];
  _fileBrowserWidth = qDefaultFileBrowserWidth;
  _dragIncrement = 1;

  return self;
}

- (void)updateConstraints {
  [self removeConstraints:_myConstraints];
  [_myConstraints removeAllObjects];
  [super updateConstraints];

  NSDictionary *views = @{
      @"fileBrowserView" : _fileBrowserView ?: [NSNull null],
      @"settings" : _settingsButton,
      @"fileBrowserDivider" : _fileBrowserDivider ?: [NSNull null],

      @"documentView" : _vimView,
      @"pathControl" : _pathControl,
  };

  if (!_pathControl.superview) {[self addSubview:_pathControl];}
  if (!_settingsButton.superview) {[self addSubview:_settingsButton];}
  if (!_showStatusBar) {
    [_pathControl removeFromSuperview];
    [_settingsButton removeFromSuperview];
  }
  if (!_fileBrowserView) {[_settingsButton removeFromSuperview];}

  [self addVimViewMinSizeConstraints];
  if (_fileBrowserView) {[self addFileBrowserWidthConstraint];}

  if (_fileBrowserView) {
    CONSTRAINT(@"V:|[fileBrowserDivider]|");

    if (_fileBrowserOnRight) {
      CONSTRAINT(@"H:|[documentView][fileBrowserDivider][fileBrowserView]|");
    } else {
      CONSTRAINT(@"H:|[fileBrowserView][fileBrowserDivider][documentView]|");
    }
  } else {
    CONSTRAINT(@"H:|[documentView]|");
  }

  if (_showStatusBar) {
    CONSTRAINT(@"V:|[documentView]-(%d)-|", qMainWindowBorderThickness + 1);
    CONSTRAINT(@"V:[pathControl]-(1)-|");

    if (_fileBrowserView) {
      CONSTRAINT(@"V:[settings]-(3)-|");
      CONSTRAINT(@"V:|[fileBrowserView(>=100)]-(%d)-|", qMainWindowBorderThickness + 1);

      if (_fileBrowserOnRight) {
        CONSTRAINT(@"H:[fileBrowserDivider][settings]");
        CONSTRAINT(@"H:|-(2)-[pathControl]-(2)-[fileBrowserDivider]");
      } else {
        CONSTRAINT(@"H:[settings][fileBrowserDivider]");
        CONSTRAINT(@"H:[fileBrowserDivider]-(2)-[pathControl]-(2)-|");
      }
    } else {
      CONSTRAINT(@"H:|-(2)-[pathControl]-(2)-|");
    }
  } else {
    CONSTRAINT(@"V:|[documentView]|");

    if (_fileBrowserView) {
      CONSTRAINT(@"V:|[fileBrowserView(>=100)]|");
    } else {
      CONSTRAINT(@"H:|[documentView]|");
    }
  }

  [self addConstraints:_myConstraints];
  [self.window invalidateCursorRectsForView:self];
}

- (void)addFileBrowserWidthConstraint {
  _fileBrowserWidth -= (NSUInteger) _fileBrowserWidthConstraint.constant % _dragIncrement;
  _fileBrowserWidthConstraint = [NSLayoutConstraint constraintWithItem:_fileBrowserView
                                                             attribute:NSLayoutAttributeWidth
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:nil
                                                             attribute:NSLayoutAttributeNotAnAttribute
                                                            multiplier:1
                                                              constant:_fileBrowserWidth];
  _fileBrowserWidthConstraint.priority = NSLayoutPriorityDragThatCannotResizeWindow;
  [_myConstraints addObject:_fileBrowserWidthConstraint];
}

- (void)resetCursorRects {
  [self addCursorRect:self.fileBrowserResizeRect cursor:[NSCursor resizeLeftRightCursor]];
}

- (NSView *)hitTest:(NSPoint)aPoint {
  if (NSMouseInRect([self convertPoint:aPoint fromView:self.superview], self.fileBrowserResizeRect, self.isFlipped)) {
    return self;
  }

  return [super hitTest:aPoint];
}

- (void)mouseDown:(NSEvent *)anEvent {
  if (_mouseDownRecursionGuard) {
    return;
  }

  _mouseDownRecursionGuard = YES;

  NSView *view = nil;
  NSPoint mouseDownPos = [self convertPoint:anEvent.locationInWindow fromView:nil];
  if (NSMouseInRect(mouseDownPos, self.fileBrowserResizeRect, self.isFlipped)) {
    view = _fileBrowserView;
  }

  if (!view || anEvent.type != NSLeftMouseDown) {
    DDLogDebug(@"view: %@", view);
    [super mouseDown:anEvent];
  } else {
    if (_fileBrowserView) {
      _fileBrowserWidthConstraint.constant = NSWidth(_fileBrowserView.frame);
      _fileBrowserWidthConstraint.priority = NSLayoutPriorityDragThatCannotResizeWindow;
    }

    NSEvent *mouseDownEvent = anEvent;
    CGRect initialFrame = view.frame;

    VRMainWindowController *windowController = (VRMainWindowController *) self.window.windowController;
    DDLogDebug(@"turning on live resize flag");
    DDLogDebug(@"drag increment: %lu\tcell width: %f", _dragIncrement, _vimView.textView.cellSize.width);
    [windowController.vimView viewWillStartLiveResize];

    DDLogDebug(@"before: %f = %f + 1 + %f", self.frame.size.width, _fileBrowserWidth, _vimView.frame.size.width);

    BOOL didDrag = NO;
    while (anEvent.type != NSLeftMouseUp) {
      anEvent = [NSApp nextEventMatchingMask:(NSLeftMouseDraggedMask | NSLeftMouseDown | NSLeftMouseUpMask)
                                   untilDate:[NSDate distantFuture] inMode:NSEventTrackingRunLoopMode dequeue:YES];
      if (anEvent.type != NSLeftMouseDragged) {
        break;
      }

      CGPoint mouseCurrentPos = [self convertPoint:anEvent.locationInWindow fromView:nil];
      if (!didDrag &&
              SQ(fabs(mouseDownPos.x - mouseCurrentPos.x)) + SQ(fabs(mouseDownPos.y - mouseCurrentPos.y)) < SQ(1)) {

        continue; // we didn't even drag a pixel
      }

      if (view == _fileBrowserView) {
        CGFloat width = NSWidth(initialFrame) + (mouseCurrentPos.x - mouseDownPos.x) * (_fileBrowserOnRight ? -1 : +1);
        _fileBrowserWidth = [self adjustedFileBrowserWidthForWidth:width];

        _fileBrowserWidthConstraint.constant = _fileBrowserWidth;
        _fileBrowserWidthConstraint.priority = NSLayoutPriorityDragThatCannotResizeWindow - 1;
      }

      [self.window invalidateCursorRectsForView:self];
      didDrag = YES;
    }

    [windowController.vimView viewDidEndLiveResize];

    if (!didDrag) {
      NSView *hitView = [super hitTest:[self.superview convertPoint:[mouseDownEvent locationInWindow] fromView:nil]];
      if (hitView && hitView != self) {
        [NSApp postEvent:anEvent atStart:NO];
        [hitView mouseDown:mouseDownEvent];
      }
    }

    _fileBrowserWidthConstraint.priority = NSLayoutPriorityDragThatCannotResizeWindow;
  }

  _mouseDownRecursionGuard = NO;
}

#pragma mark Private

- (CGFloat)adjustedFileBrowserWidthForWidth:(CGFloat)width {
  NSUInteger targetWidth = (NSUInteger) MAX(qMinimumFileBrowserWidth, round(width));

  CGFloat totalWidth = self.frame.size.width;
  CGFloat insetOfVimView = _vimView.totalHorizontalInset;

  // 1 is the width of the divider
  double targetVimViewWidth = _dragIncrement * ceil((totalWidth - targetWidth - 1 - insetOfVimView) / _dragIncrement)
      + insetOfVimView;

  return totalWidth - targetVimViewWidth - 1;
}

- (id)replaceView:(NSView *)oldView withView:(NSView *)newView {
  if (newView == oldView) {
    return oldView;
  }

  [oldView removeFromSuperview];

  if (newView) {
    newView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:newView];
  }

  self.needsUpdateConstraints = YES;
  return newView;
}

- (void)addVimViewMinSizeConstraints {
  _vimViewWidthConstraint = [NSLayoutConstraint constraintWithItem:_vimView
                                                         attribute:NSLayoutAttributeWidth
                                                         relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                            toItem:nil
                                                         attribute:NSLayoutAttributeNotAnAttribute
                                                        multiplier:1
                                                          constant:_vimView.minSize.width];
  _vimViewHeightConstraint = [NSLayoutConstraint constraintWithItem:_vimView
                                                          attribute:NSLayoutAttributeHeight
                                                          relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                             toItem:nil
                                                          attribute:NSLayoutAttributeNotAnAttribute
                                                         multiplier:1
                                                           constant:_vimView.minSize.height];
  [_myConstraints addObject:_vimViewWidthConstraint];
  [_myConstraints addObject:_vimViewHeightConstraint];
}

- (CGRect)fileBrowserResizeRect {
  if (!_fileBrowserView) {
    return CGRectZero;
  }

  CGRect r = _fileBrowserView.frame;
  return CGRectMake(_fileBrowserOnRight ? NSMinX(r) - 3 : NSMaxX(r) - 4, NSMinY(r), 10, NSHeight(r));
}

- (void)setUp {
  _pathControl = [[NSPathControl alloc] initWithFrame:CGRectZero];
  _pathControl.translatesAutoresizingMaskIntoConstraints = NO;
  _pathControl.pathStyle = NSPathStyleStandard;
  _pathControl.backgroundColor = [NSColor clearColor];
  _pathControl.refusesFirstResponder = YES;
  [_pathControl.cell setControlSize:NSSmallControlSize];
  [_pathControl.cell setFont:[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSSmallControlSize]]];
  [_pathControl setContentCompressionResistancePriority:NSLayoutPriorityDefaultLow
                                         forOrientation:NSLayoutConstraintOrientationHorizontal];

  [self addSubview:_pathControl];

  _settingsButton = [[NSPopUpButton alloc] initWithFrame:CGRectZero pullsDown:YES];
  _settingsButton.bordered = NO;
  _settingsButton.translatesAutoresizingMaskIntoConstraints = NO;
  [self addSubview:_settingsButton];

  NSMenuItem *item = [NSMenuItem new];
  item.title = @"";
  item.image = [NSImage imageNamed:NSImageNameActionTemplate];
  [item.image setSize:NSMakeSize(12, 12)];

  [_settingsButton.cell setBackgroundStyle:NSBackgroundStyleRaised];
  [_settingsButton.cell setUsesItemFromMenu:NO];
  [_settingsButton.cell setMenuItem:item];
  [_settingsButton.menu addItemWithTitle:@"" action:NULL keyEquivalent:@""];

  NSMenuItem *showFoldersFirstMenuItem = [[NSMenuItem alloc] initWithTitle:@"Show Folders First"
                                                                    action:@selector(toggleShowFoldersFirst:)
                                                             keyEquivalent:@""];
  showFoldersFirstMenuItem.target = self;
  showFoldersFirstMenuItem.state = _showFoldersFirst ? NSOnState : NSOffState;
  [_settingsButton.menu addItem:showFoldersFirstMenuItem];

  NSMenuItem *showHiddenMenuItem = [[NSMenuItem alloc] initWithTitle:@"Show Hidden Files"
                                                              action:@selector(toggleShowHiddenFiles:)
                                                       keyEquivalent:@""];
  showHiddenMenuItem.target = self;
  showHiddenMenuItem.state = _showHiddenFiles ? NSOnState : NSOffState;
  [_settingsButton.menu addItem:showHiddenMenuItem];

  NSMenuItem *syncWorkspaceWithPwdMenuItem =
      [[NSMenuItem alloc] initWithTitle:@"Sync Working Directory with Vim's 'pwd'"
                                 action:@selector(toggleSyncWorkspaceWithPwd:)
                          keyEquivalent:@""];
  syncWorkspaceWithPwdMenuItem.target = self;
  syncWorkspaceWithPwdMenuItem.state = _syncWorkspaceWithPwd ? NSOnState : NSOffState;
  [_settingsButton.menu addItem:syncWorkspaceWithPwdMenuItem];
}

@end
