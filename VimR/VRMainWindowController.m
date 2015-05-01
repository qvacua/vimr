/**
* Tae Won Ha — @hataewon
*
* http://taewon.de
* http://qvacua.com
*
* See LICENSE
*/

#import <PSMTabBarControl/PSMTabBarControl.h>
#import <MacVimFramework/MacVimFramework.h>
#import <PureLayout/ALView+PureLayout.h>
#import "VRMainWindowController.h"
#import "VRLog.h"
#import "VRAlert.h"
#import "VRUtils.h"
#import "VRMainWindow.h"
#import "VROpenQuicklyWindowController.h"
#import "VRFileItemManager.h"
#import "VRWorkspace.h"
#import "VRWorkspaceController.h"
#import "VRDefaultLogSetting.h"
#import "VRWorkspaceView.h"
#import "VRFileBrowserOutlineView.h"
#import "VRFileBrowserView.h"
#import "NSArray+VR.h"
#import "VRPreviewWindowController.h"
#import "VRWorkspaceViewFactory.h"
#import "QVWorkspace.h"
#import "VRFileBrowserViewFactory.h"
#import "QVToolbarButtonDelegate.h"
#import "QVToolbar.h"


const int qMainWindowBorderThickness = 22;


static NSString *const qVimRAutoGroupName = @"VimR";
static NSString *const qMainWindowFrameAutosaveName = @"main-window-frame-autosave";


@implementation VRMainWindowController {
  BOOL _vimViewSetUpDone;

  int _userRows;
  int _userCols;
  CGPoint _userTopLeft;
  BOOL _shouldRestoreUserTopLeft;

  BOOL _needsToResizeVimView;
  BOOL _windowOriginShouldMoveToKeepOnScreen;

  QVWorkspace *_workspaceView;
  VRFileBrowserView *_fileBrowserView;
}

#pragma mark Public
- (instancetype)initWithContentRect:(CGRect)contentRect {
  self = [super initWithWindow:[self newMainWindowForContentRect:contentRect]];
  RETURN_NIL_WHEN_NOT_SELF

  _loadDone = NO;

  return self;
}

- (void)updateWorkingDirectory {
  _fileBrowserView.rootUrl = _workspace.workingDirectory;
}

- (void)cleanUpAndClose {
  [self removeUserDefaultsObservation];
  [_vimView removeFromSuperviewWithoutNeedingDisplay];
  [_vimView cleanup];

  [_previewWindowController close];

  // FIXME: where is the bar?! trbl?
  if (self.window.isKeyWindow) {
    [_userDefaults setObject:NSStringFromRect(self.window.frame) forKey:qMainWindowFrameAutosaveName];
    [_userDefaults setFloat:(float) _workspaceView.leftBar.dimension forKey:qSidebarWidthAutosaveName];
  }

  [self close];
}

- (void)openFileWithUrls:(NSURL *)url openMode:(VROpenMode)openMode {
  NSArray *urlsAlreadyOpen = [self alreadyOpenedUrlsFromUrls:@[url]];
  if (!urlsAlreadyOpen.isEmpty) {
    [_vimController gotoBufferWithUrl:url];
    [self.window makeFirstResponder:_vimView.textView];
    return;
  }

  switch (openMode) {
    case VROpenModeInNewTab:
      [_vimController sendMessage:OpenWithArgumentsMsgID data:[self vimArgsAsDataFromUrl:url mode:MMLayoutTabs]];
      break;
    case VROpenModeInCurrentTab:
      [self sendCommandToVim:SF(@":e %@", url.path)];
      break;
    case VROpenModeInVerticalSplit:
      [_vimController sendMessage:OpenWithArgumentsMsgID data:[self vimArgsAsDataFromUrl:url mode:MMLayoutVerticalSplit]];
      break;
    case VROpenModeInHorizontalSplit:
      [_vimController sendMessage:OpenWithArgumentsMsgID data:[self vimArgsAsDataFromUrl:url mode:MMLayoutHorizontalSplit]];
      break;
  }

  [self updateBuffersInTabs];

  [self.window makeFirstResponder:_vimView.textView];
}

- (void)openFilesWithUrls:(NSArray *)urls {
  if (urls.isEmpty) {return;}

  NSArray *urlsAlreadyOpen = [self alreadyOpenedUrlsFromUrls:urls];
  NSMutableArray *urlsToOpen = [[NSMutableArray alloc] initWithArray:urls];
  [urlsToOpen removeObjectsInArray:urlsAlreadyOpen];

  if (!urlsToOpen.isEmpty) {
    [_vimController sendMessage:OpenWithArgumentsMsgID data:[self vimArgsAsDataFromFileUrls:urlsToOpen]];
  } else {
    [_vimController gotoBufferWithUrl:urlsAlreadyOpen[0]];
  }

  [self updateBuffersInTabs];

  [self.window makeFirstResponder:_vimView.textView];
}

- (void)forceRedrawVimView {
  [self sendCommandToVim:@":redraw!"];
}

- (NSURL *)workingDirectory {
  return _workspace.workingDirectory;
}

#pragma mark IBActions
- (IBAction)newTab:(id)sender {
  [self sendCommandToVim:@":tabe"];
}

- (IBAction)performClose:(id)sender {
  NSArray *descriptor = @[@"File", @"Close"];
  [self.vimController sendMessage:ExecuteMenuMsgID data:vim_data_for_menu_descriptor(descriptor)];
}

