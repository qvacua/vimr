/**
* Tae Won Ha — @hataewon
*
* http://taewon.de
* http://qvacua.com
*
* See LICENSE
*/

#import "VRFileBrowserViewFactory.h"
#import "VRFileItemManager.h"
#import "VRFileBrowserOutlineView.h"
#import "VRFileBrowserView.h"
#import "VRWorkspaceView.h"


@implementation VRFileBrowserViewFactory

@autowire(fileManager)
@autowire(fileItemManager)
@autowire(userDefaults)
@autowire(notificationCenter)

- (VRFileBrowserView *)newFileBrowserViewWithWorkspaceView:(VRWorkspaceView *)workspaceView rootUrl:(NSURL *)rootUrl {
  VRFileBrowserView *view = [[VRFileBrowserView alloc] initWithRootUrl:rootUrl];

  view.fileItemManager = _fileItemManager;
  view.userDefaults = _userDefaults;
  view.notificationCenter = _notificationCenter;
  view.fileManager = _fileManager;
  view.workspaceView = workspaceView;

  return view;
}

@end
