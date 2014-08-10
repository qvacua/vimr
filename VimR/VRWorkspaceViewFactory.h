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


@class VRFileBrowserViewFactory;
@class VRWorkspaceView;


@interface VRWorkspaceViewFactory : NSObject <TBBean>

@property (nonatomic, weak) NSUserDefaults *userDefaults;
@property (nonatomic, weak) VRFileBrowserViewFactory *fileBrowserViewFactory;

- (VRWorkspaceView *)newWorkspaceViewWithFrame:(NSRect)frame vimView:(MMVimView *)vimView;

@end