- (IBAction)saveDocument:(id)sender {
  NSArray *descriptor = @[@"File", @"Save"];
  [self.vimController sendMessage:ExecuteMenuMsgID data:vim_data_for_menu_descriptor(descriptor)];
}

- (IBAction)saveDocumentAs:(id)sender {
  [self sendCommandToVim:@":browse confirm sav"];
}

- (IBAction)revertDocumentToSaved:(id)sender {
  [self sendCommandToVim:@":e!"];
}

- (IBAction)selectNextTab:(id)sender {
  [_vimView selectTabWithIndexDelta:+1];
}

- (IBAction)selectPreviousTab:(id)sender {
  [_vimView selectTabWithIndexDelta:-1];
}

- (IBAction)showPreview:(id)sender {
  [_previewWindowController updatePreview];
  [_previewWindowController showWindow:self];
}

- (IBAction)refreshPreview:(id)sender {
  [_previewWindowController refreshPreview:sender];
}

- (IBAction)zoom:(id)sender {
  // maximize window
  NSScreen *screen = self.window.screen;
  if (!screen) {
    DDLogWarn(@"Window not on screen, zoom to main screen");
    screen = [NSScreen mainScreen];
    if (!screen) {
      DDLogError(@"No main screen, abort zoom");
      return;
    }
  }

  // Decide whether too zoom horizontally or not (always zoom vertically).
  NSEvent *event = [NSApp currentEvent];
  BOOL zoomBoth = event.type == NSLeftMouseUp
      && (event.modifierFlags & NSCommandKeyMask || event.modifierFlags & NSAlternateKeyMask);

  // Figure out how many rows/columns can fit while zoomed.
  int rowsZoomed;
  int colsZoomed;
  CGRect maxFrame = screen.visibleFrame;
  CGSize uncorrectedVimViewSize = [self uncorrectedVimViewSizeForWinFrameRect:maxFrame];
  [_vimView constrainRows:&rowsZoomed columns:&colsZoomed toSize:uncorrectedVimViewSize];

  int curRows, curCols;
  [_vimView.textView getMaxRows:&curRows columns:&curCols];

  int rows, cols;
  BOOL isZoomed = zoomBoth ? curRows >= rowsZoomed && curCols >= colsZoomed : curRows >= rowsZoomed;
  if (isZoomed) {
    rows = _userRows > 0 ? _userRows : curRows;
    cols = _userCols > 0 ? _userCols : curCols;
  } else {
    rows = rowsZoomed;
    cols = zoomBoth ? colsZoomed : curCols;

    if (curRows + 2 < rows || curCols + 2 < cols) {
      // The window is being zoomed so save the current "user state".
      // Note that if the window does not enlarge by a 'significant'
      // number of rows/columns then we don't save the current state.
      // This is done to take into account toolbar/scrollbars
      // showing/hiding.
      _userRows = curRows;
      _userCols = curCols;
      CGRect frame = self.window.frame;
      _userTopLeft = CGPointMake(frame.origin.x, NSMaxY(frame));
    }
  }

  // NOTE: Instead of resizing the window immediately we send a zoom message
  // to the backend so that it gets a chance to resize before the window
  // does.  This avoids problems with the window flickering when zooming.
  int info[3] = {rows, cols, !isZoomed};
  NSData *data = [NSData dataWithBytes:info length:3 * sizeof(int)];
  [_vimController sendMessage:ZoomMsgID data:data];
}

- (IBAction)openQuickly:(id)sender {
  @synchronized (_fileItemManager) {
    [_fileItemManager setTargetUrl:self.workingDirectory];
    [_openQuicklyWindowController showForWindowController:self];
  }
}

- (IBAction)zoomIn:(id)sender {
  [_fontManager modifyFont:sender];
}

- (IBAction)zoomOut:(id)sender {
  [_fontManager modifyFont:sender];
}

- (IBAction)selectNthTab:(id)sender {
  [_vimView selectTabWithIndex:(int) [sender tag] fromVim:NO];
}

#ifdef DEBUG
- (IBAction)debug1Action:(id)sender {
//  DDLogDebug(@"tabs: %@", _vimController.tabs);
//  DDLogDebug(@"buffers: %@", _vimController.buffers);
//  NSMenu *menu = _vimController.mainMenu;
//  NSMenuItem *fileMenu = menu.itemArray[2];
//  NSArray *editMenuArray = [[fileMenu submenu] itemArray];
//  DDLogDebug(@"edit menu: %@", editMenuArray);
}
#endif

#pragma mark NSUserInterfaceValidations
- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem {
  SEL action = anItem.action;

  if (action == @selector(newTab:)) {return YES;}
  if (action == @selector(performClose:)) {return YES;}
  if (action == @selector(saveDocument:)) {return YES;}
  if (action == @selector(saveDocumentAs:)) {return YES;}
  if (action == @selector(revertDocumentToSaved:)) {return YES;}
  if (action == @selector(openQuickly:)) {return YES;}
  if (action == @selector(showPreview:)) {return YES;}

  if (action == @selector(zoomIn:)) {return YES;}
  if (action == @selector(zoomOut:)) {return YES;}

  if (action == @selector(selectNthTab:)) {return YES;}

#ifdef DEBUG
  if (action == @selector(debug1Action:)) {return YES;}
#endif

  if (action == @selector(refreshPreview:)) {
    return _previewWindowController.window.isVisible;
  }

  if (action == @selector(selectNextTab:) || action == @selector(selectPreviousTab:)) {
    return _vimController.tabs.count >= 2;
  }

  return NO;
}

