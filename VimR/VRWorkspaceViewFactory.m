/**
* Tae Won Ha — @hataewon
*
* http://taewon.de
* http://qvacua.com
*
* See LICENSE
*/

#import <MacVimFramework/MacVimFramework.h>
#import <PureLayout/ALView+PureLayout.h>
#import "VRWorkspaceViewFactory.h"
#import "QVWorkspace.h"


@implementation VRWorkspaceViewFactory

@autowire(userDefaults)
@autowire(fileBrowserViewFactory)

- (QVWorkspace *)newWorkspaceViewWithFrame:(NSRect)frame vimView:(MMVimView *)vimView {
  QVWorkspace *view = [[QVWorkspace alloc] initForAutoLayout];

  view.centerView = vimView;

  return view;
}

@end
