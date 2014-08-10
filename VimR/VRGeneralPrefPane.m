/**
* Tae Won Ha — @hataewon
*
* http://taewon.de
* http://qvacua.com
*
* See LICENSE
*/

#import "VRGeneralPrefPane.h"
#import "VRUserDefaults.h"
#import "VRUtils.h"


#define CONSTRAIN(fmt) [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:fmt options:0 metrics:nil views:views]];


@implementation VRGeneralPrefPane

#pragma mark VRPrefPane
- (NSString *)displayName {
  return @"General";
}

#pragma mark Public
- (id)initWithUserDefaultsController:(NSUserDefaultsController *)userDefaultsController {
  self = [super initWithFrame:CGRectZero];
  RETURN_NIL_WHEN_NOT_SELF

  self.userDefaultsController = userDefaultsController;

  [self addViews];

  return self;
}

#pragma mark Private
- (void)addViews {
  // default appearance
  NSTextField *daTitle = [self newTextLabelWithString:@"Default Appearance:" alignment:NSRightTextAlignment];
  NSButton *showStatusBarButton = [self checkButtonWithTitle:@"Show status bar" defaultKey:qDefaultShowStatusBar];
  NSButton *showSidebarButton = [self checkButtonWithTitle:@"Show sidebar" defaultKey:qDefaultShowSideBar];
  NSButton *showSidebarOnRightButton = [self checkButtonWithTitle:@"Sidebar on right" defaultKey:qDefaultShowSideBarOnRight];
  NSTextField *daDescription = [self newDescriptionLabelWithString:@"These are default values, ie new windows will start with these values set:\n– The changes will only affect new windows.\n– You can override these settings in each window."
                                                         alignment:NSLeftTextAlignment];

  NSTextField *ouTitle = [self newTextLabelWithString:@"Open Untitled Window:" alignment:NSRightTextAlignment];
  NSButton *ouOnLaunch = [self checkButtonWithTitle:@"On launch" defaultKey:qDefaultOpenUntitledWinModeOnLaunch];
  NSButton *ouOnReactivation = [self checkButtonWithTitle:@"On re-activation" defaultKey:qDefaultOpenUntitledWinModeOnReactivation];

  // auto saving
  NSTextField *asTitle = [self newTextLabelWithString:@"Saving Behavior:" alignment:NSRightTextAlignment];

  NSButton *asOnFrameDeactivation = [self checkButtonWithTitle:@"Save automatically on focus loss" defaultKey:qDefaultAutoSaveOnFrameDeactivation];
  NSTextField *asOfdDesc = [self newDescriptionLabelWithString:@"'autocmd BufLeave,FocusLost * silent! wall' in VimR group" alignment:NSLeftTextAlignment];

  NSButton *asOnCursorHold = [self checkButtonWithTitle:@"Save automatically if VimR is idle for some time" defaultKey:qDefaultAutoSaveOnCursorHold];
  NSTextField *asOchDesc = [self newDescriptionLabelWithString:@"'autocmd CursorHold * silent! wall' in VimR group" alignment:NSLeftTextAlignment];

  NSDictionary *views = @{
      @"daTitle" : daTitle,
      @"showStatusBar" : showStatusBarButton,
      @"showSidebar" : showSidebarButton,
      @"showSidebarRight" : showSidebarOnRightButton,
      @"daDesc" : daDescription,

      @"ouTitle" : ouTitle,
      @"ouOnLaunch" : ouOnLaunch,
      @"ouOnReactivation" : ouOnReactivation,

      @"asTitle" : asTitle,
      @"asOnFrameDeactivation" : asOnFrameDeactivation,
      @"asOfdDesc" : asOfdDesc,
      @"asOnCursorHold" : asOnCursorHold,
      @"asOchDesc" : asOchDesc,
  };

  for (NSView *view in @[asTitle, ouTitle]) {
    [self addConstraint:[NSLayoutConstraint constraintWithItem:view
                                                     attribute:NSLayoutAttributeTrailing
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:daTitle
                                                     attribute:NSLayoutAttributeTrailing
                                                    multiplier:1 constant:0]];
  }

  for (NSView *view in views.allValues) {
    [view setContentHuggingPriority:NSLayoutPriorityDefaultLow forOrientation:NSLayoutConstraintOrientationHorizontal];
  }

  CONSTRAIN(@"H:|-[daTitle]-[showStatusBar]-|");
  CONSTRAIN(@"H:|-[daTitle]-[showSidebar]-|");
  CONSTRAIN(@"H:|-[daTitle]-[showSidebarRight]-|");
  CONSTRAIN(@"H:|-[daTitle]-[daDesc]-|");

  CONSTRAIN(@"H:|-[ouTitle]-[ouOnLaunch]")
  CONSTRAIN(@"H:|-[ouTitle]-[ouOnReactivation]")

  CONSTRAIN(@"H:|-[asTitle]-[asOnFrameDeactivation]-|");
  CONSTRAIN(@"H:|-[asTitle]-[asOfdDesc]-|");
  CONSTRAIN(@"H:|-[asTitle]-[asOnCursorHold]-|");
  CONSTRAIN(@"H:|-[asTitle]-[asOchDesc]-|");

  [self addConstraint:[self baseLineConstraintForView:daTitle toView:showStatusBarButton]];
  [self addConstraint:[self baseLineConstraintForView:asTitle toView:asOnFrameDeactivation]];
  [self addConstraint:[self baseLineConstraintForView:ouTitle toView:ouOnLaunch]];

  CONSTRAIN(@"V:|-[showStatusBar]-[showSidebar]-[showSidebarRight]-[daDesc]-(24)-"
      "[ouOnLaunch]-[ouOnReactivation]-(24)-"
      "[asOnFrameDeactivation]-[asOfdDesc]-[asOnCursorHold]-[asOchDesc]-|");
}

@end
