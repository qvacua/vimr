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


@interface VRMainWindowControllerFactory : NSObject <TBBean>

- (VRMainWindowController *)newMainWindowControllerWithContentRect:(CGRect)contentRect
                                                         workspace:(VRWorkspace *)workspace
                                                     vimController:(MMVimController *)vimController;

@end