#pragma mark NSObject
- (void)dealloc {
  log4Mark;
}

#pragma mark VRUserDefaultsObserver
- (void)registerUserDefaultsObservation {
  [_userDefaults addObserver:self forKeyPath:qDefaultAutoSaveOnFrameDeactivation options:NSKeyValueObservingOptionNew context:NULL];
  [_userDefaults addObserver:self forKeyPath:qDefaultAutoSaveOnCursorHold options:NSKeyValueObservingOptionNew context:NULL];
}

- (void)removeUserDefaultsObservation {
  [_userDefaults removeObserver:self forKeyPath:qDefaultAutoSaveOnFrameDeactivation];
  [_userDefaults removeObserver:self forKeyPath:qDefaultAutoSaveOnCursorHold];
}

#pragma mark MMViewDelegate informal protocol
/**
* Resize code
*/
- (void)liveResizeWillStart {
  /**
  * NOTE: During live resize Cocoa goes into "event tracking mode".  We have
  * to add the backend connection to this mode in order for resize messages
  * from Vim to reach MacVim.  We do not wish to always listen to requests
  * in event tracking mode since then MacVim could receive DO messages at
  * unexpected times (e.g. when a key equivalent is pressed and the menu bar
  * momentarily lights up).
  */
  [self.connectionToBackend addRequestMode:NSEventTrackingRunLoopMode];
}

/**
* Resize code
*/
- (void)liveResizeDidEnd {
  // See comment regarding event tracking mode in -liveResizeWillStart.
  [self.connectionToBackend removeRequestMode:NSEventTrackingRunLoopMode];

  /**
  * NOTE: During live resize messages from MacVim to Vim are often dropped
  * (because too many messages are sent at once).  This may lead to
  * inconsistent states between Vim and MacVim; to avoid this we send a
  * synchronous resize message to Vim now (this is not fool-proof, but it
  * does seem to work quite well).
  * Do NOT send a SetTextDimensionsMsgID message (as opposed to
  * LiveResizeMsgID) since then the view is constrained to not be larger
  * than the screen the window mostly occupies; this makes it impossible to
  * resize the window across multiple screens.
  */

  NSView <MMTextViewProtocol> *textView = _vimView.textView;

  int constrained[2];
  [textView constrainRows:&constrained[0] columns:&constrained[1] toSize:textView.frame.size];

  DDLogDebug(@"End of live resize, notify Vim that text dimensions are %d x %d", constrained[1], constrained[0]);

  NSData *data = [NSData dataWithBytes:constrained length:(2 * sizeof(int))];
  BOOL liveResizeMsgSuccessful = [_vimController sendMessageNow:LiveResizeMsgID data:data timeout:.5];

  if (!liveResizeMsgSuccessful) {
    /**
    * Sending of synchronous message failed.  Force the window size to
    * match the last dimensions received from Vim, otherwise we end up
    * with inconsistent states.
    */
    CGSize manualWinContentSize = [self winContentSizeForVimViewSize:_vimView.desiredSize];
    [self resizeWindowToFitContentSize:manualWinContentSize];
  }

  [self setWindowTitleToCurrentBuffer];
}

#pragma mark MMVimControllerDelegate
/**
* Resize code
*/
- (void)controller:(MMVimController *)controller zoomWithRows:(int)rows columns:(int)columns state:(int)state
              data:(NSData *)data {

  DDLogWarn(@"zoom with rows and colums: %d X %d", rows, columns);

  [_vimView setDesiredRows:rows columns:columns];
  _needsToResizeVimView = YES;
  _windowOriginShouldMoveToKeepOnScreen = YES;

  // NOTE: If state==0 then the window should be put in the non-zoomed
  // "user state".  That is, move the window back to the last stored
  // position.  If the window is in the zoomed state, the call to change the
  // dimensions above will also reposition the window to ensure it fits on
  // the screen.  However, since resizing of the window is delayed we also
  // delay repositioning so that both happen at the same time (this avoid
  // situations where the window would appear to "jump").
  if (!state && !CGPointEqualToPoint(CGPointZero, _userTopLeft)) {
    _shouldRestoreUserTopLeft = YES;
  }
}

- (void)controller:(MMVimController *)controller handleShowDialogWithButtonTitles:(NSArray *)buttonTitles
             style:(NSAlertStyle)style message:(NSString *)message text:(NSString *)text
   textFieldString:(NSString *)textFieldString data:(NSData *)data {

  log4Mark;

  // copied from MacVim {
  VRAlert *alert = [[VRAlert alloc] init];
  alert.alertStyle = style;

  // NOTE: This has to be done before setting the informative text.
  if (textFieldString) {
    alert.textFieldString = textFieldString;
  }

  if (message) {
    alert.messageText = message;
  } else {
    // If no message text is specified 'Alert' is used, which we don't
    // want, so set an empty string as message text.
    alert.messageText = @"";
  }

  if (text) {
    alert.informativeText = text;
  } else if (textFieldString) {
    // Make sure there is always room for the input text field.
    alert.informativeText = @"";
  }

  unsigned i;
  int count = buttonTitles.count;
  for (i = 0; i < count; ++i) {
    NSString *title = buttonTitles[i];
    // NOTE: The title of the button may contain the character '&' to
    // indicate that the following letter should be the key equivalent
    // associated with the button.  Extract this letter and lowercase it.
    NSString *keyEquivalent = nil;
    NSRange hotkeyRange = [title rangeOfString:@"&"];
    if (NSNotFound != hotkeyRange.location) {
      if ([title length] > NSMaxRange(hotkeyRange)) {
        NSRange keyEquivRange = NSMakeRange(hotkeyRange.location + 1, 1);
        keyEquivalent = [title substringWithRange:keyEquivRange].lowercaseString;
      }

      NSMutableString *string = [NSMutableString stringWithString:title];
      [string deleteCharactersInRange:hotkeyRange];
      title = string;
    }

    [alert addButtonWithTitle:title];

    // Set key equivalent for the button, but only if NSAlert hasn't
    // already done so.  (Check the documentation for
    // - [NSAlert addButtonWithTitle:] to see what key equivalents are
    // automatically assigned.)
    NSButton *btn = alert.buttons.lastObject;
    if (btn.keyEquivalent.length == 0 && keyEquivalent) {
      btn.keyEquivalent = keyEquivalent;
    }
  }

  [alert beginSheetModalForWindow:self.window modalDelegate:self didEndSelector:@selector(alertDidEnd:code:context:)
                      contextInfo:NULL];
  // } copied from MacVim
}

