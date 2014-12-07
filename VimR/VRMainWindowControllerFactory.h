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


@class VRWorkspace;
@class MMVimController;
@class VRMainWindowController;
@class VRPluginManager;
@class VRFileItemManager;
@class VROpenQuicklyWindowController;
@class VRWorkspaceViewFactory;


@interface VRMainWindowControllerFactory : NSObject <TBBean>

@property (nonatomic, weak) NSUserDefaults *userDefaults;
@property (nonatomic, weak) VRPluginManager *pluginManager;
@property (nonatomic, weak) VRFileItemManager *fileItemManager;
@property (nonatomic, weak) VROpenQuicklyWindowController *openQuicklyWindowController;
@property (nonatomic, weak) NSNotificationCenter *notificationCenter;
@property (nonatomic, weak) VRWorkspaceViewFactory *workspaceViewFactory;
@property (nonatomic, unsafe_unretained) NSFontManager *fontManager;

- (VRMainWindowController *)newMainWindowControllerWithContentRect:(CGRect)contentRect
                                                         workspace:(VRWorkspace *)workspace
                                                     vimController:(MMVimController *)vimController;

@end
