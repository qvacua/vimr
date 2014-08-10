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
#import "VRUserDefaults.h"
#import "VRUserDefaultsObserver.h"


@class VRWorkspaceController;
@class VROpenQuicklyWindowController;
@class VRWorkspace;
@class VRPluginManager;
@class VRPreviewWindowController;
@class VRFileItemManager;
@class VRWorkspaceViewFactory;


extern const int qMainWindowBorderThickness;


@interface VRMainWindowController : NSWindowController <
    NSWindowDelegate,
    MMVimControllerDelegate,
    VRUserDefaultsObserver,
    NSUserInterfaceValidations>

@property (nonatomic, weak) VRWorkspace *workspace;
@property (nonatomic, weak) VRWorkspaceViewFactory *workspaceViewFactory;
@property (nonatomic, weak) VRFileItemManager *fileItemManager;
@property (nonatomic, weak) VROpenQuicklyWindowController *openQuicklyWindowController;
@property (nonatomic, weak) NSUserDefaults *userDefaults;
@property (nonatomic, weak) MMVimController *vimController;

@property (nonatomic, weak) MMVimView *vimView;
@property (nonatomic) VRPreviewWindowController *previewWindowController;

#pragma mark Public
- (instancetype)initWithContentRect:(CGRect)contentRect;
- (void)updateWorkingDirectory;
- (void)cleanUpAndClose;
- (void)openFileWithUrls:(NSURL *)urls openMode:(VROpenMode)openMode;
- (void)openFilesWithUrls:(NSArray *)url;
- (void)forceRedrawVimView;
- (NSURL *)workingDirectory;

#pragma mark IBActions
- (IBAction)newTab:(id)sender;
- (IBAction)performClose:(id)sender;
- (IBAction)saveDocument:(id)sender;
- (IBAction)saveDocumentAs:(id)sender;
- (IBAction)revertDocumentToSaved:(id)sender;
- (IBAction)selectNextTab:(id)sender;
- (IBAction)selectPreviousTab:(id)sender;
- (IBAction)showPreview:(id)sender;
- (IBAction)zoom:(id)sender;
- (IBAction)openQuickly:(id)sender;

#pragma mark NSUserInterfaceValidations
- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem;

#pragma mark NSObject
- (void)dealloc;

#pragma mark MMViewDelegate informal protocol
- (void)liveResizeWillStart;
- (void)liveResizeDidEnd;

#pragma mark MMVimControllerDelegate
- (void)controller:(MMVimController *)controller zoomWithRows:(int)rows columns:(int)columns state:(int)state data:(NSData *)data;
- (void)controller:(MMVimController *)controller handleShowDialogWithButtonTitles:(NSArray *)buttonTitles style:(NSAlertStyle)style message:(NSString *)message text:(NSString *)text textFieldString:(NSString *)string data:(NSData *)data;
- (void)controller:(MMVimController *)controller showScrollbarWithIdentifier:(int32_t)identifier state:(BOOL)state data:(NSData *)data;
- (void)controller:(MMVimController *)controller setTextDimensionsWithRows:(int)rows columns:(int)columns isLive:(BOOL)live keepOnScreen:(BOOL)winOriginShouldMove data:(NSData *)data;
- (void)controller:(MMVimController *)controller openWindowWithData:(NSData *)data;
- (void)controller:(MMVimController *)controller showTabBarWithData:(NSData *)data;
- (void)controller:(MMVimController *)controller setScrollbarThumbValue:(float)value proportion:(float)proportion identifier:(int32_t)identifier data:(NSData *)data;
- (void)controller:(MMVimController *)controller destroyScrollbarWithIdentifier:(int32_t)identifier data:(NSData *)data;
- (void)controller:(MMVimController *)controller tabShouldUpdateWithData:(NSData *)data;
- (void)controller:(MMVimController *)controller tabDidUpdateWithData:(NSData *)data;
- (void)controller:(MMVimController *)controller tabDraggedWithData:(NSData *)data;
- (void)controller:(MMVimController *)controller setBufferModified:(BOOL)modified data:(NSData *)data;
- (void)controller:(MMVimController *)controller setDocumentFilename:(NSString *)filename data:(NSData *)data;
- (void)controller:(MMVimController *)controller setVimState:(NSDictionary *)vimState data:(NSData *)data;
- (void)controller:(MMVimController *)controller setWindowTitle:(NSString *)title data:(NSData *)data;
- (void)controller:(MMVimController *)controller processFinishedForInputQueue:(NSArray *)inputQueue;
- (void)controller:(MMVimController *)controller removeToolbarItemWithIdentifier:(NSString *)identifier;
- (void)controller:(MMVimController *)controller handleBrowseWithDirectoryUrl:(NSURL *)url browseDir:(BOOL)dir saving:(BOOL)saving data:(NSData *)data;

#pragma mark VRUserDefaultsObserver
- (void)registerUserDefaultsObservation;
- (void)removeUserDefaultsObservation;

#pragma mark NSWindowDelegate
- (void)windowDidBecomeMain:(NSNotification *)notification;
- (void)windowDidResignMain:(NSNotification *)notification;
- (BOOL)windowShouldClose:(id)sender;

@end