- (void)controller:(MMVimController *)controller showScrollbarWithIdentifier:(int32_t)identifier state:(BOOL)state
              data:(NSData *)data {

  [self.vimView showScrollbarWithIdentifier:identifier state:state];
  if (!_vimViewSetUpDone) {
    // This delegate method is called when live resizing. Thus, set resize to YES, only when we are opening the window.
    _needsToResizeVimView = YES;
  }
}

- (void)controller:(MMVimController *)controller setTextDimensionsWithRows:(int)rows columns:(int)columns
            isLive:(BOOL)live keepOnScreen:(BOOL)winOriginShouldMove data:(NSData *)data {

  DDLogDebug(@"%d X %d, live: %@, winOriginShouldMove: %@", rows, columns, @(live), @(winOriginShouldMove));
  [_vimView setDesiredRows:rows columns:columns];
  [self updateResizeConstraints];

  if (!_vimViewSetUpDone) {
    DDLogDebug(@"not yet setup");
    return;
  }

  if (!live) {
    _needsToResizeVimView = YES;
    _windowOriginShouldMoveToKeepOnScreen = winOriginShouldMove;
  }
}

- (void)controller:(MMVimController *)controller openWindowWithData:(NSData *)data {
  self.window.acceptsMouseMovedEvents = YES; // Vim wants to have mouse move events

  [self updateResizeConstraints];

  [self addViews];

  [_vimView addNewTabViewItem];

  [self registerUserDefaultsObservation];
  [self applyUserDefaultsToVim];

  _vimViewSetUpDone = YES;
  _windowOriginShouldMoveToKeepOnScreen = YES;

  [_workspace setUpInitialBuffers];

  /**
  * FIXME: When opening a folder and netrw is used, the Vim view does not get redrawn...
  * When NERDTree ist used, the screen does get redrawn, but there is another problem,
  * cf https://github.com/qvacua/vimr/issues/35 and
  */
  [self forceRedrawVimView];

  [self.window makeFirstResponder:_vimView.textView];
}

- (void)controller:(MMVimController *)controller showTabBarWithData:(NSData *)data {
  _vimView.tabBarControl.hidden = NO;
}

- (void)controller:(MMVimController *)controller destroyScrollbarWithIdentifier:(int32_t)identifier data:(NSData *)data {
  _needsToResizeVimView = YES;
}

- (void)controller:(MMVimController *)controller tabDidUpdateWithData:(NSData *)data {
  [self updateBuffersInTabs];
  [self updatePreview];
}

- (void)updatePreview {
  if (!_previewWindowController.window.isVisible) {
    return;
  }

  [_previewWindowController updatePreview];
}

- (void)controller:(MMVimController *)controller hideTabBarWithData:(NSData *)data {
  _vimView.tabBarControl.hidden = YES;
  [self updateBuffersInTabs];
}

- (void)controller:(MMVimController *)controller setBufferModified:(BOOL)modified data:(NSData *)data {
  self.documentEdited = modified;
}

- (void)controller:(MMVimController *)controller setDocumentFilename:(NSString *)filename data:(NSData *)data {
  self.window.representedFilename = filename;
}

- (void)controller:(MMVimController *)controller setVimState:(NSDictionary *)vimState data:(NSData *)data {
  // FIXME
//  if (_workspaceView.syncWorkspaceWithPwd) {
//    NSString *pwdPath = _vimController.vimState[@"pwd"];
//    if (![_workspace.workingDirectory.path isEqualToString:pwdPath]) {
//      [_workspace updateWorkingDirectoryToUrl:[[NSURL alloc] initFileURLWithPath:pwdPath]];
//    }
//  }
}

- (void)controller:(MMVimController *)controller setWindowTitle:(NSString *)title data:(NSData *)data {
  // FIXME
  [self setWindowTitleToCurrentBuffer];

//  if (!_vimController.currentBuffer.fileName) {
//    [_workspaceView setUrlOfPathControl:_workspace.workingDirectory];
//  } else {
//    [_workspaceView setUrlOfPathControl:[NSURL fileURLWithPath:_vimController.currentBuffer.fileName]];
//  }
}

