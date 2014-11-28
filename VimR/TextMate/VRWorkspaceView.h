/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import <Cocoa/Cocoa.h>


extern NSString *const qSidebarWidthAutosaveName;


@class MMVimView;
@class VRFileBrowserView;
@class VRWorkspace;
@class VRFileBrowserViewFactory;

/**
* Copied and modified from TextMate -Tae
*
* Frameworks/DocumentWindow/src/ProjectLayoutView.mm
* v2.0-alpha.9537
*/
@interface VRWorkspaceView : NSView <NSUserInterfaceValidations>

@property (nonatomic, weak) VRFileBrowserViewFactory *fileBrowserViewFactory;
@property (nonatomic, weak) NSUserDefaults *userDefaults;

@property (nonatomic) VRFileBrowserView *fileBrowserView;
@property (nonatomic) MMVimView *vimView;

@property (nonatomic) CGFloat fileBrowserWidth;
@property (nonatomic, readonly) CGFloat sidebarAndDividerWidth;
@property (nonatomic, readonly) CGFloat defaultFileBrowserAndDividerWidth;
@property (nonatomic) NSUInteger dragIncrement;

@property (nonatomic) BOOL fileBrowserOnRight;
@property (nonatomic) BOOL showStatusBar;
@property (nonatomic) BOOL showHiddenFiles;
@property (nonatomic) BOOL showFoldersFirst;
@property (nonatomic) BOOL syncWorkspaceWithPwd;

#pragma mark Public
- (void)setUrlOfPathControl:(NSURL *)url;
- (void)setUp;
- (void)setStatusMessage:(NSString *)message;
- (NSSet *)nonFilteredWildIgnorePathsForParentPath:(NSString *)path;

#pragma mark NSUserInterfaceValidations
- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem;

#pragma mark NSView
- (id)initWithFrame:(NSRect)aRect;
- (void)updateConstraints;
- (void)resetCursorRects;
- (NSView *)hitTest:(NSPoint)aPoint;
- (void)mouseDown:(NSEvent *)anEvent;

#pragma mark IBActions
- (IBAction)toggleStatusBar:(NSMenuItem *)sender;
- (IBAction)toggleSyncWorkspaceWithPwd:(NSMenuItem *)sender;
- (IBAction)toggleShowFoldersFirst:(NSMenuItem *)sender;
- (IBAction)toggleShowHiddenFiles:(NSMenuItem *)sender;
- (IBAction)toggleSidebarOnRight:(id)sender;

- (IBAction)focusFileBrowser:(id)sender;
- (IBAction)showFileBrowser:(id)sender;

@end
