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
#import "VRFileBrowserView.h"
#import "NSArray+VR.h"
#import "VROutlineView.h"


#define CONSTRAINT(fmt) [contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:fmt options:0 metrics:nil views:views]];


@implementation VRMainWindowController {
  int _userRows;
  int _userCols;
  CGPoint _userTopLeft;
  BOOL _shouldRestoreUserTopLeft;
  BOOL _winShouldNotMove;
  BOOL _vimViewSetUpDone;
  BOOL _needsToResizeVimView;

  VRWorkspaceView *_workspaceView;
  VRFileBrowserView *_fileBrowserView;
}

#pragma mark Public

- (instancetype)initWithContentRect:(CGRect)contentRect {
  self = [super initWithWindow:[self newMainWindowForContentRect:contentRect]];
  RETURN_NIL_WHEN_NOT_SELF

  return self;
}

- (void)updateWorkingDirectory {
  _fileBrowserView.rootUrl = _workspace.workingDirectory;
}

- (void)cleanUpAndClose {
  log4Mark;

  [_vimView removeFromSuperviewWithoutNeedingDisplay];
  [_vimView cleanup];

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
      [_vimController sendMessage:OpenWithArgumentsMsgID
                             data:[self vimArgsFromUrl:url mode:MMLayoutTabs].dictionaryAsData];
      break;
    case VROpenModeInCurrentTab:
      [self sendCommandToVim:SF(@":e %@", url.path)];
      break;
    case VROpenModeInVerticalSplit:
      [_vimController sendMessage:OpenWithArgumentsMsgID
                             data:[self vimArgsFromUrl:url mode:MMLayoutVerticalSplit].dictionaryAsData];
      break;
    case VROpenModeInHorizontalSplit:
      [_vimController sendMessage:OpenWithArgumentsMsgID
                             data:[self vimArgsFromUrl:url mode:MMLayoutHorizontalSplit].dictionaryAsData];
      break;
  }

  [self.window makeFirstResponder:_vimView.textView];
}

- (void)openFilesWithUrls:(NSArray *)urls {
  if (urls.isEmpty) {
    return;
  }

  NSArray *urlsAlreadyOpen = [self alreadyOpenedUrlsFromUrls:urls];
  NSMutableArray *urlsToOpen = [[NSMutableArray alloc] initWithArray:urls];
  [urlsToOpen removeObjectsInArray:urlsAlreadyOpen];

  if (!urlsToOpen.isEmpty) {
    [_vimController sendMessage:OpenWithArgumentsMsgID data:[self vimArgsFromFileUrls:urlsToOpen].dictionaryAsData];
  } else {
    [_vimController gotoBufferWithUrl:urlsAlreadyOpen[0]];
  }

  [self.window makeFirstResponder:_vimView.textView];
}

#pragma mark IBActions

- (IBAction)newTab:(id)sender {
  [self sendCommandToVim:@":tabe"];
}

- (IBAction)performClose:(id)sender {
  NSArray *descriptor = @[@"File", @"Close"];
  [self.vimController sendMessage:ExecuteMenuMsgID data:[self dataFromDescriptor:descriptor]];
}

- (IBAction)saveDocument:(id)sender {
  NSArray *descriptor = @[@"File", @"Save"];
  [self.vimController sendMessage:ExecuteMenuMsgID data:[self dataFromDescriptor:descriptor]];
}

- (IBAction)saveDocumentAs:(id)sender {
  [self sendCommandToVim:@":browse confirm sav"];
}

- (IBAction)revertDocumentToSaved:(id)sender {
  [self sendCommandToVim:@":e!"];
}

- (IBAction)selectNextTab:(id)sender {
  [self sendCommandToVim:@"gt"];
}

- (IBAction)selectPreviousTab:(id)sender {
  [self sendCommandToVim:@"gT"];
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
  DDLogWarn(@"###### max frame of the screen: %@", vrect(maxFrame));
  CGSize uncorrectedVimViewSize = [self uncorrectedVimViewSizeForWinFrameRect:maxFrame];
  DDLogWarn(@"###### uncorrected vim view for max frame: %@", vsize(uncorrectedVimViewSize));
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

  DDLogWarn(@"###### telling vim to zoom with %@ X %@", @(rows), @(cols));

  // NOTE: Instead of resizing the window immediately we send a zoom message
  // to the backend so that it gets a chance to resize before the window
  // does.  This avoids problems with the window flickering when zooming.
  int info[3] = {rows, cols, !isZoomed};
  NSData *data = [NSData dataWithBytes:info length:3 * sizeof(int)];
  [_vimController sendMessage:ZoomMsgID data:data];
}

