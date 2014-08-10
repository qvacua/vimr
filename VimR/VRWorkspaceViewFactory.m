/**
* Tae Won Ha — @hataewon
*
* http://taewon.de
* http://qvacua.com
*
* See LICENSE
*/

#import <MacVimFramework/MacVimFramework.h>
#import "VRWorkspaceViewFactory.h"
#import "VRFileBrowserViewFactory.h"
#import "VRWorkspaceView.h"


@implementation VRWorkspaceViewFactory

@autowire(userDefaults)
@autowire(fileBrowserViewFactory)

- (VRWorkspaceView *)newWorkspaceViewWithFrame:(NSRect)frame vimView:(MMVimView *)vimView {
  VRWorkspaceView *view = [[VRWorkspaceView alloc] initWithFrame:frame];

  view.fileBrowserViewFactory = _fileBrowserViewFactory;
  view.userDefaults = _userDefaults;
  view.vimView = vimView;

  return view;
}

@end