/**
* Resize code
*/
- (void)controller:(MMVimController *)controller processFinishedForInputQueue:(NSArray *)inputQueue {
  if (!_needsToResizeVimView) {return;}

  // When :set lines=2000, the following happens:
  // - setTextDimensions is called with rows=2000, keepOnScreen=YES
  // - in this method, we constrain the window frame to fit the screen size, ie the size of the Vim view changes which
  //   is small to accommodate 2000 rows.
  // - thus, setTextDimensions is called again with eg rows=60, keepOnScreen=NO

  _needsToResizeVimView = NO;

  // We have to start our computation of window frame with the desired size of the Vim view because of non-GUI resize
  // requests like :set columns=XYZ

  CGSize reqVimViewSize = _vimView.desiredSize;

  // We constrain the desired size of the Vim view to the visible frame of the screen. This can happen, when you
  // for instance use :set lines=BIG_NUMBER

  CGSize reqWinContentSizeView = [self winContentSizeForVimViewSize:reqVimViewSize];
  CGSize constrainedWinContentSize = [self constrainContentSizeToScreenSize:reqWinContentSizeView];

  // The constrained window frame size may be not integral for the Vim view, however, there's no need for re-adjustment,
  // because
  // 1. If the requested size was too big for the screen, then the win frame size got constrained and Vim will call
  //    setTextDimension again, which will again resize the window with a size that will fit to the screen and will be
  //    integral for the Vim view.
  // 2. If the requested size did fit to the screen, then the resulting size is already integral for the Vim view.

  [self resizeWindowToFitContentSize:constrainedWinContentSize];

  _windowOriginShouldMoveToKeepOnScreen = NO;

  // FIXME: this is a quick-and-dirty hack to avoid the empty window when opening a new main window.
  if (_loadDone) {return;}

  NSString *savedRectString = [_userDefaults objectForKey:qMainWindowFrameAutosaveName];
  CGRect savedRect;
  if (savedRectString) {
    savedRect = NSRectFromString(savedRectString);
    CGRect integralRect = [self desiredWinFrameRectForWinFrameRect:savedRect];
    CGRect integralRectToKeepOnScreen = [self winFrameRectToKeepOnScreenForWinFrameRect:integralRect];

    CGPoint origin = self.window.frame.origin;

    [self.window setFrame:integralRectToKeepOnScreen display:NO animate:NO];
    if (!_workspace.isOnlyWorkspace) {
      [self.window setFrameOrigin:origin];
    }
  }

  [self showWindow:self];
  _loadDone = YES;
}

- (void)controller:(MMVimController *)controller handleBrowseWithDirectoryUrl:(NSURL *)url browseDir:(BOOL)dir saving:(BOOL)saving data:(NSData *)data {
  if (!saving) {
    return;
  }

  NSSavePanel *savePanel = [NSSavePanel savePanel];
  if (url != nil) {
    [savePanel setDirectoryURL:url];
  }

  [savePanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
    NSString *path = nil;
    if (result == NSOKButton) {
      path = savePanel.URL.path;
    }

    [savePanel orderBack:self];

    if (![controller sendDialogReturnToBackend:path]) {
      log4Error(@"some error occurred sending dialog return value %@ to backend!", path);
      return;
    }
  }];
}

- (void)controller:(MMVimController *)controller setTooltipDelay:(float)delay {
  DDLogDebug(@"NOOP");
}

- (void)controller:(MMVimController *)controller tabShouldUpdateWithData:(NSData *)data {
  DDLogDebug(@"NOOP");
}

- (void)controller:(MMVimController *)controller setScrollbarThumbValue:(float)value proportion:(float)proportion identifier:(int32_t)identifier data:(NSData *)data {
  DDLogDebug(@"NOOP");
}

- (void)controller:(MMVimController *)controller tabDraggedWithData:(NSData *)data {
  DDLogDebug(@"NOOP");
}

- (void)controller:(MMVimController *)controller removeToolbarItemWithIdentifier:(NSString *)identifier {
  DDLogDebug(@"NOOP");
}

- (void)controller:(MMVimController *)controller setDefaultColorsBackground:(NSColor *)background foreground:(NSColor *)foreground data:(NSData *)data {
  DDLogDebug(@"NOOP");
}

- (void)controller:(MMVimController *)controller adjustLinespace:(int)linespace data:(NSData *)data {
  DDLogDebug(@"NOOP");
}

- (void)controller:(MMVimController *)controller setFont:(NSFont *)font data:(NSData *)data {
  DDLogDebug(@"NOOP");
}

- (void)controller:(MMVimController *)controller setWideFont:(NSFont *)font data:(NSData *)data {
  DDLogDebug(@"NOOP");
}

- (void)controller:(MMVimController *)controller createScrollbarWithIdentifier:(int32_t)identifier type:(int)type data:(NSData *)data {
  DDLogDebug(@"NOOP");
}

- (void)controller:(MMVimController *)controller setMouseShape:(int)shape data:(NSData *)data {
  DDLogDebug(@"NOOP");
}

- (void)controller:(MMVimController *)controller setStateToolbarItemWithIdentifier:(NSString *)identifier state:(BOOL)state {
  DDLogDebug(@"NOOP");
}

- (void)controller:(MMVimController *)controller addToolbarItemWithLabel:(NSString *)label tip:(NSString *)tip icon:(NSString *)icon atIndex:(int)idx {
  DDLogDebug(@"NOOP");
}

- (void)controller:(MMVimController *)controller showToolbar:(BOOL)enable flags:(int)flags data:(NSData *)data {
  DDLogDebug(@"NOOP");
}

- (void)controller:(MMVimController *)controller setScrollbarPosition:(int)position length:(int)length identifier:(int32_t)identifier data:(NSData *)data {
  DDLogDebug(@"NOOP");
}

