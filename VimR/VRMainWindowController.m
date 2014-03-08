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
#import "VRDocumentController.h"
#import "VRDocument.h"
#import "VRLog.h"
#import "MMAlert.h"


@implementation VRMainWindowController

#pragma mark IBActions
- (IBAction)firstDebugAction:(id)sender {
    log4Debug(@"edited: %@", @([self.documents[0] isDocumentEdited]));
}

- (IBAction)performClose:(id)sender {
    log4Mark;

    // TODO: we could ask the user here whether to save or not
    log4Debug(@"%@ dirty: %@", self.selectedDocument.fileURL.path, @(self.selectedDocument.dirty));

    // TODO: when reordering tabs, we have to reflect the order in the order of docs
    NSArray *descriptor = @[@"File", @"Close"];
    [self.vimController sendMessage:ExecuteMenuMsgID data:[self dataFromDescriptor:descriptor]];
    [self removeDocument:[self selectedDocument]];

}

- (IBAction)saveDocument:(id)sender {
    log4Mark;
    [self sendCommandToVim:@":browse confirm w"];
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

    _documents = [[NSMutableArray alloc] initWithCapacity:4];

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

    self.vimView.frameSize = [self.window contentRectForFrameRect:self.window.frame].size;
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
    log4Debug(@"selected tab index: %li", [self indexOfSelectedTab]);
}

- (void)vimController:(MMVimController *)controller hideTabBarWithData:(NSData *)data {
    log4Mark;
    [[self.vimView tabBarControl] setHidden:YES];
}

- (void)vimController:(MMVimController *)controller setBufferModified:(BOOL)modified data:(NSData *)data {
    log4Mark;

    [self setDocumentEdited:modified];
    [self selectedDocument].dirty = modified;
}

- (void)vimController:(MMVimController *)controller setDocumentFilename:(NSString *)filename data:(NSData *)data {
    log4Mark;

    [self.window setRepresentedFilename:filename];
}

- (void)vimController:(MMVimController *)controller setWindowTitle:(NSString *)title data:(NSData *)data {
    self.window.title = title;
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
    for (VRDocument *doc in self.documents) {
        log4Debug(@"%@ - dirty: %@", doc.fileURL.path, @(doc.dirty));
    }

    // don't close the window or tab; instead let Vim decide what to do
    [self.vimController sendMessage:VimShouldCloseMsgID data:nil];

    return NO;
}

#pragma mark Private
- (void)removeDocument:(VRDocument *)doc {
    [self.documents removeObject:doc];
    [doc close];
}

- (VRDocument *)selectedDocument {
    if (self.documents.count == 1) {
        return self.documents[0];
    }

    return self.documents[[self indexOfSelectedTab]];
}

- (NSUInteger)indexOfSelectedTab {
    PSMTabBarControl *tabBar = self.vimView.tabBarControl;
    return [tabBar.representedTabViewItems indexOfObject:tabBar.tabView.selectedTabViewItem];
}

- (void)sendCommandToVim:(NSString *)command {
    [self.vimController addVimInput:[NSString stringWithFormat:@"<C-\\><C-N>%@\n", command]];
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

@end
