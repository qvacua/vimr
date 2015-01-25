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
@class VRPropertyReader;


@interface VRWorkspace : NSObject

@property (nonatomic, weak) VRFileItemManager *fileItemManager;
@property (nonatomic, weak) NSFileManager *fileManager;
@property (nonatomic, weak) VRMainWindowControllerFactory *mainWindowControllerFactory;
@property (nonatomic, weak) VRWorkspaceController *workspaceController;
@property (nonatomic, weak) VRPropertyReader *propertyReader;


@property (nonatomic) VRMainWindowController *mainWindowController;
@property (nonatomic) NSURL *workingDirectory;

#pragma mark Public
- (void)ensureUrlsAreVisible:(NSArray *)urls;
- (BOOL)isOnlyWorkspace;
- (NSArray *)openedUrls;
- (void)updateWorkingDirectoryToUrl:(NSURL *)workingDir;
- (void)openFilesWithUrls:(NSArray *)url;
- (BOOL)hasModifiedBuffer;
- (void)setUpWithVimController:(MMVimController *)vimController;
- (void)setUpInitialBuffers;
- (void)updateWorkingDirectoryToCommonParent;
- (void)cleanUpAndClose;
- (void)updateBuffersInTabs;
- (void)selectBufferWithUrl:(NSURL *)url;
- (NSArray *)openQuicklyIgnorePatterns;

#pragma mark NSObject
- (id)init;

@end
