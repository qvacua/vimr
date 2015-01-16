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
@class VRPropertyReader;


@interface VRWorkspaceFactory : NSObject <TBBean>

@property (nonatomic, weak) NSFileManager *fileManager;
@property (nonatomic, weak) VRFileItemManager *fileItemManager;
@property (nonatomic, weak) VRMainWindowControllerFactory *mainWindowControllerFactory;
@property (nonatomic, weak) VRWorkspaceController *workspaceController;

- (VRWorkspace *)newWorkspaceWithWorkingDir:(NSURL *)workingDir;

@end
