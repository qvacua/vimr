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


@interface VRMainWindowControllerFactory : NSObject <TBBean>

@property (nonatomic, weak) VRPluginManager *pluginManager;
@property (nonatomic, weak) NSNotificationCenter *notificationCenter;

- (VRMainWindowController *)newMainWindowControllerWithContentRect:(CGRect)contentRect
                                                         workspace:(VRWorkspace *)workspace
                                                     vimController:(MMVimController *)vimController;

@end
