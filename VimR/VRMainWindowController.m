/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import <PSMTabBarControl/PSMTabBarControl.h>
#import "VRMainWindowController.h"
#import "VRLog.h"
#import "MMAlert.h"
#import "VRUtils.h"


@interface VRMainWindowController ()

@property BOOL processOngoing;

@end

@implementation VRMainWindowController

#pragma mark Public
- (void)cleanupAndClose {
    log4Mark;
    [self close];
}

#pragma mark IBActions
- (IBAction)firstDebugAction:(id)sender {
    log4Mark;
}

- (IBAction)performClose:(id)sender {
    log4Mark;
    // TODO: when the doc is dirty, we could ask to save here!
    NSArray *descriptor = @[@"File", @"Close"];
    [self.vimController sendMessage:ExecuteMenuMsgID data:[self dataFromDescriptor:descriptor]];
}

- (IBAction)saveDocument:(id)sender {
    log4Mark;
    [self sendCommandToVim:@":w"];
}

- (IBAction)saveDocumentAs:(id)sender {
    log4Mark;
    [self sendCommandToVim:@"browse confirm sav"];
}

- (IBAction)revertDocumentToSaved:(id)sender {
    log4Mark;
    [self sendCommandToVim:@":e!"];
}

#pragma mark NSWindowController
- (id)initWithWindowNibName:(NSString *)windowNibName {
    self = [super initWithWindowNibName:windowNibName];
    if (self == nil) {
        return nil;
    }

    return self;
}

- (void)dealloc {
    log4Mark;

    [self.vimView removeFromSuperviewWithoutNeedingDisplay];
    [self.vimView cleanup];
}

#pragma mark MMVimControllerDelegate
- (void)vimController:(MMVimController *)controller handleShowDialogWithButtonTitles:(NSArray *)buttonTitles
                style:(NSAlertStyle)style message:(NSString *)message text:(NSString *)text
      textFieldString:(NSString *)textFieldString data:(NSData *)data {

    log4Mark;

    // copied from MacVim {
    MMAlert *alert = [[MMAlert alloc] init];

    // NOTE! This has to be done before setting the informative text.
    if (textFieldString) {
        alert.textFieldString = textFieldString;
    }

    alert.alertStyle = style;

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

    unsigned i, count = buttonTitles.count;
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

- (void)vimController:(MMVimController *)controller showScrollbarWithIdentifier:(int32_t)identifier
                state:(BOOL)state data:(NSData *)data {

    [self.vimView showScrollbarWithIdentifier:identifier state:state];
}

- (void)vimController:(MMVimController *)controller setTextDimensionsWithRows:(int)rows columns:(int)columns
               isLive:(BOOL)live keepOnScreen:(BOOL)screen data:(NSData *)data {

    [self.vimView setDesiredRows:rows columns:columns];
}

- (void)vimController:(MMVimController *)controller openWindowWithData:(NSData *)data {
    self.window.acceptsMouseMovedEvents = YES; // Vim wants to have mouse move events

    self.vimView.tabBarControl.styleNamed = @"Metal";

    // TODO: we always show the tabs! NO exception!
    [self sendCommandToVim:@":set showtabline=2"];

    [self.window.contentView addSubview:self.vimView];

    [self.vimView addNewTabViewItem];
    [self.window makeFirstResponder:self.vimView.textView];
}

- (void)vimController:(MMVimController *)controller showTabBarWithData:(NSData *)data {
    [self.vimView.tabBarControl setHidden:NO];

    log4Mark;
}

- (void)vimController:(MMVimController *)controller setScrollbarThumbValue:(float)value proportion:(float)proportion
           identifier:(int32_t)identifier data:(NSData *)data {

    log4Mark;
}

- (void)vimController:(MMVimController *)controller destroyScrollbarWithIdentifier:(int32_t)identifier
                 data:(NSData *)data {

    log4Mark;
}

- (void)vimController:(MMVimController *)controller tabShouldUpdateWithData:(NSData *)data {
    log4Mark;
}

- (void)vimController:(MMVimController *)controller tabDidUpdateWithData:(NSData *)data {
    log4Mark;
}

- (void)vimController:(MMVimController *)controller tabDraggedWithData:(NSData *)data {
    log4Mark;
}

- (void)vimController:(MMVimController *)controller hideTabBarWithData:(NSData *)data {
    log4Mark;
    // TODO: we always show the tabs! NO exception!
    [self sendCommandToVim:@":set showtabline=2"];
}

- (void)vimController:(MMVimController *)controller setBufferModified:(BOOL)modified data:(NSData *)data {
    log4Mark;

    [self setDocumentEdited:modified];
}

- (void)vimController:(MMVimController *)controller setDocumentFilename:(NSString *)filename data:(NSData *)data {
    log4Mark;

    [self.window setRepresentedFilename:filename];
}

- (void)vimController:(MMVimController *)controller setWindowTitle:(NSString *)title data:(NSData *)data {
    self.window.title = title;
}

- (void)vimController:(MMVimController *)controller processFinishedForInputQueue:(NSArray *)inputQueue {
    if (self.processOngoing) {
        log4Debug(@"setting process ongoing to no");
        self.processOngoing = NO;
    }

    NSSize contentSize = self.vimView.desiredSize;
    contentSize = [self constrainContentSizeToScreenSize:contentSize];
    int rows = 0, cols = 0;
    contentSize = [self.vimView constrainRows:&rows columns:&cols toSize:contentSize];
    self.vimView.frameSize = contentSize;

    [self resizeWindowToFitContentSize:contentSize];
}

- (void)vimController:(MMVimController *)controller removeToolbarItemWithIdentifier:(NSString *)identifier {
    log4Mark;
}

- (void)vimController:(MMVimController *)controller handleBrowseWithDirectoryUrl:(NSURL *)url browseDir:(BOOL)dir saving:(BOOL)saving data:(NSData *)data {

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
    // don't close the window or tab; instead let Vim decide what to do
    [self.vimController sendMessage:VimShouldCloseMsgID data:nil];

    return NO;
}

#pragma mark Private
- (NSUInteger)indexOfSelectedDocument {
    PSMTabBarControl *tabBar = self.vimView.tabBarControl;
    return [tabBar.representedTabViewItems indexOfObject:tabBar.tabView.selectedTabViewItem];
}

- (void)sendCommandToVim:(NSString *)command {
    while (self.processOngoing) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }

    self.processOngoing = YES;

    log4Debug(@"sending command %@", command);
    [self.vimController addVimInput:SF(@"<C-\\><C-N>%@<CR>", command)];
}

