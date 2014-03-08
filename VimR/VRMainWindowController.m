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


@implementation VRMainWindowController

- (IBAction)saveDocument:(id)sender {
    NSArray *fileSaveDescriptor = @[@"File", @"Save"];
    [self.vimController sendMessage:ExecuteMenuMsgID data:[self dataFromDescriptor:fileSaveDescriptor]];
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
      textFieldString:(NSString *)string data:(NSData *)data {

    // 3 = don't save
    // 1 = save
    [self.vimController tellBackend:@[@3]];
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
}

- (void)vimController:(MMVimController *)controller setDocumentFilename:(NSString *)filename data:(NSData *)data {
    log4Mark;

    [self.window setRepresentedFilename:filename];
}

- (void)vimController:(MMVimController *)controller handleBrowseWithDirectoryUrl:(NSURL *)url browseDir:(BOOL)dir saving:(BOOL)saving data:(NSData *)data {

    if (!saving) {
        return;
    }


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

    // TODO: when reordering tabs, we have to reflect the order in the order of docs
    if (self.documents.count <= 1) {
        log4Debug(@"only one doc left, thus closing the Vim process");

        [self.vimController sendMessage:VimShouldCloseMsgID data:nil];
    } else {
        int index = (int) [self indexOfSelectedTab];
        log4Debug(@"more than one doc open, thus closing the selected tab with index: %d", index);

        [self.vimController sendMessage:CloseTabMsgID data:[NSData dataWithBytes:&index length:sizeof(int)]];
        [self removeDocument:self.documents[(NSUInteger) index]];
    }

    return NO;
}

#pragma mark Private
- (void)removeDocument:(VRDocument *)doc {
    [self.documents removeObject:doc];
    [self.documentController removeDocument:doc];
}

- (NSUInteger)indexOfSelectedTab {
    PSMTabBarControl *tabBar = self.vimView.tabBarControl;
    return [tabBar.representedTabViewItems indexOfObject:tabBar.tabView.selectedTabViewItem];
}

- (NSData *)dataFromDescriptor:(NSArray *)descriptor {
    return [@{@"descriptor" : descriptor} dictionaryAsData];
}

@end