- (void)controller:(MMVimController *)controller setAntialias:(BOOL)antialias data:(NSData *)data {
  DDLogDebug(@"NOOP");
}

- (void)controller:(MMVimController *)controller activateIm:(BOOL)activate data:(NSData *)data {
  DDLogDebug(@"NOOP");
}

- (void)controller:(MMVimController *)controller setImControl:(BOOL)control data:(NSData *)data {
  DDLogDebug(@"NOOP");
}

- (void)controller:(MMVimController *)controller addToMru:(NSArray *)filenames data:(NSData *)data {
  DDLogDebug(@"NOOP");
}

- (void)controller:(MMVimController *)controller setWindowPosition:(NSPoint)position data:(NSData *)data {
  DDLogDebug(@"NOOP");
}

- (void)controller:(MMVimController *)controller activateWithData:(NSData *)data {
  DDLogDebug(@"NOOP");
}

- (void)controller:(MMVimController *)controller enterFullScreen:(int)screen backgroundColor:(NSColor *)color data:(NSData *)data {
  DDLogDebug(@"NOOP");
}

- (void)controller:(MMVimController *)controller leaveFullScreenWithData:(NSData *)data {
  DDLogDebug(@"NOOP");
}

- (void)controller:(MMVimController *)controller setFullScreenBackgroundColor:(NSColor *)color data:(NSData *)data {
  DDLogDebug(@"NOOP");
}

- (void)controller:(MMVimController *)controller showFindReplaceDialogWithText:(id)text flags:(int)flags data:(NSData *)data {
  DDLogDebug(@"NOOP");
}

- (void)controller:(MMVimController *)controller dropFiles:(NSArray *)filenames forceOpen:(BOOL)force {
  DDLogDebug(@"NOOP");
}

// The following delegate method is called too often...
//- (void)controller:(MMVimController *)controller setPreEditRow:(int)row column:(int)column data:(NSData *)data {
//  DDLogDebug(@"NOOP");
//}

#pragma mark NSWindowDelegate
- (void)windowDidBecomeMain:(NSNotification *)notification {
  [_vimController sendMessage:GotFocusMsgID data:nil];
}

- (void)windowDidResignMain:(NSNotification *)notification {
  [_vimController sendMessage:LostFocusMsgID data:nil];
}

- (BOOL)windowShouldClose:(id)sender {
  /**
  * this gets called when Cmd-W
  */

  // don't close the window or tab; instead let Vim decide what to do
  [_vimController sendMessage:VimShouldCloseMsgID data:nil];

  return NO;
}

- (void)windowDidExitFullScreen:(NSNotification *)notification {
  [self forceRedrawVimView];
}

/**
* Resize code
*/
- (void)windowDidResize:(id)sender {
  if (_loadDone) {
    [_userDefaults setObject:NSStringFromRect(self.window.frame) forKey:qMainWindowFrameAutosaveName];
    [_userDefaults synchronize];
  }
}

/**
* Resize code
*/
- (NSSize)windowWillResize:(NSWindow *)sender toSize:(NSSize)frameSize {
  // To set -contentResizeIncrements of the window to the cell width of the vim view does not suffice because of the
  // file browser and insets among others. Here, we adjust the width of the window such that the vim view is always
  // A * column wide where A is an integer. And the height.
  CGRect winRect = sender.frame;
  winRect.size = frameSize;

  return [self desiredWinFrameRectForWinFrameRect:winRect].size;
}

#pragma mark KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
  [self applyUserDefaultsToVim];
}


#pragma mark Private
- (void)sendMultipleCommandsToVim:(NSArray *)commands {
  NSString *joinedCmds = [commands componentsJoinedByString:@"<CR>"];

  [self sendCommandToVim:joinedCmds];
}

- (void)applyUserDefaultsToVim {
  BOOL autoSaveOnFrameDeactivation = [_userDefaults boolForKey:qDefaultAutoSaveOnFrameDeactivation];
  BOOL autoSaveOnCursorHold = [_userDefaults boolForKey:qDefaultAutoSaveOnCursorHold];

  if (autoSaveOnFrameDeactivation) {
    [self sendMultipleCommandsToVim:@[
        SF(@":augroup %@", qVimRAutoGroupName),
        @":autocmd BufLeave,FocusLost * silent! wall",
        @":augroup END",
    ]];
  } else {
    [self sendMultipleCommandsToVim:@[
        SF(@":augroup %@", qVimRAutoGroupName),
        @":autocmd! BufLeave,FocusLost *",
        @":augroup END",
    ]];
  }

  if (autoSaveOnCursorHold) {
    [self sendMultipleCommandsToVim:@[
        SF(@":augroup %@", qVimRAutoGroupName),
        @":autocmd CursorHold * silent! wall",
        @":augroup END",
    ]];
  } else {
    [self sendMultipleCommandsToVim:@[
        SF(@":augroup %@", qVimRAutoGroupName),
        @":autocmd! CursorHold *",
        @":augroup END",
    ]];
  }
}

- (void)addViews {
  _vimView.tabBarControl.styleNamed = @"Metal";

  _workspaceView = [_workspaceViewFactory newWorkspaceViewWithFrame:CGRectZero vimView:_vimView];

  // FIXME: nil workspace view
  _fileBrowserView = [_fileBrowserViewFactory newFileBrowserViewWithVimController:_vimController rootUrl:self.workingDirectory];
  [_fileBrowserView setUp];

  [_workspaceView addToolView:_fileBrowserView displayName:@"Files" location:QVToolbarLocationLeft];

  [self.window.contentView addSubview:_workspaceView];

  [_workspaceView autoPinEdgesToSuperviewEdgesWithInsets:ALEdgeInsetsZero];
}