- (NSData *)dataFromDescriptor:(NSArray *)descriptor {
    return [@{@"descriptor" : descriptor} dictionaryAsData];
}

- (void)alertDidEnd:(MMAlert *)alert code:(int)code context:(void *)controllerContext {
    // copied from MacVim {
    NSArray *ret = nil;
    code = code - NSAlertFirstButtonReturn + 1;

    if ([alert isKindOfClass:[MMAlert class]] && alert.textField) {
        ret = @[@(code), alert.textField.stringValue];
    } else {
        ret = @[@(code)];
    }

    log4Debug(@"Alert return=%@", ret);

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

- (NSRect)constrainFrame:(NSRect)frame {
    // Constrain the given (window) frame so that it fits an even number of
    // rows and columns.
    NSWindow *window = self.window;
    NSRect contentRect = [window contentRectForFrameRect:frame];
    NSSize constrainedSize = [self.vimView constrainRows:NULL columns:NULL toSize:contentRect.size];

    contentRect.origin.y += contentRect.size.height - constrainedSize.height;
    contentRect.size = constrainedSize;

    return [window frameRectForContentRect:contentRect];
}

- (void)resizeWindowToFitContentSize:(NSSize)contentSize {
    NSWindow *window = self.window;
    NSRect frame = window.frame;
    NSRect contentRect = [window contentRectForFrameRect:frame];

    // Keep top-left corner of the window fixed when resizing.
    contentRect.origin.y -= contentSize.height - contentRect.size.height;
    contentRect.size = contentSize;

    NSRect newFrame = [window frameRectForContentRect:contentRect];

    NSScreen *screen = window.screen;
    if (screen) {
        // Ensure that the window fits inside the visible part of the screen.
        // If there are more than one screen the window will be moved to fit
        // entirely in the screen that most of it occupies.
        NSRect maxFrame = screen.visibleFrame;
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

        // Keep window centered when in native full-screen.
        NSRect screenFrame = screen.frame;
        newFrame.origin.y = screenFrame.origin.y + round(0.5 * (screenFrame.size.height - newFrame.size.height));
        newFrame.origin.x = screenFrame.origin.x + round(0.5 * (screenFrame.size.width - newFrame.size.width));
    }

    [window setFrame:newFrame display:YES];

    NSPoint oldTopLeft = {frame.origin.x, NSMaxY(frame)};
    NSPoint newTopLeft = {newFrame.origin.x, NSMaxY(newFrame)};
    if (NSEqualPoints(oldTopLeft, newTopLeft)) {
        return;
    }

    // NOTE: The window top left position may change due to the window
    // being moved e.g. when the tabline is shown so we must tell Vim what
    // the new window position is here.
    // NOTE 2: Vim measures Y-coordinates from top of screen.
    int pos[2] = {(int) newTopLeft.x, (int) (NSMaxY(window.screen.frame) - newTopLeft.y)};
    [self.vimController sendMessage:SetWindowPositionMsgID data:[NSData dataWithBytes:pos length:2 * sizeof(int)]];
}

- (NSSize)constrainContentSizeToScreenSize:(NSSize)contentSize {
    NSWindow *win = self.window;
    if (!win.screen) {
        return contentSize;
    }

    // NOTE: This may be called in both windowed and full-screen mode.  The
    // "visibleFrame" method does not overlap menu and dock so should not be
    // used in full-screen.
    NSRect screenRect = win.screen.visibleFrame;
    NSRect rect = [win contentRectForFrameRect:screenRect];

    if (contentSize.height > rect.size.height) {
        contentSize.height = rect.size.height;
    }

    if (contentSize.width > rect.size.width) {
        contentSize.width = rect.size.width;
    }

    return contentSize;
}

@end
