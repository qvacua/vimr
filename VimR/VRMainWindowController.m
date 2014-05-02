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
#import <CocoaLumberjack/DDLog.h>
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


@interface VRMainWindowController ()

@property BOOL isReplyToGuiResize;
@property BOOL vimViewSetUpDone;

@end

@implementation VRMainWindowController {
  int _userRows;
  int _userCols;
  CGPoint _userTopLeft;
  BOOL _shouldRestoreUserTopLeft;
}

#pragma mark Public
- (instancetype)initWithContentRect:(CGRect)contentRect {
  self = [super initWithWindow:[self newMainWindowForContentRect:contentRect]];
  RETURN_NIL_WHEN_NOT_SELF

  return self;
}

- (void)openFilesWithArgs:(NSDictionary *)args {
  [self.vimController sendMessage:OpenWithArgumentsMsgID data:args.dictionaryAsData];
}

- (void)cleanUpAndClose {
  log4Mark;

  [self.vimView removeFromSuperviewWithoutNeedingDisplay];
  [self.vimView cleanup];

  [self close];
}

- (void)openFileWithUrl:(NSURL *)url {
  __block BOOL alreadyOpened = NO;
  [_vimController.tabs enumerateObjectsUsingBlock:^(MMTabPage *tab, NSUInteger idx, BOOL *stop) {
    if ([tab.buffer.fileName isEqualToString:url.path]) {
      [self sendCommandToVim:SF(@":tabm %lu", idx)];
      *stop = YES;
      alreadyOpened = YES;
    }
  }];

  if (alreadyOpened) {
    return;
  }

  [_vimController sendMessage:OpenWithArgumentsMsgID data:[self vimArgsFromFileUrls:@[url]].dictionaryAsData];
}

#pragma mark IBActions
- (IBAction)newTab:(id)sender {
  [self sendCommandToVim:@":tabe"];
}