- (void)sendCommandToVim:(NSString *)command {
  DDLogDebug(@"sending command %@", command);
  [_vimController addVimInput:SF(@"<C-\\><C-N>%@<CR>", command)];
}

- (void)alertDidEnd:(VRAlert *)alert code:(int)code context:(void *)controllerContext {
  NSArray *ret = nil;
  code = code - NSAlertFirstButtonReturn + 1;

  if ([alert isKindOfClass:[VRAlert class]] && alert.textField) {
    ret = @[@(code), alert.textField.stringValue];
  } else {
    ret = @[@(code)];
  }

  DDLogDebug(@"Alert return=%@", ret);

  // NOTE!  This causes the sheet animation to run its course BEFORE the rest
  // of this function is executed.  If we do not wait for the sheet to
  // disappear before continuing it can happen that the controller is
  // released from under us (i.e. we'll crash and burn) because this
  // animation is otherwise performed in the default run loop mode!
  [alert.window orderOut:self];

  // TODO: why not use -sendDialogReturnToBackend:?
  [_vimController tellBackend:ret];
}

- (NSConnection *)connectionToBackend {
  NSDistantObject *proxy = _vimController.backendProxy;

  return proxy.connectionForProxy;
}

- (void)setWindowTitleToCurrentBuffer {
  NSString *filePath = _vimController.currentBuffer.fileName;
  NSString *filename = filePath.lastPathComponent;

  if (filename == nil) {
    self.window.title = SF(@"Untitled — [%@]", [_vimController.vimState[@"pwd"] stringByAbbreviatingWithTildeInPath]);
    return;
  }

  self.window.title = SF(@"%@ — [%@]", filename, filePath.stringByDeletingLastPathComponent.stringByAbbreviatingWithTildeInPath);
}

- (VRMainWindow *)newMainWindowForContentRect:(CGRect)contentRect {
  unsigned windowStyle = NSTitledWindowMask | NSUnifiedTitleAndToolbarWindowMask
      | NSClosableWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask
      | NSTexturedBackgroundWindowMask;

  VRMainWindow *window = [[VRMainWindow alloc] initWithContentRect:contentRect styleMask:windowStyle backing:NSBackingStoreBuffered defer:YES];
  window.delegate = self;
  window.hasShadow = YES;
  window.title = @"VimR";
  window.opaque = NO;
  window.animationBehavior = NSWindowAnimationBehaviorDocumentWindow;

  [window setAutorecalculatesContentBorderThickness:NO forEdge:NSMinYEdge];
  [window setContentBorderThickness:qMainWindowBorderThickness forEdge:NSMinYEdge];

  return window;
}

- (void)updateBuffersInTabs {
  [_workspace updateBuffersInTabs];

  // FIXME
//  if (_workspaceView.syncWorkspaceWithPwd) {
//    return;
//  }

  [_workspace updateWorkingDirectoryToCommonParent];
}

- (NSData *)vimArgsAsDataFromFileUrls:(NSArray *)fileUrls {
  NSMutableArray *filenames = [[NSMutableArray alloc] initWithCapacity:4];
  for (NSURL *url in fileUrls) {
    [filenames addObject:url.path];
  }

  return @{
      qVimArgFileNamesToOpen : filenames,
      qVimArgOpenFilesLayout : @(MMLayoutTabs),
  }.dictionaryAsData;
}

- (NSMutableArray *)alreadyOpenedUrlsFromUrls:(NSArray *)urls {
  NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:urls.count];
  NSArray *buffers = _vimController.buffers;

  for (NSURL *url in urls) {
    for (MMBuffer *buffer in buffers) {
      if ([buffer.fileName isEqualToString:url.path]) {
        [result addObject:url];
      }
    }
  }

  return result;
}

- (BOOL)fileBrowserVisible {
  return _workspaceView.leftBar.hasActiveTool;
}

- (NSData *)vimArgsAsDataFromUrl:(NSURL *)url mode:(NSUInteger)mode {
  return @{
      qVimArgFileNamesToOpen : @[url.path],
      qVimArgOpenFilesLayout : @(mode),
  }.dictionaryAsData;
}

#pragma mark Private Resize Code
/**
* The resulting Vim view size is not guaranteed to be integral.
*
* Resize code
*/
- (CGSize)uncorrectedVimViewSizeForWinFrameRect:(CGRect)winFrameRect {
  CGSize winContentSize = [self.window contentRectForFrameRect:winFrameRect].size;

  // FIXME
  winContentSize.width = winContentSize.width - _workspaceView.leftBar.dimension;
  winContentSize.height = winContentSize.height;// - (_workspaceView.showStatusBar ? (qMainWindowBorderThickness + 1) : 0);

  return winContentSize;
}

/**
* Resize code
*/
- (CGSize)winContentSizeForVimViewSize:(CGSize)vimViewSize {
  // FIXME
  return CGSizeMake(
      _workspaceView.leftBar.dimension + vimViewSize.width,
      vimViewSize.height// + (_workspaceView.showStatusBar ? (qMainWindowBorderThickness + 1) : 0)
  );
}

