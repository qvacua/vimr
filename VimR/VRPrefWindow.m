/**
* Tae Won Ha — @hataewon
*
* http://taewon.de
* http://qvacua.com
*
* See LICENSE
*/

#import "VRPrefWindow.h"
#import "VRUtils.h"
#import "VRGeneralPrefPane.h"
#import "VRFileBrowserPrefPane.h"


NSString *const qPrefWindowFrameAutosaveName = @"pref-window-frame-autosave";


@implementation VRPrefWindow {
  NSDictionary *_prefPanes;
}

@autowire(userDefaultsController)

#pragma mark NSWindow
- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag {
  self = [super initWithContentRect:contentRect styleMask:NSTitledWindowMask | NSClosableWindowMask backing:NSBackingStoreBuffered defer:YES];
  RETURN_NIL_WHEN_NOT_SELF

  self.title = @"Preferences";
  self.releasedWhenClosed = NO;
  [self setFrameAutosaveName:qPrefWindowFrameAutosaveName];

  return self;
}

#pragma mark TBInitializingBean
- (void)postConstruct {
  _prefPanes = @{
      @"General" : [[VRGeneralPrefPane alloc] initWithUserDefaultsController:_userDefaultsController],
      @"FileBrowser" : [[VRFileBrowserPrefPane alloc] initWithUserDefaultsController:_userDefaultsController],
  };
}

#pragma mark Private

@end
