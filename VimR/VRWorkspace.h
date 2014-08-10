/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import <Cocoa/Cocoa.h>


@class VRMainWindowController;
@class MMVimController;
@class VRFileItemManager;
@class VROpenQuicklyWindowController;
@class VRWorkspaceController;
@class VRMainWindowControllerFactory;


@interface VRWorkspace : NSObject

@property (nonatomic, weak) NSFileManager *fileManager;
@property (nonatomic, weak) VRWorkspaceController *workspaceController;
@property (nonatomic, weak) VRFileItemManager *fileItemManager;
@property (nonatomic, weak) NSUserDefaults *userDefaults;
@property (nonatomic, weak) NSNotificationCenter *notificationCenter;
@property (nonatomic, weak) VRMainWindowControllerFactory *mainWindowControllerFactory;
@property (nonatomic, weak) VROpenQuicklyWindowController *openQuicklyWindowController;

@property (nonatomic) VRMainWindowController *mainWindowController;
@property (nonatomic) NSURL *workingDirectory;

#pragma mark Public
- (NSArray *)openedUrls;
- (void)updateWorkingDirectory:(NSURL *)workingDir;
- (void)openFilesWithUrls:(NSArray *)url;
- (BOOL)hasModifiedBuffer;
- (void)setUpWithVimController:(MMVimController *)vimController;
- (void)setUpInitialBuffers;
- (void)cleanUpAndClose;
- (void)updateBuffers;
- (void)selectBufferWithUrl:(NSURL *)url;

#pragma mark NSObject
- (id)init;

@end