- (IBAction)openQuickly:(id)sender {
  @synchronized (_workspace.fileItemManager) {
    [_workspace.fileItemManager setTargetUrl:self.workingDirectory];
    [_workspace.openQuicklyWindowController showForWindowController:self];
  }
}

- (IBAction)showFileBrowser:(id)sender {
  if (_workspaceView.fileBrowserView) {
    [self.window makeFirstResponder:_fileBrowserView.fileOutlineView];

    return;
  }

  CGRect frame = self.window.frame;
  if (frame.size.width <= _vimView.minSize.width) {
    frame.size.width += _workspaceView.defaultFileBrowserAndDividerWidth;
    [self.window setFrame:frame display:YES];
  }
  _workspaceView.fileBrowserView = _fileBrowserView;

  // We do not make the file browser the first responder, when the file browser was hidden and now gets shown
}

- (IBAction)hideSidebar:(id)sender {
  _workspaceView.fileBrowserView = nil;
  [self.window makeFirstResponder:_vimView.textView];
}

#pragma mark NSUserInterfaceValidations

- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem {
  SEL action = anItem.action;

  if (action == @selector(newTab:)) {
    return YES;
  }

  if (action == @selector(performClose:)) {
    return YES;
  }

  if (action == @selector(saveDocument:)) {
    return YES;
  }

  if (action == @selector(saveDocumentAs:)) {
    return YES;
  }

  if (action == @selector(revertDocumentToSaved:)) {
    return YES;
  }

  if (action == @selector(openQuickly:)) {
    return YES;
  }

  if (action == @selector(showFileBrowser:)) {
    return YES;
  }

  if (action == @selector(hideSidebar:)) {
    return _workspaceView.fileBrowserView != nil;
  }

  if (action == @selector(selectNextTab:) || action == @selector(selectPreviousTab:)) {
    return _vimController.tabs.count >= 2;
  }

  return action == @selector(debug1Action:);

}

#pragma mark Debug

- (IBAction)debug1Action:(id)sender {
  DDLogDebug(@"tabs: %@", _vimController.tabs);
  DDLogDebug(@"buffers: %@", _vimController.buffers);
//  NSMenu *menu = _vimController.mainMenu;
//  NSMenuItem *fileMenu = menu.itemArray[2];
//  NSArray *editMenuArray = [[fileMenu submenu] itemArray];
//  DDLogDebug(@"edit menu: %@", editMenuArray);
}

#pragma mark NSObject

- (void)dealloc {
  log4Mark;
}

#pragma mark MMViewDelegate informal protocol

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
    DDLogWarn(@"live resizing failed");
    [self resizeWindowToFitVimViewSize:_vimView.desiredSize];
  }

  [self setWindowTitleToCurrentBuffer];
}

#pragma mark MMVimControllerDelegate

