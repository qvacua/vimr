/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import <Cocoa/Cocoa.h>
#import <MacVimFramework/MacVimFramework.h>


@class VRWorkspaceController;
@class VROpenQuicklyWindowController;
@class VRWorkspace;

@interface VRMainWindowController : NSWindowController <NSWindowDelegate, MMVimControllerDelegate>

#pragma mark Properties
@property (weak) VROpenQuicklyWindowController *openQuicklyWindowController;
@property (weak) VRWorkspace *workspace;

@property (weak) MMVimController *vimController;
@property (weak) MMVimView *vimView;

@property BOOL needsToResizeVimView;

#pragma mark Public
- (instancetype)initWithContentRect:(CGRect)contentRect;
- (void)openFilesWithArgs:(NSDictionary *)args;
- (void)cleanUpAndClose;

#pragma mark IBActions
- (IBAction)newTab:(id)sender;
- (IBAction)performClose:(id)sender;
- (IBAction)saveDocument:(id)sender;
- (IBAction)saveDocumentAs:(id)sender;
- (IBAction)revertDocumentToSaved:(id)sender;
- (IBAction)openQuickly:(id)sender;

#pragma mark Debug
- (IBAction)firstDebugAction:(id)sender;
- (IBAction)secondDebugAction:(id)sender;

#pragma mark NSWindowController
- (IBAction)thirdDebugAction:(id)sender;
- (void)dealloc;

#pragma mark MMViewDelegate informal protocol
- (void)liveResizeWillStart;
- (void)liveResizeDidEnd;

#pragma mark MMVimControllerDelegate
- (void)controller:(MMVimController *)controller handleShowDialogWithButtonTitles:(NSArray *)buttonTitles
             style:(NSAlertStyle)style message:(NSString *)message text:(NSString *)text
   textFieldString:(NSString *)string data:(NSData *)data;
- (void)controller:(MMVimController *)controller showScrollbarWithIdentifier:(int32_t)identifier state:(BOOL)state
              data:(NSData *)data;
- (void)controller:(MMVimController *)controller setTextDimensionsWithRows:(int)rows columns:(int)columns
            isLive:(BOOL)live keepOnScreen:(BOOL)isReplyToGuiResize data:(NSData *)data;
- (void)controller:(MMVimController *)controller openWindowWithData:(NSData *)data;
- (void)controller:(MMVimController *)controller showTabBarWithData:(NSData *)data;
- (void)controller:(MMVimController *)controller setScrollbarThumbValue:(float)value
        proportion:(float)proportion identifier:(int32_t)identifier data:(NSData *)data;
- (void)controller:(MMVimController *)controller destroyScrollbarWithIdentifier:(int32_t)identifier
              data:(NSData *)data;
- (void)controller:(MMVimController *)controller tabShouldUpdateWithData:(NSData *)data;
- (void)controller:(MMVimController *)controller tabDidUpdateWithData:(NSData *)data;
- (void)controller:(MMVimController *)controller tabDraggedWithData:(NSData *)data;
- (void)controller:(MMVimController *)controller setBufferModified:(BOOL)modified data:(NSData *)data;
- (void)controller:(MMVimController *)controller setDocumentFilename:(NSString *)filename data:(NSData *)data;
- (void)controller:(MMVimController *)controller setWindowTitle:(NSString *)title data:(NSData *)data;
- (void)controller:(MMVimController *)controller processFinishedForInputQueue:(NSArray *)inputQueue;
- (void)controller:(MMVimController *)controller removeToolbarItemWithIdentifier:(NSString *)identifier;
- (void)controller:(MMVimController *)controller handleBrowseWithDirectoryUrl:(NSURL *)url browseDir:(BOOL)dir
            saving:(BOOL)saving data:(NSData *)data;

#pragma mark NSWindowDelegate
- (void)windowDidBecomeMain:(NSNotification *)notification;
- (void)windowDidResignMain:(NSNotification *)notification;
- (BOOL)windowShouldClose:(id)sender;

@end
