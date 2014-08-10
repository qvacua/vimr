/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import <Cocoa/Cocoa.h>
#import <TBCacao/TBCacao.h>


@class VRWorkspaceController;
@class VRFileItemManager;
@class VRWorkspace;
@class VROpenQuicklyWindowController;
@class VRMainWindowControllerFactory;


@interface VRWorkspaceFactory : NSObject <TBBean>

@property (nonatomic, weak) NSFileManager *fileManager;
@property (nonatomic, weak) VRWorkspaceController *workspaceController;
@property (nonatomic, weak) VRFileItemManager *fileItemManager;
@property (nonatomic, weak) NSUserDefaults *userDefaults;
@property (nonatomic, weak) NSNotificationCenter *notificationCenter;
@property (nonatomic, weak) VROpenQuicklyWindowController *openQuicklyWindowController;
@property (nonatomic, weak) VRMainWindowControllerFactory *mainWindowControllerFactory;

- (VRWorkspace *)newWorkspaceWithWorkingDir:(NSURL *)workingDir;

@end
