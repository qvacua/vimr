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


@interface VRWorkspace : NSObject

@property (nonatomic) VRWorkspaceController *workspaceController;
@property (nonatomic) VRFileItemManager *fileItemManager;
@property (nonatomic) NSUserDefaults *userDefaults;
@property (nonatomic) NSNotificationCenter *notificationCenter;

@property (nonatomic) VROpenQuicklyWindowController *openQuicklyWindowController;
@property (nonatomic) VRMainWindowController *mainWindowController;
@property (nonatomic) NSURL *workingDirectory;

#pragma mark Public
- (void)updateWorkingDirectory:(NSURL *)commonParent;
- (void)openFilesWithUrls:(NSArray *)url;
- (BOOL)hasModifiedBuffer;
- (void)setUpWithVimController:(MMVimController *)vimController;
- (void)setUpInitialBuffers;
- (void)cleanUpAndClose;
- (void)updateBuffers;

#pragma mark NSObject
- (id)init;

@end
