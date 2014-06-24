/**
* Tae Won Ha — @hataewon
*
* http://taewon.de
* http://qvacua.com
*
* See LICENSE
*/

#import <MacVimFramework/MacVimFramework.h>
#import "VRWorkspaceView.h"
#import "VRTextMateUiUtils.h"
#import "VRFileBrowserView.h"
#import "VRMainWindowController.h"
#import "VROutlineView.h"
#import "VRUtils.h"
#import "VRWorkspace.h"


#define SQ(x) ((x)*(x))
#define CONSTRAINT(str, ...) [_myConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat: str, ##__VA_ARGS__] options:0 metrics:nil views:views]]


static const int qDefaultFileBrowserWidth = 240;
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

  BOOL _mouseDownRecursionGuard;

  NSView *_fileBrowserDivider;

  NSPathControl *_pathView;
  NSPopUpButton *_settingsButton;

  VRFileBrowserView *_cachedFileBrowserView;
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

- (void)setFileBrowserOnRight:(BOOL)flag {
  if (_fileBrowserOnRight == flag) {
    return;
  }

  _fileBrowserOnRight = flag;

  if (_fileBrowserView) {
    self.needsUpdateConstraints = YES;
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

- (IBAction)hideSidebar:(id)sender {
  self.fileBrowserView = nil;
  [self.window makeFirstResponder:_vimView.textView];
}

- (IBAction)toggleSidebarOnRight:(id)sender {
  self.fileBrowserOnRight = !_fileBrowserOnRight;
  [self.mainWindowController forceRedrawVimView]; // Vim does not refresh the part in which the file browser was
}

- (IBAction)showFileBrowser:(id)sender {
  if (_fileBrowserView) {
    [self.window makeFirstResponder:_fileBrowserView.fileOutlineView];
    return;
  }

  CGRect frame = self.window.frame;
  if (frame.size.width <= _vimView.minSize.width) {
    frame.size.width += self.defaultFileBrowserAndDividerWidth;
    [self.window setFrame:frame display:YES];
  }
  self.fileBrowserView = _cachedFileBrowserView;

  // We do not make the file browser the first responder, when the file browser was hidden and now gets shown
}

#pragma mark Public
- (void)setUrlOfPathControl:(NSURL *)url {
  _pathView.URL = url;
}

- (void)setUp {
  _pathView = [[NSPathControl alloc] initWithFrame:CGRectZero];
  _pathView.translatesAutoresizingMaskIntoConstraints = NO;
  _pathView.pathStyle = NSPathStyleStandard;
  _pathView.backgroundColor = [NSColor clearColor];
  _pathView.refusesFirstResponder = YES;
  [_pathView.cell setControlSize:NSSmallControlSize];
  [_pathView.cell setFont:[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSSmallControlSize]]];
  [_pathView setContentCompressionResistancePriority:NSLayoutPriorityDefaultLow
                                      forOrientation:NSLayoutConstraintOrientationHorizontal];

  [self addSubview:_pathView];

  NSMenuItem *item = [NSMenuItem new];
  item.title = @"";
  item.image = [NSImage imageNamed:NSImageNameActionTemplate];
  [item.image setSize:NSMakeSize(12, 12)];

  _settingsButton = [[NSPopUpButton alloc] initWithFrame:CGRectZero pullsDown:YES];
  _settingsButton.bordered = NO;
  _settingsButton.translatesAutoresizingMaskIntoConstraints = NO;
  [_settingsButton.cell setBackgroundStyle:NSBackgroundStyleRaised];
  [_settingsButton.cell setUsesItemFromMenu:NO];
  [_settingsButton.cell setMenuItem:item];
  [_settingsButton.menu addItemWithTitle:@"" action:NULL keyEquivalent:@""];
  [self addSubview:_settingsButton];

  [self addMenuItemToSettingsButtonWithTitle:@"Show Folders First"
                                      action:@selector(toggleShowFoldersFirst:) flag:_showFoldersFirst];
  [self addMenuItemToSettingsButtonWithTitle:@"Show hidden files"
                                      action:@selector(toggleShowHiddenFiles:) flag:_showHiddenFiles];
  [self addMenuItemToSettingsButtonWithTitle:@"Sync Working Directory with Vim's 'pwd'"
                                      action:@selector(toggleSyncWorkspaceWithPwd:) flag:_syncWorkspaceWithPwd];


  _cachedFileBrowserView = [[VRFileBrowserView alloc] initWithRootUrl:self.mainWindowController.workingDirectory];

  VRWorkspace *workspace = self.mainWindowController.workspace;
  _cachedFileBrowserView.fileItemManager = workspace.fileItemManager;
  _cachedFileBrowserView.userDefaults = workspace.userDefaults;
  _cachedFileBrowserView.notificationCenter = workspace.notificationCenter;
  _cachedFileBrowserView.workspaceView = self;

  [_cachedFileBrowserView setUp];

  if ([self.mainWindowController.workspace.userDefaults boolForKey:qDefaultShowSideBar]) {
    self.fileBrowserView = _cachedFileBrowserView;
  }
}

#pragma mark NSUserInterfaceValidations
- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem {
  SEL action = anItem.action;

  if (action == @selector(showFileBrowser:)) {return YES;}

  if (action == @selector(hideSidebar:)) {return _fileBrowserView != nil;}

  if (action == @selector(toggleStatusBar:)) {
    if (_showStatusBar) {
      [(NSMenuItem *) anItem setTitle:@"Hide Status Bar"];
    } else {
      [(NSMenuItem *) anItem setTitle:@"Show Status Bar"];
    }

    return YES;
  }

  if (action == @selector(toggleSidebarOnRight:)) {
    if (_fileBrowserOnRight) {
      [(NSMenuItem *) anItem setTitle:@"Put Sidebar on Left"];
    } else {
      [(NSMenuItem *) anItem setTitle:@"Put Sidebar on Right"];
    }

    return _fileBrowserView != nil;
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
      @"pathControl" : _pathView,
  };

  if (!_pathView.superview) {[self addSubview:_pathView];}
  if (!_settingsButton.superview) {[self addSubview:_settingsButton];}
  if (!_showStatusBar) {
    [_pathView removeFromSuperview];
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
    [super mouseDown:anEvent];
    _mouseDownRecursionGuard = NO;

    return;
  }

  if (_fileBrowserView) {
    _fileBrowserWidthConstraint.constant = NSWidth(_fileBrowserView.frame);
    _fileBrowserWidthConstraint.priority = NSLayoutPriorityDragThatCannotResizeWindow;
  }

  NSEvent *mouseDownEvent = anEvent;
  CGRect initialFrame = view.frame;

  [self.mainWindowController.vimView viewWillStartLiveResize];

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

  [self.mainWindowController.vimView viewDidEndLiveResize];

  if (!didDrag) {
    NSView *hitView = [super hitTest:[self.superview convertPoint:mouseDownEvent.locationInWindow fromView:nil]];
    if (hitView && hitView != self) {
      [NSApp postEvent:anEvent atStart:NO];
      [hitView mouseDown:mouseDownEvent];
    }
  }

  _fileBrowserWidthConstraint.priority = NSLayoutPriorityDragThatCannotResizeWindow;

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
  if (newView == oldView) {return oldView;}

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
  if (!_fileBrowserView) {return CGRectZero;}

  CGRect rect = _fileBrowserView.frame;
  return CGRectMake(_fileBrowserOnRight ? NSMinX(rect) - 3 : NSMaxX(rect) - 4, NSMinY(rect), 10, NSHeight(rect));
}

- (void)updateMetrics {
  _dragIncrement = (NSUInteger) _vimView.textView.cellSize.width;
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

- (void)addMenuItemToSettingsButtonWithTitle:(NSString *)title action:(SEL)action flag:(BOOL)flag {
  NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:title action:action keyEquivalent:@""];
  menuItem.target = self;
  menuItem.state = flag ? NSOnState : NSOffState;

  [_settingsButton.menu addItem:menuItem];
}

- (VRMainWindowController *)mainWindowController {
  return (VRMainWindowController *) self.window.windowController;
}

@end
