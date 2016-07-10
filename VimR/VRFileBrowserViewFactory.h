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


@class VRFileItemManager;
@class VRFileBrowserView;
@class VRWorkspaceView;
@class MMVimController;


@interface VRFileBrowserViewFactory : NSObject <TBBean>

@property (nonatomic, weak) NSFileManager *fileManager;
@property (nonatomic, weak) VRFileItemManager *fileItemManager;
@property (nonatomic, weak) NSUserDefaults *userDefaults;
@property (nonatomic, weak) NSNotificationCenter *notificationCenter;

- (VRFileBrowserView *)newFileBrowserViewWithVimController:(MMVimController *)vimController rootUrl:(NSURL *)rootUrl;

@end