/**
* We does not check whether the resulting rect will be bigger then the screen.
*
* Resize code
*/
- (CGRect)desiredWinFrameRectForWinFrameRect:(CGRect)winFrameRect {
  CGSize givenVimViewSize = [self uncorrectedVimViewSizeForWinFrameRect:winFrameRect];
  CGSize desiredVimViewSize = [_vimView constrainRows:NULL columns:NULL toSize:givenVimViewSize];

  CGRect contentRect = [self.window contentRectForFrameRect:winFrameRect];
  contentRect.size = [self winContentSizeForVimViewSize:desiredVimViewSize];

  return [self.window frameRectForContentRect:contentRect];
}

/**
* We expect that targetWinContentSize does fit to the screen.
*
* Resize code
*/
- (void)resizeWindowToFitContentSize:(CGSize)targetWinContentSize {
  NSWindow *window = self.window;
  CGRect curWinFrameRect = window.frame;
  CGRect curContentRect = [self.window contentRectForFrameRect:curWinFrameRect];
  CGRect targetContentRect;

  // Keep top-left corner of the window fixed when resizing.
  targetContentRect.origin = curContentRect.origin;
  targetContentRect.origin.y -= targetWinContentSize.height - curContentRect.size.height;
  targetContentRect.size = targetWinContentSize;

  CGRect targetWinFrameRect = [window frameRectForContentRect:targetContentRect];

  if (_shouldRestoreUserTopLeft) {
    // Restore user top left window position (which is saved when zooming).
    CGFloat dy = _userTopLeft.y - NSMaxY(targetWinFrameRect);
    targetWinFrameRect.origin.x = _userTopLeft.x;
    targetWinFrameRect.origin.y += dy;
    _shouldRestoreUserTopLeft = NO;
  }

  NSScreen *screen = window.screen;
  if (_windowOriginShouldMoveToKeepOnScreen && screen) {
    targetWinFrameRect = [self winFrameRectToKeepOnScreenForWinFrameRect:targetWinFrameRect];
  }

  DDLogDebug(@"Resizing window to %@", vrect(targetWinFrameRect));
  [window setFrame:targetWinFrameRect display:YES];

  CGPoint oldTopLeft = CGPointMake(curWinFrameRect.origin.x, NSMaxY(curWinFrameRect));
  CGPoint newTopLeft = CGPointMake(targetWinFrameRect.origin.x, NSMaxY(targetWinFrameRect));
  if (CGPointEqualToPoint(oldTopLeft, newTopLeft)) {
    DDLogDebug(@"returning since top left point equal");
    return;
  }

  // NOTE: The window top left position may change due to the window
  // being moved e.g. when the tabline is shown so we must tell Vim what
  // the new window position is here.
  // NOTE 2: Vim measures Y-coordinates from top of screen.
  int pos[2] = {(int) newTopLeft.x, (int) (NSMaxY(window.screen.frame) - newTopLeft.y)};
  [_vimController sendMessage:SetWindowPositionMsgID data:[NSData dataWithBytes:pos length:2 * sizeof(int)]];
}

/**
* Resize code
*/
- (CGRect)winFrameRectToKeepOnScreenForWinFrameRect:(CGRect)reqWinFrameRect {
  // Ensure that the window fits inside the visible part of the screen.
  // If there are more than one screen the window will be moved to fit
  // entirely in the screen that most of it occupies.
  CGRect targetWinFrameRect = reqWinFrameRect;
  CGRect maxFrame = self.window.screen.visibleFrame;

  if (targetWinFrameRect.origin.y < maxFrame.origin.y) {
    targetWinFrameRect.origin.y = maxFrame.origin.y;
  }

  if (NSMaxY(targetWinFrameRect) > NSMaxY(maxFrame)) {
    targetWinFrameRect.origin.y = NSMaxY(maxFrame) - targetWinFrameRect.size.height;
  }

  if (targetWinFrameRect.origin.x < maxFrame.origin.x) {
    targetWinFrameRect.origin.x = maxFrame.origin.x;
  }

  if (NSMaxX(targetWinFrameRect) > NSMaxX(maxFrame)) {
    targetWinFrameRect.origin.x = NSMaxX(maxFrame) - targetWinFrameRect.size.width;
  }

  return targetWinFrameRect;
}

/**
* Resize code
*/
- (CGSize)constrainContentSizeToScreenSize:(CGSize)winContentSize {
  NSWindow *win = self.window;
  if (win.screen == nil) {
    return winContentSize;
  }

  // NOTE: This may be called in both windowed and full-screen mode.  The
  // "visibleFrame" method does not overlap menu and dock so should not be
  // used in full-screen.
  CGRect screenRect = win.screen.visibleFrame;
  CGRect rect = [self.window contentRectForFrameRect:screenRect];

  if (winContentSize.height > rect.size.height) {
    winContentSize.height = rect.size.height;
  }

  if (winContentSize.width > rect.size.width) {
    winContentSize.width = rect.size.width;
  }

  return winContentSize;
}

/**
* Resize code
*/
- (void)updateResizeConstraints {
  if (!_vimViewSetUpDone) {
    return;
  }

  NSRect winFrameRect = self.window.frame;
  winFrameRect.size = [self winContentSizeForVimViewSize:_vimView.minSize];
  self.window.minSize = [self.window frameRectForContentRect:winFrameRect].size;

  // FIXME
  // We also update the increment of the workspace view, because it could be that the font size has changed
  _workspaceView.leftBar.dragIncrement = (NSUInteger) _vimView.textView.cellSize.width;
}

@end