- (IBAction)performClose:(id)sender {
  // TODO: when the doc is dirty, we could ask to save here!
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
  CGRect contentRect = [self uncorrectedVimViewRectInParentRect:maxFrame];
  [_vimView constrainRows:&rowsZoomed columns:&colsZoomed toSize:contentRect.size];

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

- (CGRect)uncorrectedVimViewRectInParentRect:(CGRect)parentRect {
  return [self.window contentRectForFrameRect:parentRect];
}

- (IBAction)openQuickly:(id)sender {
  [_workspace.fileItemManager setTargetUrl:_workspace.workingDirectory];
  [_workspace.openQuicklyWindowController showForWindowController:self];
}

#pragma mark Debug
- (IBAction)debug1Action:(id)sender {
  DDLogDebug(@"buffers: %@", _vimController.buffers);
  NSMenu *menu = _vimController.mainMenu;
  NSMenuItem *fileMenu = menu.itemArray[2];
  NSArray *editMenuArray = [[fileMenu submenu] itemArray];
  DDLogDebug(@"edit menu: %@", editMenuArray);
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

  NSView <MMTextViewProtocol> *textView = self.vimView.textView;

  int constrained[2];
  [textView constrainRows:&constrained[0] columns:&constrained[1] toSize:textView.frame.size];

  DDLogDebug(@"End of live resize, notify Vim that text dimensions are %d x %d", constrained[1], constrained[0]);

  NSData *data = [NSData dataWithBytes:constrained length:(2 * sizeof(int))];
  BOOL liveResizeMsgSuccessful = [self.vimController sendMessageNow:LiveResizeMsgID data:data timeout:.5];

  if (!liveResizeMsgSuccessful) {
    /**
    * Sending of synchronous message failed.  Force the window size to
    * match the last dimensions received from Vim, otherwise we end up
    * with inconsistent states.
    */
    DDLogDebug(@"live resizing failed");
    [self resizeWindowToFitContentSize:_vimView.desiredSize];
  }

  [self setWindowTitleToCurrentBuffer];
}

#pragma mark MMVimControllerDelegate
- (void)controller:(MMVimController *)controller zoomWithRows:(int)rows columns:(int)columns state:(int)state
              data:(NSData *)data {

  [_vimView setDesiredRows:rows columns:columns];
  _needsToResizeVimView = YES;
  _isReplyToGuiResize = YES;

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
  self.needsToResizeVimView = YES;
}

- (void)controller:(MMVimController *)controller setTextDimensionsWithRows:(int)rows columns:(int)columns
            isLive:(BOOL)live keepOnScreen:(BOOL)isReplyToGuiResize data:(NSData *)data {

  log4Mark;
  DDLogDebug(@"%d X %d\tlive: %@\tkeepOnScreen: %@", rows, columns, @(live), @(isReplyToGuiResize));
  [_vimView setDesiredRows:rows columns:columns];

  if (!self.vimViewSetUpDone) {
    DDLogDebug(@"not yet setup");
    return;
  }

  if (!live) {
    _needsToResizeVimView = YES;
    _isReplyToGuiResize = isReplyToGuiResize;
  }
}

- (void)controller:(MMVimController *)controller openWindowWithData:(NSData *)data {
  log4Mark;

  self.window.acceptsMouseMovedEvents = YES; // Vim wants to have mouse move events

  _vimView.tabBarControl.styleNamed = @"Metal";

  [self.window.contentView addSubview:_vimView];
  _vimView.autoresizingMask = NSViewNotSizable;

  [_vimView addNewTabViewItem];

  _vimViewSetUpDone = YES;
  _isReplyToGuiResize = YES;

  [self updateResizeConstraints];

  [_workspace setUpInitialBuffers];

  [self.window makeFirstResponder:_vimView.textView];
}

- (void)controller:(MMVimController *)controller showTabBarWithData:(NSData *)data {
  log4Mark;
  self.vimView.tabBarControl.hidden = NO;
}

- (void)controller:(MMVimController *)controller setScrollbarThumbValue:(float)value proportion:(float)proportion
        identifier:(int32_t)identifier data:(NSData *)data {

  log4Mark;
}

- (void)controller:(MMVimController *)controller destroyScrollbarWithIdentifier:(int32_t)identifier
              data:(NSData *)data {

  log4Mark;
  self.needsToResizeVimView = YES;
}

- (void)controller:(MMVimController *)controller tabShouldUpdateWithData:(NSData *)data {
  log4Mark;
}

- (void)controller:(MMVimController *)controller tabDidUpdateWithData:(NSData *)data {
  log4Mark;

  DDLogDebug(@"tabs: %@", [self.vimController tabs]);
}

- (void)controller:(MMVimController *)controller tabDraggedWithData:(NSData *)data {
  log4Mark;
}

- (void)controller:(MMVimController *)controller hideTabBarWithData:(NSData *)data {
  log4Mark;
  self.vimView.tabBarControl.hidden = YES;
}

- (void)controller:(MMVimController *)controller setBufferModified:(BOOL)modified data:(NSData *)data {
  log4Mark;

  [self setDocumentEdited:modified];
}

- (void)controller:(MMVimController *)controller setDocumentFilename:(NSString *)filename data:(NSData *)data {
  log4Mark;

  [self.window setRepresentedFilename:filename];
}

- (void)controller:(MMVimController *)controller setWindowTitle:(NSString *)title data:(NSData *)data {
  [self setWindowTitleToCurrentBuffer];

  // This delegate method is called whenever new buffer is opened, eg :e filename. Here we should loop over all buffers
  // and determine the common parent directory and set it as the workspace.
  // When we open a new tab, this does not get called, but in that case, no change in workspace is required.
  [_workspace updateBuffers];
}


- (void)controller:(MMVimController *)controller processFinishedForInputQueue:(NSArray *)inputQueue {
  if (!_needsToResizeVimView) {
    return;
  }

  DDLogDebug(@"resizing window to fit Vim view");
  _needsToResizeVimView = NO;

  CGSize contentSize = _vimView.desiredSize;
  contentSize = [self constrainContentSizeToScreenSize:contentSize];
  DDLogDebug(@"uncorrected size: %@", vsize(contentSize));
  int rows = 0, cols = 0;
  contentSize = [self.vimView constrainRows:&rows columns:&cols toSize:contentSize];

  DDLogDebug(@"%d X %d", rows, cols);
  DDLogDebug(@"corrected size: %@", vsize(contentSize));

  _vimView.frameSize = contentSize;

  [self resizeWindowToFitContentSize:contentSize];

  _isReplyToGuiResize = NO;
}

- (void)controller:(MMVimController *)controller removeToolbarItemWithIdentifier:(NSString *)identifier {
  log4Mark;
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
  [self.vimController sendMessage:GotFocusMsgID data:nil];
}

- (void)windowDidResignMain:(NSNotification *)notification {
  [self.vimController sendMessage:LostFocusMsgID data:nil];
}

- (BOOL)windowShouldClose:(id)sender {
  log4Mark;
  /**
  * this gets called when Cmd-W
  */

  // don't close the window or tab; instead let Vim decide what to do
  [self.vimController sendMessage:VimShouldCloseMsgID data:nil];

  return NO;
}

- (void)windowDidResize:(id)sender {
  /**
  * NOTE: Since we have no control over when the window may resize (Cocoa
  * may resize automatically) we simply set the view to fill the entire
  * window.  The vim view takes care of notifying Vim if the number of
  * (rows,columns) changed.
  */
  _vimView.frameSize = [self uncorrectedVimViewRectInParentRect:self.window.frame].size;
}

#pragma mark Private
- (void)sendCommandToVim:(NSString *)command {
  DDLogDebug(@"sending command %@", command);
  [_vimController addVimInput:SF(@"<C-\\><C-N>%@<CR>", command)];
}

- (NSData *)dataFromDescriptor:(NSArray *)descriptor {
  return [@{@"descriptor" : descriptor} dictionaryAsData];
}

- (void)alertDidEnd:(VRAlert *)alert code:(int)code context:(void *)controllerContext {
  // copied from MacVim {
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
  [self.vimController tellBackend:ret];
  // } copied from MacVim
}

- (CGRect)constrainFrame:(CGRect)frame {
  // Constrain the given (window) frame so that it fits an even number of
  // rows and columns.
  NSWindow *window = self.window;
  CGRect contentRect = [self uncorrectedVimViewRectInParentRect:frame];
  CGSize constrainedSize = [self.vimView constrainRows:NULL columns:NULL toSize:contentRect.size];

  contentRect.origin.y += contentRect.size.height - constrainedSize.height;
  contentRect.size = constrainedSize;

  return [window frameRectForContentRect:contentRect];
}

- (void)resizeWindowToFitContentSize:(CGSize)contentSize {
  logSize4Debug(@"contentSize", contentSize);
  NSWindow *window = self.window;
  CGRect frame = window.frame;
  CGRect contentRect = [self uncorrectedVimViewRectInParentRect:frame];

  // Keep top-left corner of the window fixed when resizing.
  contentRect.origin.y -= contentSize.height - contentRect.size.height;
  contentRect.size = contentSize;

  CGRect newFrame = [window frameRectForContentRect:contentRect];

  logRect4Debug(@"old", frame);
  logRect4Debug(@"new", newFrame);

  if (_shouldRestoreUserTopLeft) {
    // Restore user top left window position (which is saved when zooming).
    CGFloat dy = _userTopLeft.y - NSMaxY(newFrame);
    newFrame.origin.x = _userTopLeft.x;
    newFrame.origin.y += dy;
    _shouldRestoreUserTopLeft = NO;
  }

  NSScreen *screen = window.screen;
  if (_isReplyToGuiResize && screen) {
    // Ensure that the window fits inside the visible part of the screen.
    // If there are more than one screen the window will be moved to fit
    // entirely in the screen that most of it occupies.
    CGRect maxFrame = screen.visibleFrame;
    maxFrame = [self constrainFrame:maxFrame];

    if (newFrame.size.width > maxFrame.size.width) {
      newFrame.size.width = maxFrame.size.width;
      newFrame.origin.x = maxFrame.origin.x;
    }

    if (newFrame.size.height > maxFrame.size.height) {
      newFrame.size.height = maxFrame.size.height;
      newFrame.origin.y = maxFrame.origin.y;
    }

    if (newFrame.origin.y < maxFrame.origin.y) {
      newFrame.origin.y = maxFrame.origin.y;
    }

    if (NSMaxY(newFrame) > NSMaxY(maxFrame)) {
      newFrame.origin.y = NSMaxY(maxFrame) - newFrame.size.height;
    }

    if (newFrame.origin.x < maxFrame.origin.x) {
      newFrame.origin.x = maxFrame.origin.x;
    }

    if (NSMaxX(newFrame) > NSMaxX(maxFrame)) {
      newFrame.origin.x = NSMaxX(maxFrame) - newFrame.size.width;
    }
  }

  [window setFrame:newFrame display:YES];

  CGPoint oldTopLeft = {frame.origin.x, NSMaxY(frame)};
  CGPoint newTopLeft = {newFrame.origin.x, NSMaxY(newFrame)};
  if (CGPointEqualToPoint(oldTopLeft, newTopLeft)) {
    DDLogDebug(@"returning since top left point equal");
    return;
  }

  // NOTE: The window top left position may change due to the window
  // being moved e.g. when the tabline is shown so we must tell Vim what
  // the new window position is here.
  // NOTE 2: Vim measures Y-coordinates from top of screen.
  int pos[2] = {(int) newTopLeft.x, (int) (NSMaxY(window.screen.frame) - newTopLeft.y)};
  [self.vimController sendMessage:SetWindowPositionMsgID data:[NSData dataWithBytes:pos length:2 * sizeof(int)]];
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
  CGRect rect = [self uncorrectedVimViewRectInParentRect:screenRect];

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

  // Set the resize increments to exactly match the font size; this way the
  // window will always hold an integer number of (rows, columns).
  self.window.contentResizeIncrements = _vimView.textView.cellSize;
  self.window.contentMinSize = _vimView.minSize;
}

- (void)setWindowTitleToCurrentBuffer {
  NSString *filePath = _vimController.currentTab.buffer.fileName;
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

@end
