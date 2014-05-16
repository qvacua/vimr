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

@property VRWorkspaceController *workspaceController;
@property VRFileItemManager *fileItemManager;
@property NSUserDefaults *userDefaults;

@property VROpenQuicklyWindowController *openQuicklyWindowController;
@property VRMainWindowController *mainWindowController;
@property (copy) NSURL *workingDirectory;

#pragma mark Public
- (void)openFileWithUrl:(NSURL *)url;
- (BOOL)hasModifiedBuffer;
- (void)setUpWithVimController:(MMVimController *)vimController;
- (void)setUpInitialBuffers;
- (void)cleanUpAndClose;

#pragma mark NSObject
- (id)init;

- (void)updateBuffers;
@end