- (void)controller:(MMVimController *)controller zoomWithRows:(int)rows columns:(int)columns state:(int)state
              data:(NSData *)data {

  DDLogWarn(@"zoom with rows and colums: %d X %d", rows, columns) ;

  [_vimView setDesiredRows:rows columns:columns];
  _needsToResizeVimView = YES;
  _winShouldNotMove = YES;

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
            isLive:(BOOL)live keepOnScreen:(BOOL)winShouldNotMove data:(NSData *)data {

  DDLogDebug(@"%d X %d\tlive: %@\tkeepOnScreen: %@", rows, columns, @(live), @(winShouldNotMove));
  [_vimView setDesiredRows:rows columns:columns];
  [self updateResizeConstraints];

  if (!_vimViewSetUpDone) {
    DDLogDebug(@"not yet setup");
    return;
  }

  if (!winShouldNotMove) {
    DDLogError(@"###### window should not move!!!!");
  }

  if (!live) {
    _needsToResizeVimView = YES;
    _winShouldNotMove = winShouldNotMove;
  }
}

- (void)controller:(MMVimController *)controller openWindowWithData:(NSData *)data {
  self.window.acceptsMouseMovedEvents = YES; // Vim wants to have mouse move events

  [self updateResizeConstraints];

  [self addViews];

  [_vimView addNewTabViewItem];

  _vimViewSetUpDone = YES;
  _winShouldNotMove = YES;

  [_workspace setUpInitialBuffers];

  [self.window makeFirstResponder:_vimView.textView];
}

- (void)controller:(MMVimController *)controller showTabBarWithData:(NSData *)data {
  _vimView.tabBarControl.hidden = NO;
}

- (void)controller:(MMVimController *)controller setScrollbarThumbValue:(float)value proportion:(float)proportion
        identifier:(int32_t)identifier data:(NSData *)data {

}

- (void)controller:(MMVimController *)controller destroyScrollbarWithIdentifier:(int32_t)identifier
              data:(NSData *)data {

  _needsToResizeVimView = YES;
}

- (void)controller:(MMVimController *)controller tabShouldUpdateWithData:(NSData *)data {
}

- (void)controller:(MMVimController *)controller tabDidUpdateWithData:(NSData *)data {
}

- (void)controller:(MMVimController *)controller tabDraggedWithData:(NSData *)data {
}

- (void)controller:(MMVimController *)controller hideTabBarWithData:(NSData *)data {
  _vimView.tabBarControl.hidden = YES;
}

- (void)controller:(MMVimController *)controller setBufferModified:(BOOL)modified data:(NSData *)data {
  self.documentEdited = modified;
}

- (void)controller:(MMVimController *)controller setDocumentFilename:(NSString *)filename data:(NSData *)data {
  self.window.representedFilename = filename;
}

- (void)controller:(MMVimController *)controller setWindowTitle:(NSString *)title data:(NSData *)data {
  [self setWindowTitleToCurrentBuffer];

  // This delegate method is called whenever new buffer is opened, eg :e filename. Here we should loop over all buffers
  // and determine the common parent directory and set it as the workspace.
  // When we open a new tab, this does not get called, but in that case, no change in workspace is required.
  [_workspace updateBuffers];
}

- (void)controller:(MMVimController *)controller processFinishedForInputQueue:(NSArray *)inputQueue {
  if (_fileBrowserView.syncWorkspaceWithPwd) {
    NSString *pwdPath = _vimController.vimState[@"pwd"];
    if (![_workspace.workingDirectory.path isEqualToString:pwdPath]) {
      [_workspace updateWorkingDirectory:[[NSURL alloc] initFileURLWithPath:pwdPath]];
    }
  }

  if (!_needsToResizeVimView) {
    return;
  }

  _needsToResizeVimView = NO;

  CGSize desiredVimViewSize = _vimView.desiredSize;
  DDLogError(@"###### desired vim view size: %@", vsize(desiredVimViewSize));
  DDLogError(@"######     content view size: %@", vsize([self.window contentRectForFrameRect:self.window.frame].size));

  // We constrain the desired size of the Vim view to the visible frame of the screen. This can happen, when you
  // for instance use :set lines=BIG_NUMBER

  desiredVimViewSize = [self constrainContentSizeToScreenSize:desiredVimViewSize];

  DDLogError(@"###### to screen constrained vim view size: %@", vsize(desiredVimViewSize));

  [self resizeWindowToFitVimViewSize:desiredVimViewSize];

  _winShouldNotMove = NO;
}

- (void)controller:(MMVimController *)controller removeToolbarItemWithIdentifier:(NSString *)identifier {
}

- (void)controller:(MMVimController *)controller handleBrowseWithDirectoryUrl:(NSURL *)url browseDir:(BOOL)dir
            saving:(BOOL)saving data:(NSData *)data {

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

- (void)windowDidResize:(id)sender {
  // noop
}

- (NSSize)windowWillResize:(NSWindow *)sender toSize:(NSSize)frameSize {
  // To set -contentResizeIncrements of the window to the cell width of the vim view does not suffice because of the
  // file browser and insets among others. Here, we adjust the width of the window such that the vim view is always
  // A * column wide where A is an integer. And the height.
  CGRect winRect = sender.frame;
  winRect.size = frameSize;

  return [self desiredWinFrameRectForWinFrameRect:winRect].size;
}

#pragma mark Private

- (CGSize)vimViewSizeForWindowRect:(CGRect)winRect {
  NSRect contentRect = [self.window contentRectForFrameRect:winRect];
  contentRect.size.width = contentRect.size.width - _workspaceView.sidebarAndDividerWidth;
  contentRect.size.height = contentRect.size.height - 23;

  return contentRect.size;
}

- (CGSize)uncorrectedVimViewSizeForWinFrameRect:(CGRect)winRect {
  NSRect winContentRect = [self.window contentRectForFrameRect:winRect];
  CGSize winContentSize = winContentRect.size;

  winContentSize.width = winContentSize.width - _workspaceView.sidebarAndDividerWidth;
  winContentSize.height = winContentSize.height - 0;

  return winContentSize;
}

- (CGSize)winContentSizeForVimViewSize:(CGSize)vimViewSize {
  CGSize result;

  result.width = _workspaceView.sidebarAndDividerWidth + vimViewSize.width;
  result.height = vimViewSize.height + 0;

  return result;
}

- (CGRect)desiredWinFrameRectForWinFrameRect:(CGRect)winRect {
  CGRect contentRect = [self.window contentRectForFrameRect:winRect];
  CGFloat fileBrowserAndDividerWidth = _workspaceView.sidebarAndDividerWidth;

  int rows, columns;
  CGSize givenVimViewSize = CGSizeMake(
      contentRect.size.width - fileBrowserAndDividerWidth,
      contentRect.size.height
  );
  CGSize desiredVimViewSize = [_vimView constrainRows:&rows columns:&columns toSize:givenVimViewSize];
  contentRect.size = [self winContentSizeForVimViewSize:desiredVimViewSize];

  return [self.window frameRectForContentRect:contentRect];
}

- (NSURL *)workingDirectory {
  return _workspace.workingDirectory;
}

- (void)addViews {
  _vimView.tabBarControl.styleNamed = @"Metal";

  _fileBrowserView = [[VRFileBrowserView alloc] initWithRootUrl:self.workingDirectory];
  _fileBrowserView.fileItemManager = _workspace.fileItemManager;
  _fileBrowserView.userDefaults = _workspace.userDefaults;
  _fileBrowserView.notificationCenter = _workspace.notificationCenter;

  [_fileBrowserView setUp];

  NSView *contentView = self.window.contentView;
  _workspaceView = [[VRWorkspaceView alloc] initWithFrame:CGRectZero];
  _workspaceView.translatesAutoresizingMaskIntoConstraints = NO;
  _workspaceView.fileBrowserView = _fileBrowserView;
  _workspaceView.vimView = _vimView;
  [contentView addSubview:_workspaceView];

  NSDictionary *views = @{
      @"workspace" : _workspaceView,
  };
  CONSTRAINT(@"H:|[workspace]|");
  CONSTRAINT(@"V:|[workspace]|");
}

- (void)sendCommandToVim:(NSString *)command {
  DDLogDebug(@"sending command %@", command);
  [_vimController addVimInput:SF(@"<C-\\><C-N>%@<CR>", command)];
}

- (NSData *)dataFromDescriptor:(NSArray *)descriptor {
  return [@{@"descriptor" : descriptor} dictionaryAsData];
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

- (CGRect)constrainFrame:(CGRect)frame {
  // Constrain the given (window) frame so that it fits an even number of
  // rows and columns.
  NSWindow *window = self.window;
  CGRect contentRect = [self.window contentRectForFrameRect:frame];
  CGSize constrainedSize = [self.vimView constrainRows:NULL columns:NULL toSize:contentRect.size];

  contentRect.origin.y += contentRect.size.height - constrainedSize.height;
  contentRect.size = constrainedSize;

  return [window frameRectForContentRect:contentRect];
}

- (void)resizeWindowToFitVimViewSize:(CGSize)vimViewSize {
  NSWindow *window = self.window;
  CGRect frame = window.frame;
  CGRect winContentRect = [self.window contentRectForFrameRect:frame];

  // Keep top-left corner of the window fixed when resizing.
  winContentRect.origin.y -= vimViewSize.height - winContentRect.size.height;
  winContentRect.size = vimViewSize;
  winContentRect.size.width += _workspaceView.sidebarAndDividerWidth;

  CGRect newWinFrameRect = [window frameRectForContentRect:winContentRect];

  DDLogError(@"###### old win frame rect: %@", vrect(frame));
  DDLogError(@"###### new win frame rect: %@", vrect(newWinFrameRect));

  if (_shouldRestoreUserTopLeft) {
    // Restore user top left window position (which is saved when zooming).
    CGFloat dy = _userTopLeft.y - NSMaxY(newWinFrameRect);
    newWinFrameRect.origin.x = _userTopLeft.x;
    newWinFrameRect.origin.y += dy;
    _shouldRestoreUserTopLeft = NO;
  }

  NSScreen *screen = window.screen;
  if (_winShouldNotMove && screen) {
    // Ensure that the window fits inside the visible part of the screen.
    // If there are more than one screen the window will be moved to fit
    // entirely in the screen that most of it occupies.
    CGRect maxFrame = screen.visibleFrame;
    maxFrame = [self constrainFrame:maxFrame];

    if (newWinFrameRect.size.width > maxFrame.size.width) {
      newWinFrameRect.size.width = maxFrame.size.width;
      newWinFrameRect.origin.x = maxFrame.origin.x;
    }

    if (newWinFrameRect.size.height > maxFrame.size.height) {
      newWinFrameRect.size.height = maxFrame.size.height;
      newWinFrameRect.origin.y = maxFrame.origin.y;
    }

    if (newWinFrameRect.origin.y < maxFrame.origin.y) {
      newWinFrameRect.origin.y = maxFrame.origin.y;
    }

    if (NSMaxY(newWinFrameRect) > NSMaxY(maxFrame)) {
      newWinFrameRect.origin.y = NSMaxY(maxFrame) - newWinFrameRect.size.height;
    }

    if (newWinFrameRect.origin.x < maxFrame.origin.x) {
      newWinFrameRect.origin.x = maxFrame.origin.x;
    }

    if (NSMaxX(newWinFrameRect) > NSMaxX(maxFrame)) {
      newWinFrameRect.origin.x = NSMaxX(maxFrame) - newWinFrameRect.size.width;
    }
  }

  [window setFrame:newWinFrameRect display:YES];

  CGPoint oldTopLeft = CGPointMake(frame.origin.x, NSMaxY(frame));
  CGPoint newTopLeft = CGPointMake(newWinFrameRect.origin.x, NSMaxY(newWinFrameRect));
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

- (CGSize)constrainContentSizeToScreenSize:(CGSize)contentSize {
  NSWindow *win = self.window;
  if (win.screen == nil) {
    return contentSize;
  }

  // NOTE: This may be called in both windowed and full-screen mode.  The
  // "visibleFrame" method does not overlap menu and dock so should not be
  // used in full-screen.
  CGRect screenRect = win.screen.visibleFrame;
  CGRect rect = [self.window contentRectForFrameRect:screenRect];

  if (contentSize.height > rect.size.height) {
    contentSize.height = rect.size.height;
  }

  if (contentSize.width > rect.size.width) {
    contentSize.width = rect.size.width;
  }

  return contentSize;
}

- (NSConnection *)connectionToBackend {
  NSDistantObject *proxy = _vimController.backendProxy;

  return proxy.connectionForProxy;
}

- (void)updateResizeConstraints {
  if (!_vimViewSetUpDone) {
    return;
  }

  NSWindow *window = self.window;
  if (_workspaceView.fileBrowserView) {
    window.minSize =
        CGSizeMake(_workspaceView.sidebarAndDividerWidth + _vimView.minSize.width, _vimView.minSize.height);
  } else {
    window.minSize = _vimView.minSize;
  }
  // We also update the increment of the workspace view, because it could be that the font size has changed
  _workspaceView.dragIncrement = (NSUInteger) _vimView.textView.cellSize.width;
}

- (void)setWindowTitleToCurrentBuffer {
  NSString *filePath = _vimController.currentBuffer.fileName;
  NSString *filename = filePath.lastPathComponent;

  if (filename == nil) {
    self.window.title = @"Untitled";
    return;
  }

  NSString *containingFolder = filePath.stringByDeletingLastPathComponent.lastPathComponent;
  self.window.title = SF(@"%@ — %@", filename, containingFolder);
}

- (VRMainWindow *)newMainWindowForContentRect:(CGRect)contentRect {
  unsigned windowStyle = NSTitledWindowMask | NSUnifiedTitleAndToolbarWindowMask
      | NSClosableWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask
      | NSTexturedBackgroundWindowMask;

  VRMainWindow *window = [[VRMainWindow alloc] initWithContentRect:contentRect styleMask:windowStyle
                                                           backing:NSBackingStoreBuffered defer:YES];
  window.delegate = self;
  window.hasShadow = YES;
  window.title = @"VimR";

  [window setAutorecalculatesContentBorderThickness:NO forEdge:NSMinYEdge];
  [window setContentBorderThickness:22 forEdge:NSMinYEdge];

  return window;
}

- (NSDictionary *)vimArgsFromFileUrls:(NSArray *)fileUrls {
  NSMutableArray *filenames = [[NSMutableArray alloc] initWithCapacity:4];
  for (NSURL *url in fileUrls) {
    [filenames addObject:url.path];
  }

  return @{
      qVimArgFileNamesToOpen : filenames,
      qVimArgOpenFilesLayout : @(MMLayoutTabs),
  };
}

- (NSDictionary *)vimArgsFromUrl:(NSURL *)url mode:(NSUInteger)mode {
  return @{
      qVimArgFileNamesToOpen : @[url.path],
      qVimArgOpenFilesLayout : @(mode),
  };
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

@end
